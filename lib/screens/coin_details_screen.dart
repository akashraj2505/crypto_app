import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../blocs/watchlist/watchlist_bloc.dart';
import '../models/coin.dart';
import '../services/binance_api_service.dart';

class CoinDetailsScreen extends StatefulWidget {
  const CoinDetailsScreen({super.key, required this.coin});
  final Coin coin;

  @override
  State<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends State<CoinDetailsScreen> {
  final _api = BinanceApiService();
  late Future<List<Candle>> _candlesFuture;
  String _interval = '1h';

  @override
  void initState() {
    super.initState();
    _candlesFuture = _api.fetchKlines(widget.coin.symbol, interval: _interval);
  }

  void _changeInterval(String interval) {
    setState(() {
      _interval = interval;
      _candlesFuture =
          _api.fetchKlines(widget.coin.symbol, interval: interval);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coin = widget.coin;
    final isUp = coin.priceChangePercent24h >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${coin.baseAsset} / ${coin.symbol.substring(coin.baseAsset.length)}'),
        actions: [
          BlocBuilder<WatchlistBloc, WatchlistState>(
            buildWhen: (prev, curr) =>
                prev.contains(coin.symbol) != curr.contains(coin.symbol),
            builder: (context, state) {
              final isWatched = state.contains(coin.symbol);
              return IconButton(
                icon: Icon(isWatched ? Icons.star_rounded : Icons.star_border_rounded),
                color: isWatched ? AppColors.watchlistStar : null,
                onPressed: () => context
                    .read<WatchlistBloc>()
                    .add(WatchlistToggled(coin.symbol)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('\$${coin.lastPrice.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.headlineMedium),
          Text(
            '${isUp ? '+' : ''}${coin.priceChangePercent24h.toStringAsFixed(2)}% (24h)',
            style: TextStyle(
                color: isUp ? AppColors.gain : AppColors.loss,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _IntervalSelector(selected: _interval, onChanged: _changeInterval),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: FutureBuilder<List<Candle>>(
              future: _candlesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Chart unavailable'));
                }
                final candles = snapshot.data ?? [];
                if (candles.isEmpty) {
                  return const Center(child: Text('No chart data'));
                }
                return _PriceLineChart(candles: candles, isUp: isUp);
              },
            ),
          ),
          const SizedBox(height: 24),
          _StatsGrid(coin: coin),
        ],
      ),
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  static const _intervals = ['15m', '1h', '4h', '1d', '1w'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _intervals.map((interval) {
        return ChoiceChip(
          label: Text(interval),
          selected: selected == interval,
          onSelected: (_) => onChanged(interval),
        );
      }).toList(),
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  const _PriceLineChart({required this.candles, required this.isUp});
  final List<Candle> candles;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < candles.length; i++)
        FlSpot(i.toDouble(), candles[i].close),
    ];
    final color = isUp ? AppColors.gain : AppColors.loss;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                    '\$${s.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
      // Animate transitions when switching intervals for a smoother feel.
      duration: const Duration(milliseconds: 300),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final stats = <String, String>{
      '24h High': '\$${coin.highPrice24h.toStringAsFixed(4)}',
      '24h Low': '\$${coin.lowPrice24h.toStringAsFixed(4)}',
      '24h Volume': coin.volume24h.toStringAsFixed(2),
      '24h Quote Vol': coin.quoteVolume24h.toStringAsFixed(2),
    };

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: stats.entries.map((e) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.key,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
