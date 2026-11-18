import '../../../../core/utils/datetime_converter.dart';

/// Business bank account saved in the web receipt designer
/// (`savedBankAccounts[]` / primary `bankDetails`).
class ReceiptBankDetails {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String routingNumber;
  final String paymentLink;
  final String label;

  const ReceiptBankDetails({
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
    this.routingNumber = '',
    this.paymentLink = '',
    this.label = '',
  });

  bool get hasData =>
      bankName.trim().isNotEmpty ||
      accountNumber.trim().isNotEmpty ||
      accountName.trim().isNotEmpty;

  factory ReceiptBankDetails.fromJson(final Map<String, dynamic> json) {
    String str(final Object? v) => v is String ? v : (v?.toString() ?? '');
    return ReceiptBankDetails(
      bankName: str(json['bankName']),
      accountName: str(json['accountName']),
      accountNumber: str(json['accountNumber']),
      routingNumber: str(json['routingNumber']),
      paymentLink: str(json['paymentLink']),
      label: str(json['label']),
    );
  }
}

/// Read-only mirror of the web receipt designer config
/// (`businesses/{b}/settings/receiptDesign`, `src/types/receipt-designer.ts`).
/// M10 consistency slice: mobile receipts render the web config but the
/// designer itself is deferred (docs/PORTING_GUIDE.md §9).
class ReceiptDesignModel {
  final String template; // 'modern' | 'classic' | 'minimalist'
  final String accentColor;
  final String fontFamily;
  final bool showLogo;
  final String businessInitial;
  final ReceiptBankDetails bankDetails;
  final List<ReceiptBankDetails> savedBankAccounts;
  final String notesAndTerms;
  final String footerText;
  final String subFooterText;
  final bool showWatermark;
  final bool showTax;
  final bool showDiscount;
  final bool showPaymentDetails;
  final bool showNotesAndTerms;
  final DateTime? updatedAt;

  const ReceiptDesignModel({
    this.template = 'modern',
    this.accentColor = '#0f766e',
    this.fontFamily = 'Space Grotesk',
    this.showLogo = true,
    this.businessInitial = 'B',
    this.bankDetails = const ReceiptBankDetails(),
    this.savedBankAccounts = const [],
    this.notesAndTerms = '',
    this.footerText = 'Thank you for your business.',
    this.subFooterText = 'Created with Bizmod',
    this.showWatermark = true,
    this.showTax = true,
    this.showDiscount = true,
    this.showPaymentDetails = true,
    this.showNotesAndTerms = true,
    this.updatedAt,
  });

  static const ReceiptDesignModel defaults = ReceiptDesignModel();

  /// Primary account first, then saved accounts (deduped by account number),
  /// mirroring the web's unified `savedBankAccounts` list (`use-receipt-design`).
  List<ReceiptBankDetails> get unifiedBankAccounts {
    final result = <ReceiptBankDetails>[];
    final seen = <String>{};
    for (final account in [bankDetails, ...savedBankAccounts]) {
      if (!account.hasData) continue;
      final key = account.accountNumber.trim();
      if (key.isNotEmpty && !seen.add(key)) continue;
      result.add(account);
    }
    return result;
  }

  factory ReceiptDesignModel.fromJson(final Map<String, dynamic> json) {
    final bankRaw = json['bankDetails'];
    final savedRaw = json['savedBankAccounts'];
    return ReceiptDesignModel(
      template: (json['template'] as String?) ?? 'modern',
      accentColor: (json['accentColor'] as String?) ?? '#0f766e',
      fontFamily: (json['fontFamily'] as String?) ?? 'Space Grotesk',
      showLogo: (json['showLogo'] as bool?) ?? true,
      businessInitial: (json['businessInitial'] as String?) ?? 'B',
      bankDetails: bankRaw is Map
          ? ReceiptBankDetails.fromJson(Map<String, dynamic>.from(bankRaw))
          : const ReceiptBankDetails(),
      savedBankAccounts: savedRaw is List
          ? savedRaw
              .whereType<Map>()
              .map((final a) =>
                  ReceiptBankDetails.fromJson(Map<String, dynamic>.from(a)))
              .toList()
          : const [],
      notesAndTerms: (json['notesAndTerms'] as String?) ?? '',
      footerText: (json['footerText'] as String?) ??
          'Thank you for your business.',
      subFooterText: (json['subFooterText'] as String?) ?? 'Created with Bizmod',
      showWatermark: (json['showWatermark'] as bool?) ?? true,
      showTax: (json['showTax'] as bool?) ?? true,
      showDiscount: (json['showDiscount'] as bool?) ?? true,
      showPaymentDetails: (json['showPaymentDetails'] as bool?) ?? true,
      showNotesAndTerms: (json['showNotesAndTerms'] as bool?) ?? true,
      updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
    );
  }
}
