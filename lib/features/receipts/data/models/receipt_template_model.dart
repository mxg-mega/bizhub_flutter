import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'receipt_template_model.g.dart';

@collection
@JsonSerializable()
class ReceiptTemplateModel {
  Id get isarId => _fastHash(id);

  final String id;
  final String businessId;
  final String name;
  
  final String? headerText;
  final String? footerText;
  
  final bool showLogo;
  final bool showTax;
  final bool showDiscount;
  
  final String fontSize;
  final String paperSize;

  final DateTime updatedAt;

  const ReceiptTemplateModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.headerText,
    this.footerText,
    this.showLogo = true,
    this.showTax = true,
    this.showDiscount = true,
    this.fontSize = 'medium',
    this.paperSize = '58mm',
    required this.updatedAt,
  });

  factory ReceiptTemplateModel.defaultTemplate(final String businessId) =>
      ReceiptTemplateModel(
        id: 'default_$businessId',
        businessId: businessId,
        name: 'Standard Receipt',
        headerText: 'Thank you for shopping with us!',
        footerText: 'Powered by BizModule',
        updatedAt: DateTime.now(),
        showLogo: true,
        showTax: true,
        showDiscount: true,
        fontSize: 'medium',
        paperSize: '58mm',
      );

  factory ReceiptTemplateModel.fromJson(final Map<String, dynamic> json) =>
      _$ReceiptTemplateModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ReceiptTemplateModelToJson(this);

  ReceiptTemplateModel copyWith({
    final String? name,
    final String? headerText,
    final String? footerText,
    final bool? showLogo,
    final bool? showTax,
    final bool? showDiscount,
    final String? fontSize,
    final String? paperSize,
    final DateTime? updatedAt,
  }) =>
      ReceiptTemplateModel(
        id: id,
        businessId: businessId,
        name: name ?? this.name,
        headerText: headerText ?? this.headerText,
        footerText: footerText ?? this.footerText,
        showLogo: showLogo ?? this.showLogo,
        showTax: showTax ?? this.showTax,
        showDiscount: showDiscount ?? this.showDiscount,
        fontSize: fontSize ?? this.fontSize,
        paperSize: paperSize ?? this.paperSize,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  int _fastHash(final String string) {
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit;
      hash *= 0x100000001b3;
    }
    return hash;
  }
}
