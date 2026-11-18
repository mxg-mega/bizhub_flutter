import 'package:dio/dio.dart';
import 'gold_price_model.dart';

class GoldPriceApi {
  final Dio _dio;
  final String _baseUrl;

  GoldPriceApi(this._dio, {final String baseUrl = 'https://api.metalpriceapi.com/v1/'})
      : _baseUrl = baseUrl;

  Future<GoldPriceResponseModel> getGoldPrice({
    required final String apiKey,
    final String base = 'USD',
    final String currencies = 'XAU',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_baseUrl}latest',
      queryParameters: <String, dynamic>{
        'api_key': apiKey,
        'base': base,
        'currencies': currencies,
      },
    );
    return GoldPriceResponseModel.fromJson(response.data!);
  }
}
