import '../data/gold_price_model.dart';

abstract class GoldRepository {
  Future<GoldPriceModel> getGoldPrice(final String currency);
}
