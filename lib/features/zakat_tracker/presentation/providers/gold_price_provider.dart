import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/gold_price_model.dart';
import '../../data/gold_repository_impl.dart';

part 'gold_price_provider.g.dart';

@riverpod
Future<GoldPriceModel> goldPrice(final GoldPriceRef ref, {final String currency = 'USD'}) async {
  final repository = ref.watch(goldRepositoryProvider);
  return await repository.getGoldPrice(currency);
}
