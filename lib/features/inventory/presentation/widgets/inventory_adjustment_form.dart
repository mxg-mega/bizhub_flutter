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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8.r)),
                child: Icon(Icons.sync_alt, color: Colors.orange[700], size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory Adjustment', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  Text(widget.product.name, style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          EnhancedUnitSelector(
            product: widget.product,
            selectedUnit: _selectedUnit,
            label: 'Adjustment Unit',
            onUnitSelected: (final unit) => setState(() => _selectedUnit = unit),
          ),
          
          SizedBox(height: 20.h),
          
          Text('Location Stock Levels', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          SizedBox(height: 12.h),
          
          locationsAsync.when(
            data: (final locations) => _buildLocationList(locations),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (final err, _) => const Text('Error loading locations'),
          ),
          
          SizedBox(height: 20.h),
          
          _buildTextField(
            controller: _reasonController,
            label: 'Adjustment Reason',
            hint: 'e.g., Damaged goods, Stock audit...',
            icon: Icons.notes,
          ),
          
          SizedBox(height: 24.h),
          
          if (actionsState.hasError) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12.r)),
              child: Text(actionsState.error.toString(), style: GoogleFonts.inter(color: Colors.red[700], fontSize: 12.sp)),
            ),
            SizedBox(height: 16.h),
          ],
          
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: actionsState.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                elevation: 0,
              ),
              child: actionsState.isLoading 
                ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Confirm Adjustment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15.sp)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationList(final List<LocationModel> locations) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: locations.length,
      separatorBuilder: (_, final __) => SizedBox(height: 12.h),
      itemBuilder: (final context, final index) {
        final location = locations[index];
        final currentQty = widget.product.stockByLocation[location.id] ?? 0.0;
        
        double displayQty = currentQty;
        if (widget.product.unitChain != null) {
          final baseUnit = widget.product.unitChain!.baseUnit ?? 'Piece';
          final factor = widget.product.unitChain!.getFactor(baseUnit, _selectedUnit);
          displayQty = currentQty * factor;
        }

        final offsetValue = double.tryParse(_getController(location.id).text) ?? 0.0;
        final newQty = displayQty + offsetValue;

        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    Text('Current: ${displayQty.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600])),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  controller: _getController(location.id),
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    hintText: '0',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey[200]!)),
                  ),
                  onChanged: (final _) => setState(() {}),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('New', style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey)),
                    Text(
                      newQty.toStringAsFixed(0),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp, 
                        fontWeight: FontWeight.bold,
                        color: offsetValue != 0 ? Colors.blue[700] : Colors.black87,
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

  Widget _buildTextField({
    required final TextEditingController controller,
    required final String label,
    required final String hint,
    required final IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13.sp),
            prefixIcon: Icon(icon, size: 18.sp, color: Colors.blue[700]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}
