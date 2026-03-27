import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/services/import/import_models.dart';
import '../../../../../core/services/import/import_wizard_provider.dart';
import '../../../../../shared/presentation/widgets/common_app_bar.dart';


class ImportWizardPage extends ConsumerWidget {
  const ImportWizardPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final state = ref.watch(importWizardProvider);

    return Scaffold(
      appBar: CommonAppBar(
        // title: 'Import Inventory',
        actions: [
          if (state.step != ImportStep.upload)
            TextButton(
              onPressed: () => ref.read(importWizardProvider.notifier).reset(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepProgress(state.step),
          Expanded(
            child: _buildCurrentStep(context, ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress(final ImportStep step) {
    final steps = ['Upload', 'Mapping', 'Preview', 'Complete'];
    final currentIndex = step.index;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (final i) {
          final isActive = i <= currentIndex;
          return Row(
            children: [
              Container(
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                steps[i],
                style: TextStyle(
                  color: isActive ? Colors.blue : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.sp,
                ),
              ),
              if (i < steps.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Icon(Icons.chevron_right, size: 16.sp, color: Colors.grey[400]),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(final BuildContext context, final WidgetRef ref, final ImportWizardState state) {
    switch (state.step) {
      case ImportStep.upload:
        return _UploadStepView();
      case ImportStep.mapping:
        return _MappingStepView(state: state);
      case ImportStep.preview:
        return _PreviewStepView(state: state);
      case ImportStep.processing:
        return _ProcessingStepView(state: state);
      case ImportStep.complete:
        return _CompleteStepView();
    }
  }
}

class _UploadStepView extends ConsumerWidget {
  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 80.r, color: Colors.blue[200]),
            SizedBox(height: 24.h),
            Text(
              'Upload CSV File',
              style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            const Text(
              'Select a CSV file containing your product list.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => ref.read(importWizardProvider.notifier).pickAndParseFile(),
              icon: const Icon(Icons.file_open),
              label: const Text('Select File'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200.w, 56.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MappingStepView extends ConsumerWidget {
  final ImportWizardState state;
  const _MappingStepView({required this.state});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final systemFields = [
      'name', 'sku', 'description', 'category', 'cost', 'price', 'stock', 'sellingUnit', 'purchaseUnit'
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: state.mappings.length,
            itemBuilder: (final context, final index) {
              final m = state.mappings[index];
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(m.userHeader, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.arrow_forward),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: m.systemField,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          hint: const Text('Select field'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Ignore')),
                            ...systemFields.map((final f) => DropdownMenuItem(value: f, child: Text(f))),
                          ],
                          onChanged: (final val) {
                            ref.read(importWizardProvider.notifier).updateMapping(m.userHeader, val, val == null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            onPressed: () => ref.read(importWizardProvider.notifier).goToPreview(),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('Next: Preview Data'),
          ),
        ),
      ],
    );
  }
}

class _PreviewStepView extends ConsumerWidget {
  final ImportWizardState state;
  const _PreviewStepView({required this.state});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                ],
                rows: state.previewData.map((final row) {
                  final hasErrors = row.errors.isNotEmpty;
                  return DataRow(
                    cells: [
                      DataCell(Icon(
                        hasErrors ? Icons.error_outline : Icons.check_circle_outline,
                        color: hasErrors ? Colors.red : Colors.green,
                      )),
                      DataCell(Text(row.data['name']?.toString() ?? 'MISSING')),
                      DataCell(Text(row.data['price']?.toString() ?? '0')),
                      DataCell(Text(row.data['stock']?.toString() ?? '0')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            onPressed: () => ref.read(importWizardProvider.notifier).processImport(),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: Text('Import ${state.previewData.length} Products'),
          ),
        ),
      ],
    );
  }
}

class _ProcessingStepView extends StatelessWidget {
  final ImportWizardState state;
  const _ProcessingStepView({required this.state});

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 24.h),
            Text('Processing Import...', style: GoogleFonts.inter(fontSize: 18.sp)),
            SizedBox(height: 16.h),
            LinearProgressIndicator(value: state.progress),
            SizedBox(height: 8.h),
            Text('${(state.progress * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }
}

class _CompleteStepView extends ConsumerWidget {
  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 24.h),
          Text('Import Successful!', style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () {
              ref.read(importWizardProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('Return to Inventory'),
          ),
        ],
      ),
    );
  }
}
