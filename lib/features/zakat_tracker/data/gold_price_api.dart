import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'gold_price_model.dart';

part 'gold_price_api.g.dart';

@RestApi(baseUrl: 'https://api.metalpriceapi.com/v1/')
abstract class GoldPriceApi {
  factory GoldPriceApi(final Dio dio, {final String baseUrl}) = _GoldPriceApi;

  @GET('latest')
  Future<GoldPriceResponseModel> getGoldPrice({
    @Query('api_key') required final String apiKey,
    @Query('base') final String base = 'USD',
    @Query('currencies') final String currencies = 'XAU',
  });
}
