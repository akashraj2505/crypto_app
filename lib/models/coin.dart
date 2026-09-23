import 'package:equatable/equatable.dart';

/// Represents a single trading pair from Binance's 24hr ticker endpoint.
/// Binance doesn't expose "market cap" or "circulating supply" directly like
/// CoinGecko, so those fields are left nullable and can be enriched later
/// (e.g. from a supplementary source) without breaking the core UI.
class Coin extends Equatable {
  final String symbol; // e.g. "BTCUSDT"
  final String baseAsset; // e.g. "BTC"
  final double lastPrice;
  final double priceChangePercent24h;
  final double highPrice24h;
  final double lowPrice24h;
  final double volume24h; // base asset volume
  final double quoteVolume24h; // e.g. USDT volume
  final double? marketCap; // optional enrichment, not from Binance
  final double? circulatingSupply; // optional enrichment, not from Binance

  const Coin({
    required this.symbol,
    required this.baseAsset,
    required this.lastPrice,
    required this.priceChangePercent24h,
    required this.highPrice24h,
    required this.lowPrice24h,
    required this.volume24h,
    required this.quoteVolume24h,
    this.marketCap,
    this.circulatingSupply,
  });

  factory Coin.fromBinanceTicker(Map<String, dynamic> json) {
    final symbol = json['symbol'] as String;
    return Coin(
      symbol: symbol,
      baseAsset: _extractBaseAsset(symbol),
      lastPrice: double.tryParse(json['lastPrice']?.toString() ?? '') ?? 0,
      priceChangePercent24h:
          double.tryParse(json['priceChangePercent']?.toString() ?? '') ?? 0,
      highPrice24h: double.tryParse(json['highPrice']?.toString() ?? '') ?? 0,
      lowPrice24h: double.tryParse(json['lowPrice']?.toString() ?? '') ?? 0,
      volume24h: double.tryParse(json['volume']?.toString() ?? '') ?? 0,
      quoteVolume24h:
          double.tryParse(json['quoteVolume']?.toString() ?? '') ?? 0,
    );
  }

  /// Binance symbols are like "BTCUSDT" — strip the common quote assets to
  /// get a display-friendly base asset. Extend this list as needed.
  static String _extractBaseAsset(String symbol) {
    const quoteAssets = ['USDT', 'BUSD', 'USDC', 'BTC', 'ETH', 'BNB'];
    for (final quote in quoteAssets) {
      if (symbol.endsWith(quote) && symbol.length > quote.length) {
        return symbol.substring(0, symbol.length - quote.length);
      }
    }
    return symbol;
  }

  Coin copyWith({double? marketCap, double? circulatingSupply}) {
    return Coin(
      symbol: symbol,
      baseAsset: baseAsset,
      lastPrice: lastPrice,
      priceChangePercent24h: priceChangePercent24h,
      highPrice24h: highPrice24h,
      lowPrice24h: lowPrice24h,
      volume24h: volume24h,
      quoteVolume24h: quoteVolume24h,
      marketCap: marketCap ?? this.marketCap,
      circulatingSupply: circulatingSupply ?? this.circulatingSupply,
    );
  }

  @override
  List<Object?> get props => [
        symbol,
        lastPrice,
        priceChangePercent24h,
        highPrice24h,
        lowPrice24h,
        volume24h,
        quoteVolume24h,
        marketCap,
        circulatingSupply,
      ];
}

/// A single OHLC candle from Binance's /klines endpoint, used for the
/// interactive price chart on the coin details screen.
class Candle extends Equatable {
  final DateTime openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const Candle({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromBinanceKline(List<dynamic> raw) {
    return Candle(
      openTime: DateTime.fromMillisecondsSinceEpoch(raw[0] as int),
      open: double.parse(raw[1].toString()),
      high: double.parse(raw[2].toString()),
      low: double.parse(raw[3].toString()),
      close: double.parse(raw[4].toString()),
      volume: double.parse(raw[5].toString()),
    );
  }

  @override
  List<Object?> get props => [openTime, open, high, low, close, volume];
}
