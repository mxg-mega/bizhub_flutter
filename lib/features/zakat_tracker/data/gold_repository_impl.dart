import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/gold_repository.dart';
import 'gold_price_api.dart';
import 'gold_price_model.dart';

part 'gold_repository_impl.g.dart';

@riverpod
GoldRepository goldRepository(final GoldRepositoryRef ref) {
  final Dio dio = ref.watch(dioProvider);
  return GoldRepositoryImpl(GoldPriceApi(dio));
}

class GoldRepositoryImpl implements GoldRepository {
  final GoldPriceApi _api;

  GoldRepositoryImpl(this._api);

  @override
  Future<GoldPriceModel> getGoldPrice(final String currency) async {
    try {
      final String apiKey = dotenv.env['GOLD_API_KEY'] ?? '';
      
      if (apiKey.isEmpty) {
        throw Exception('Gold API key is missing. Please add GOLD_API_KEY to your .env file.');
      }

      // Fetch from MetalPriceAPI
      final GoldPriceResponseModel response = await _api.getGoldPrice(
        apiKey: apiKey,
        base: currency,
        currencies: 'XAU',
      );

      if (!response.success) {
        throw Exception('Failed to fetch gold price from API.');
      }

      // MetalPriceAPI returns rates as: 1 [Base] = X [Currency]
      // For USD and XAU, it returns how many ounces of gold 1 USD can buy.
      // To get the price of 1 ounce of gold in USD, we do 1 / rate.
      final double? rateXAU = response.rates['XAU'];
      if (rateXAU == null || rateXAU == 0) {
        throw Exception('Gold rate (XAU) not found in API response.');
      }

      final double pricePerOunce = 1.0 / rateXAU;

      return GoldPriceModel(
        price: pricePerOunce,
        timestamp: DateTime.fromMillisecondsSinceEpoch(response.timestamp * 1000),
        baseCurrency: response.base,
        rates: response.rates,
      );
    } on DioException catch (e) {
      final String message = _getErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  String _getErrorMessage(final DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The connection has timed out. Please check your internet connection and try again.';
      case DioExceptionType.badResponse:
        final int statusCode = e.response?.statusCode ?? 500;
        if (statusCode == 401 || statusCode == 403) {
          return 'Unauthorized access. Please check your API key.';
        } else if (statusCode == 404) {
          return 'Resource not found. The endpoint might have changed.';
        } else if (statusCode == 429) {
          return 'Rate limit exceeded. Too many requests in a short period.';
        }
        return 'Received a bad response from the server ($statusCode).';
      case DioExceptionType.cancel:
        return 'Request to the server was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please connect to a network and try again.';
      case DioExceptionType.unknown:
      default:
        return 'An unexpected network error occurred. Please try again later.';
    }
  }
}
