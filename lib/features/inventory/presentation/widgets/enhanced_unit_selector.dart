import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/product_model.dart';

class EnhancedUnitSelector extends StatelessWidget {
  final ProductModel product;
  final String? selectedUnit;
  final Function(String) onUnitSelected;
  final String label;
  final bool showPrice;

  const EnhancedUnitSelector({
    super.key,
    required this.product,
    required this.onUnitSelected,
    this.selectedUnit,
    this.label = 'Select Unit',
    this.showPrice = true,
  });

  @override
  Widget build(final BuildContext context) {
    // Determine available units from the chain or fall back to a default
    final List<String> units = product.unitChain?.units ?? ['Piece'];
    
    // Ensure the selectedUnit is valid for this product
    final String currentValue = (selectedUnit != null && units.contains(selectedUnit))
        ? selectedUnit!
        : (units.isNotEmpty ? units.first : 'Piece');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 6.h),
        ],
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.unfold_more_outlined, size: 20.w, color: Colors.blue[700]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.blue[400]!, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: units.map((final unit) {
            final double price = product.calculatePriceForUnit(unit);
            return DropdownMenuItem<String>(
              value: unit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _capitalize(unit),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showPrice)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        price.toStringAsFixed(2),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (final value) {
            if (value != null) onUnitSelected(value);
          },
        ),
      ],
    );
  }

  String _capitalize(final String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
