import 'package:dio/dio.dart';
import '../models/coin.dart';

/// Thin wrapper around Binance's public REST API. No API key required for
/// these read-only market-data endpoints.
class BinanceApiService {
  BinanceApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.binance.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  /// Returns 24hr rolling stats for every symbol. This single call powers
  /// the whole coin list screen (price, % change, volume) without needing
  /// per-coin requests.
  Future<List<Coin>> fetchTicker24hr() async {
    final response = await _dio.get('/api/v3/ticker/24hr');
    final data = response.data as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(Coin.fromBinanceTicker)
        .toList();
  }

  /// Klines (candlesticks) for a single symbol, used to draw the price chart.
  /// interval examples: 1m, 5m, 15m, 1h, 4h, 1d, 1w
  Future<List<Candle>> fetchKlines(
    String symbol, {
    String interval = '1h',
    int limit = 100,
  }) async {
    final response = await _dio.get('/api/v3/klines', queryParameters: {
      'symbol': symbol,
      'interval': interval,
      'limit': limit,
    });
    final data = response.data as List<dynamic>;
    return data.map((raw) => Candle.fromBinanceKline(raw as List)).toList();
  }

  /// Exchange metadata — useful for validating which symbols are actually
  /// tradeable/active, to filter out delisted or unusual pairs from the list.
  Future<List<String>> fetchActiveSymbols() async {
    final response = await _dio.get('/api/v3/exchangeInfo');
    final symbols = response.data['symbols'] as List<dynamic>;
    return symbols
        .cast<Map<String, dynamic>>()
        .where((s) => s['status'] == 'TRADING')
        .map((s) => s['symbol'] as String)
        .toList();
  }
}
