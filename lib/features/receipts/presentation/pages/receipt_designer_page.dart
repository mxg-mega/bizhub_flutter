import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/receipt_providers.dart';
import '../../data/models/receipt_template_model.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/presentation/widgets/common_app_bar.dart';

class ReceiptDesignerPage extends ConsumerStatefulWidget {
  const ReceiptDesignerPage({super.key});

  @override
  ConsumerState<ReceiptDesignerPage> createState() => _ReceiptDesignerPageState();
}

class _ReceiptDesignerPageState extends ConsumerState<ReceiptDesignerPage> {
  ReceiptTemplateModel? _localTemplate;
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();

  @override
  void dispose() {
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _initLocalTemplate(final ReceiptTemplateModel template) {
    if (_localTemplate == null) {
      _localTemplate = template;
      _headerController.text = template.headerText ?? '';
      _footerController.text = template.footerText ?? '';
    }
  }

  @override
  Widget build(final BuildContext context) {
    final templateAsync = ref.watch(activeReceiptTemplateProvider);

    return Scaffold(
      appBar: const CommonAppBar(actions: []),
      body: templateAsync.when(
        data: (final template) {
          _initLocalTemplate(template);
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.grey[100],
                  child: Center(child: _ReceiptPreview(template: _localTemplate!)),
                ),
              ),
              VerticalDivider(width: 1, color: Colors.grey[300]),
              Expanded(
                flex: 3,
                child: _buildSettingsPanel(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final e, final _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildSettingsPanel() => SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customize Receipt', style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 24.h),
            TextField(
              controller: _headerController,
              decoration: const InputDecoration(labelText: 'Header Text'),
              maxLines: 2,
              onChanged: (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(headerText: val)),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _footerController,
              decoration: const InputDecoration(labelText: 'Footer Text'),
              maxLines: 2,
              onChanged: (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(footerText: val)),
            ),
            SizedBox(height: 24.h),
            const Divider(),
            SizedBox(height: 24.h),
            _switchTile('Show Logo', _localTemplate!.showLogo, (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(showLogo: val))),
            _switchTile('Show Tax', _localTemplate!.showTax, (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(showTax: val))),
            _switchTile('Show Discounts', _localTemplate!.showDiscount, (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(showDiscount: val))),
            SizedBox(height: 24.h),
            DropdownButtonFormField<String>(
              initialValue: _localTemplate!.paperSize,
              items: ['58mm', '80mm', 'A4'].map((final s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(paperSize: val!)),
              decoration: InputDecoration(
                labelText: 'Paper Size',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(height: 24.h),
            Text('Layout Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            SizedBox(height: 12.h),
            _buildStyleSelector(),
          ],
        ),
      );

  Widget _buildStyleSelector() {
    final styles = ['Classic', 'Minimal', 'Modern'];
    return Row(
      children: styles.map((final style) {
        final isSelected = _localTemplate!.layoutStyle == style;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: ChoiceChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(layoutStyle: style)),
              selectedColor: Colors.blue[50],
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.blue[700] : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _switchTile(final String title, final bool value, final ValueChanged<bool> onChanged) => SwitchListTile(
        title: Text(title, style: TextStyle(fontSize: 14.sp)),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      );

  Widget _buildBottomAction() => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
        child: ElevatedButton(
          onPressed: () async {
            await ref.read(receiptTemplateActionsProvider.notifier).saveTemplate(_localTemplate!);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template saved successfully')));
          },
          child: const Text('Save Template'),
        ),
      );
}

class _ReceiptPreview extends StatelessWidget {
  final ReceiptTemplateModel template;
  const _ReceiptPreview({required this.template});

  @override
  Widget build(final BuildContext context) {
    final business = ProviderScope.containerOf(context).read(currentBusinessProvider);
    final isMinimal = template.layoutStyle == 'Minimal';
    final isModern = template.layoutStyle == 'Modern';

    return Container(
      width: 250.w,
      padding: EdgeInsets.all(isMinimal ? 12.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isModern ? Border.all(color: Colors.grey[200]!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isMinimal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (template.showLogo) 
            Icon(
              isModern ? Icons.storefront_outlined : Icons.business, 
              size: isModern ? 48.sp : 40.sp,
              color: isModern ? Colors.blue[700] : Colors.black87,
            ),
          SizedBox(height: 12.h),
          Text(
            business?.name ?? 'Business Name', 
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: isModern ? 16.sp : 14.sp,
            ),
          ),
          if (template.headerText != null && template.headerText!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              template.headerText!, 
              textAlign: isMinimal ? TextAlign.left : TextAlign.center, 
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
            ),
          ],
          SizedBox(height: 12.h),
          if (!isMinimal) const Divider(),
          SizedBox(height: 8.h),
          _itemRow('Sample Item 1', '1 x \$10.00', '10.00', template.layoutStyle),
          _itemRow('Sample Item 2', '2 x \$12.50', '25.00', template.layoutStyle),
          SizedBox(height: 8.h),
          const Divider(),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL', 
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: isModern ? 16.sp : 14.sp,
                ),
              ),
              Text(
                '\$35.00', 
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: isModern ? 16.sp : 14.sp,
                ),
              ),
            ],
          ),
          if (template.footerText != null && template.footerText!.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Text(
              template.footerText!, 
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(final String name, final String qtyPrice, final String total, final String style) {
    final isMinimal = style == 'Minimal';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500)),
              Text('\$$total', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ],
          ),
          if (!isMinimal)
            Text(qtyPrice, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey)),
        ],
      ),
    );
  }
}
