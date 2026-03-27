import '../../data/models/receipt_template_model.dart';

abstract class ReceiptTemplateRepository {
  Future<ReceiptTemplateModel> getTemplate(final String businessId);
  Future<void> saveTemplate(final ReceiptTemplateModel template);
}
