/// Canonical payment-method values shared with the Next.js client.
///
/// Contract: docs/PORTING_GUIDE.md §4.
/// Canonical write set: `cash`, `card`, `bank_transfer`, `on_credit`, `other`.
/// Reads must tolerate legacy variants observed in production:
///  - `'bank transfer'` (web POS bug: `"Bank Transfer".toLowerCase()`)
///  - `'transfer'` (legacy Flutter customer page)
///  - any casing of the display labels (`'Cash'`, `'Bank Transfer'`, …).
library;

const String kPaymentMethodCash = 'cash';
const String kPaymentMethodCard = 'card';
const String kPaymentMethodBankTransfer = 'bank_transfer';
const String kPaymentMethodOnCredit = 'on_credit';
const String kPaymentMethodOther = 'other';

const Set<String> kCanonicalPaymentMethods = {
  kPaymentMethodCash,
  kPaymentMethodCard,
  kPaymentMethodBankTransfer,
  kPaymentMethodOnCredit,
  kPaymentMethodOther,
};

/// Normalizes any raw stored/UI value to the canonical payment-method string.
///
/// - `null` / empty → `cash` (the web read default, use-sales.tsx:897).
/// - Known aliases → canonical value.
/// - Unknown values → lowercased snake_case (tolerant display, never crashes).
String normalizePaymentMethod(final dynamic raw) {
  if (raw == null) return kPaymentMethodCash;
  if (raw is! String) return kPaymentMethodCash;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return kPaymentMethodCash;

  final snake = trimmed.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  switch (snake) {
    case kPaymentMethodCash:
      return kPaymentMethodCash;
    case kPaymentMethodCard:
      return kPaymentMethodCard;
    case kPaymentMethodBankTransfer:
    case 'transfer':
      return kPaymentMethodBankTransfer;
    case kPaymentMethodOnCredit:
    case 'credit':
      return kPaymentMethodOnCredit;
    case kPaymentMethodOther:
      return kPaymentMethodOther;
    default:
      return snake;
  }
}

/// True when the given raw value refers to a credit sale.
bool isCreditPaymentMethod(final dynamic raw) =>
    normalizePaymentMethod(raw) == kPaymentMethodOnCredit;
