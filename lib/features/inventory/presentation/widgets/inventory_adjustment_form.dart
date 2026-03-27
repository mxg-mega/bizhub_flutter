import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/product_model.dart';
import '../../data/models/location_model.dart';
import '../providers/inventory_providers.dart';
import 'enhanced_unit_selector.dart';

class InventoryAdjustmentForm extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback? onComplete;

  const InventoryAdjustmentForm({
    super.key,
    required this.product,
    this.onComplete,
  });

  @override
  ConsumerState<InventoryAdjustmentForm> createState() => _InventoryAdjustmentFormState();
}

class _InventoryAdjustmentFormState extends ConsumerState<InventoryAdjustmentForm> {
  final _reasonController = TextEditingController();
  final Map<String, TextEditingController> _offsetControllers = {};
  String _selectedUnit = 'Piece';

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.product.unitChain?.baseUnit ?? 'Piece';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    for (final controller in _offsetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(final String locationId) => _offsetControllers.putIfAbsent(locationId, () => TextEditingController(text: '0'));

  double _getOffsetInBaseUnit(final String locationId) {
    final text = _getController(locationId).text;
    final offsetInSelectedUnit = double.tryParse(text) ?? 0.0;
    
    if (widget.product.unitChain == null) return offsetInSelectedUnit;
    
    final baseUnit = widget.product.unitChain!.baseUnit ?? 'Piece';
    /// Calculates the conversion factor between the selected unit and the base unit.
    /// 
    /// Uses the product's unit chain to determine the multiplicative factor needed
    /// to convert quantities from [_selectedUnit] to [baseUnit]. This factor is
    /// essential for accurate inventory adjustments when units differ from the
    /// base unit of measurement.
    /// 
    /// Returns the conversion factor as a double value.
    final factor = widget.product.unitChain!.getFactor(_selectedUnit, baseUnit);
    return offsetInSelectedUnit * factor;
  }

  Future<void> _submit() async {
    final Map<String, double> adjustments = {};
    
    for (final entry in _offsetControllers.entries) {
      final offset = _getOffsetInBaseUnit(entry.key);
      if (offset != 0) {
        adjustments[entry.key] = offset;
      }
    }

    if (adjustments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No adjustments made')),
      );
      return;
    }

    await ref.read(inventoryActionsProvider.notifier).adjustInventory(
      productId: widget.product.id,
      adjustments: adjustments,
      reason: _reasonController.text.isNotEmpty ? _reasonController.text : 'Manual Adjustment',
    );

    if (mounted && !ref.read(inventoryActionsProvider).hasError) {
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final actionsState = ref.watch(inventoryActionsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Adjustment',
          style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          'Product: ${widget.product.name}',
          style: theme.textTheme.bodySmall,
        ),
        const Divider(height: 32),
        
        // Unit Selector
        EnhancedUnitSelector(
          product: widget.product,
          selectedUnit: _selectedUnit,
          label: 'Adjustment Unit',
          onUnitSelected: (final unit) => setState(() => _selectedUnit = unit),
        ),
        
        SizedBox(height: 24.h),
        
        Text(
          'Location Stock Levels',
          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        
        locationsAsync.when(
          data: (locations) => _buildLocationList(locations),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading locations: $err'),
        ),
        
        const Divider(height: 40),
        
        // Reason Field
        TextField(
          controller: _reasonController,
          decoration: InputDecoration(
            labelText: 'Reason for Adjustment',
            hintText: 'e.g., Damaged goods, Restock, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
        
        SizedBox(height: 24.h),
        
        if (actionsState.hasError) ...[
          Text(
            actionsState.error.toString(),
            style: const TextStyle(color: Colors.red),
          ),
          SizedBox(height: 12.h),
        ],
        
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: actionsState.isLoading ? null : _submit,
            child: actionsState.isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save Adjustments'),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationList(final List<LocationModel> locations) => ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        final currentQty = widget.product.stockByLocation[location.id] ?? 0.0;
        
        // Convert current quantity from base unit to selected unit for display
        double displayQty = currentQty;
        if (widget.product.unitChain != null) {
          final baseUnit = widget.product.unitChain!.baseUnit ?? 'Piece';
          final factor = widget.product.unitChain!.getFactor(baseUnit, _selectedUnit);
          displayQty = currentQty * factor;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Current: ${displayQty.toStringAsFixed(2)} $_selectedUnit',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _getController(location.id),
                  keyboardType: TextInputType.numberWithOptions(signed: true),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    hintText: '+/-',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  onChanged: (final _) => setState(() {}), // Refresh "New" preview
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'New',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    ),
                    Text(
                      '${(displayQty + (double.tryParse(_getController(location.id).text) ?? 0.0)).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp, 
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
}
