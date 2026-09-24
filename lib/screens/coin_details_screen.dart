import 'package:crypto_app/constants/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/watchlist/watchlist_bloc.dart';
import '../models/coin.dart';
import '../services/binance_api_service.dart';
import '../widgets/coin_widgets.dart';

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
      _candlesFuture = _api.fetchKlines(widget.coin.symbol, interval: interval);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coin = widget.coin;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CoinAvatar(symbol: coin.baseAsset, size: 32),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coin.baseAsset,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                Text(
                  coin.quoteSymbol.isEmpty
                      ? coin.symbol
                      : '${coin.baseAsset} / ${coin.quoteSymbol}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          WatchStar(symbol: coin.symbol, size: 26),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _PriceHeader(coin: coin),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _IntervalSelector(
                    selected: _interval, onChanged: _changeInterval),
                const SizedBox(height: 14),
                SizedBox(
                  height: 270,
                  child: FutureBuilder<List<Candle>>(
                    future: _candlesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Chart unavailable'),
                              TextButton(
                                onPressed: () => _changeInterval(_interval),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      final candles = snapshot.data ?? const <Candle>[];
                      if (candles.length < 2) {
                        return const Center(child: Text('No chart data'));
                      }
                      return _ChartView(
                          candles: candles, prefix: coin.pricePrefix);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _RangeCard(coin: coin),
          const SizedBox(height: 8),
          const SectionTitle('Market Stats'),
          _StatsGrid(coin: coin),
          const SizedBox(height: 24),
          _WatchButton(coin: coin),
        ],
      ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            coin.priceLabel,
            style: const TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ChangePill(percent: coin.priceChangePercent24h),
            const SizedBox(width: 8),
            Text('Past 24 hours',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  static const _intervals = {
    '15m': '15m',
    '1h': '1H',
    '4h': '4H',
    '1d': '1D',
    '1w': '1W',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final e in _intervals.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (e.key == selected) return;
                  HapticFeedback.selectionClick();
                  onChanged(e.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == e.key
                        ? cs.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected == e.key ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartView extends StatelessWidget {
  const _ChartView({required this.candles, required this.prefix});
  final List<Candle> candles;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final first = candles.first.close;
    final last = candles.last.close;
    final change = first == 0 ? 0.0 : (last - first) / first * 100;
    var high = candles.first.close, low = candles.first.close;
    for (final c in candles) {
      if (c.close > high) high = c.close;
      if (c.close < low) low = c.close;
    }
    final color = change >= 0 ? AppColors.gain : AppColors.loss;
    final muted = TextStyle(color: cs.onSurfaceVariant, fontSize: 12);

    return Column(
      children: [
        Row(
          children: [
            ChangePill(percent: change, compact: true),
            const SizedBox(width: 8),
            Text('this period', style: muted),
            const Spacer(),
            Text('H $prefix${formatPrice(high)}', style: muted),
            const SizedBox(width: 10),
            Text('L $prefix${formatPrice(low)}', style: muted),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _PriceLineChart(candles: candles, color: color, prefix: prefix),
        ),
      ],
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  const _PriceLineChart({
    required this.candles,
    required this.color,
    required this.prefix,
  });
  final List<Candle> candles;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spots = <FlSpot>[
      for (var i = 0; i < candles.length; i++)
        FlSpot(i.toDouble(), candles[i].close),
    ];
    var minY = spots.first.y, maxY = spots.first.y;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    final range = maxY - minY;
    final pad = range == 0 ? (maxY.abs() * 0.01 + 1e-9) : range * 0.12;
    final lo = minY - pad;
    final hi = maxY + pad;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: lo,
        maxY: hi,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (hi - lo) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) => touched
                .map((s) => LineTooltipItem(
                      '$prefix${formatPrice(s.y)}',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
          getTouchedSpotIndicator: (barData, indexes) => indexes
              .map((_) => TouchedSpotIndicatorData(
                    FlLine(
                      color: color.withValues(alpha: 0.6),
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                    ),
                    FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4.5,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ))
              .toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.18,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final low = coin.lowPrice24h, high = coin.highPrice24h;
    final span = high - low;
    final t = span <= 0
        ? 0.5
        : ((coin.lastPrice - low) / span).clamp(0.0, 1.0).toDouble();
    final muted = TextStyle(color: cs.onSurfaceVariant, fontSize: 12);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('24h Range',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text('${coin.rangePercent24h.toStringAsFixed(2)}% swing',
                  style: muted),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: 16,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                          colors: [AppColors.loss, AppColors.gain]),
                    ),
                  ),
                  Positioned(
                    left: (c.maxWidth - 14) * t,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.surface,
                        border: Border.all(color: cs.onSurface, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low  ${coin.pricePrefix}${formatPrice(low)}', style: muted),
              Text('High  ${coin.pricePrefix}${formatPrice(high)}',
                  style: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final p = coin.pricePrefix;
    final stats = <(String, String, IconData)>[
      ('24h High', '$p${formatPrice(coin.highPrice24h)}', Icons.north_east_rounded),
      ('24h Low', '$p${formatPrice(coin.lowPrice24h)}', Icons.south_east_rounded),
      (
        '24h Volume (${coin.baseAsset})',
        formatCompact(coin.volume24h, prefix: ''),
        Icons.bar_chart_rounded
      ),
      (
        '24h Volume (${coin.quoteSymbol.isEmpty ? 'quote' : coin.quoteSymbol})',
        formatCompact(coin.quoteVolume24h, prefix: p),
        Icons.payments_rounded
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in stats)
              SizedBox(
                width: w,
                child: _StatTile(label: s.$1, value: s.$2, icon: s.$3),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _WatchButton extends StatelessWidget {
  const _WatchButton({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      buildWhen: (prev, curr) =>
          prev.contains(coin.symbol) != curr.contains(coin.symbol),
      builder: (context, state) {
        final watched = state.contains(coin.symbol);
        void toggle() {
          HapticFeedback.lightImpact();
          context.read<WatchlistBloc>().add(WatchlistToggled(coin.symbol));
        }

        return SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: watched
                ? OutlinedButton.icon(
                    onPressed: toggle,
                    icon: const Icon(Icons.star_rounded,
                        color: AppColors.watchlistStar),
                    label: const Text('Remove from watchlist'),
                  )
                : FilledButton.icon(
                    onPressed: toggle,
                    icon: const Icon(Icons.star_border_rounded),
                    label: const Text('Add to watchlist'),
                  ),
          ),
        );
      },
    );
  }
}