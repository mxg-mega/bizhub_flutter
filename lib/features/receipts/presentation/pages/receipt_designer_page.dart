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
            Text('Paper Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              initialValue: _localTemplate!.paperSize,
              items: ['58mm', '80mm', 'A4'].map((final s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (final val) => setState(() => _localTemplate = _localTemplate!.copyWith(paperSize: val!)),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      );

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
    
    return Container(
      width: 250.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (template.showLogo) const Icon(Icons.business, size: 40),
          SizedBox(height: 12.h),
          Text(business?.name ?? 'Business Name', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(template.headerText ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          const Divider(),
          _itemRow('Item 1', '10.00'),
          _itemRow('Item 2', '25.00'),
          const Divider(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$35.00', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12.h),
          Text(template.footerText ?? '', style: TextStyle(fontSize: 8.sp, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _itemRow(final String name, final String price) => Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontSize: 10.sp)),
            Text('\$$price', style: TextStyle(fontSize: 10.sp)),
          ],
        ),
      );
}
