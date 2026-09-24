import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../models/coin.dart';
import '../widgets/coin_widgets.dart';

enum _Highlight { gainers, losers, volume, volatile }

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  _Highlight _highlight = _Highlight.gainers;

  static const _highlightMeta = {
    _Highlight.gainers: ('Top Gainers', Icons.trending_up_rounded),
    _Highlight.losers: ('Top Losers', Icons.trending_down_rounded),
    _Highlight.volume: ('Highest Volume', Icons.bar_chart_rounded),
    _Highlight.volatile: ('Most Volatile', Icons.bolt_rounded),
  };

  List<Coin> _highlightList(List<Coin> coins) {
    final list = switch (_highlight) {
      _Highlight.gainers => coins.where((c) => c.priceChangePercent24h > 0).toList()
        ..sort((a, b) =>
            b.priceChangePercent24h.compareTo(a.priceChangePercent24h)),
      _Highlight.losers => coins.where((c) => c.priceChangePercent24h < 0).toList()
        ..sort((a, b) =>
            a.priceChangePercent24h.compareTo(b.priceChangePercent24h)),
      _Highlight.volume => [...coins]
        ..sort((a, b) => b.quoteVolume24h.compareTo(a.quoteVolume24h)),
      _Highlight.volatile => [...coins]
        ..sort((a, b) => b.rangePercent24h.compareTo(a.rangePercent24h)),
    };
    return list.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CoinListBloc, CoinListState>(
          builder: (context, state) {
            if (state.status == CoinListStatus.failure) {
              return StateMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Couldn\'t load insights',
                message: state.errorMessage,
                actionLabel: 'Retry',
                onAction: () =>
                    context.read<CoinListBloc>().add(const CoinListStarted()),
              );
            }
            if (state.status != CoinListStatus.success ||
                state.allCoins.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final coins = liquidUsdMarkets(state.allCoins);
            if (coins.isEmpty) {
              return const StateMessage(
                icon: Icons.insights_rounded,
                title: 'No market data yet',
                message: 'Pull to refresh on the Markets tab.',
              );
            }
            final stats = MarketStats.from(coins);
            final movers = ([...coins]..sort((a, b) => b.priceChangePercent24h
                    .abs()
                    .compareTo(a.priceChangePercent24h.abs())))
                .take(10)
                .toList();
            final highlights = _highlightList(coins);

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _header(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SentimentCard(stats: stats),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TldrCard(stats: stats),
                ),
                const SectionTitle('Biggest Movers',
                    icon: Icons.local_fire_department_rounded,
                    color: Color(0xFFF97316)),
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: movers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _MoverCard(coin: movers[i]),
                  ),
                ),
                SectionTitle('Coin Highlights',
                    icon: _highlightMeta[_highlight]!.$2,
                    color: Theme.of(context).colorScheme.primary),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final e in _highlightMeta.entries) ...[
                        PillChip(
                          label: e.value.$1,
                          icon: e.value.$2,
                          selected: _highlight == e.key,
                          onTap: () => setState(() => _highlight = e.key),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < highlights.length; i++)
                  CoinRow(
                    key: ValueKey('${_highlight.name}-${highlights[i].symbol}'),
                    coin: highlights[i],
                    rank: i + 1,
                    subtitle: _highlight == _Highlight.volatile
                        ? '24h swing ${highlights[i].rangePercent24h.toStringAsFixed(1)}%'
                        : null,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          const BrandMark(size: 38),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Insights',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
              Text('Market overview · USDT pairs',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentimentCard extends StatelessWidget {
  const _SentimentCard({required this.stats});
  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final moodColor = stats.isBullish ? AppColors.gain : AppColors.loss;
    final avgColor = stats.avgChange >= 0 ? AppColors.gain : AppColors.loss;

    Widget kv(String k, String v, {Color? color}) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: TextStyle(color: cs.onSurfaceVariant)),
            Text(v,
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ],
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Market Sentiment',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(stats.sentimentLabel,
                    style: TextStyle(
                        color: moodColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(stats.upRatio * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('of markets are up today',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RatioBar(ratio: stats.upRatio, height: 10),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${stats.up} gainers',
                  style: const TextStyle(color: AppColors.gain, fontSize: 12)),
              Text('${stats.down} losers',
                  style: const TextStyle(color: AppColors.loss, fontSize: 12)),
            ],
          ),
          const Divider(height: 28),
          kv('Total 24h volume', formatCompact(stats.totalVolume)),
          const SizedBox(height: 10),
          kv('Avg. 24h change', formatPercent(stats.avgChange), color: avgColor),
          const SizedBox(height: 10),
          kv('Markets tracked', '${stats.total}'),
        ],
      ),
    );
  }
}

/// Auto-generated from live data — no made-up news.
class _TldrCard extends StatelessWidget {
  const _TldrCard({required this.stats});
  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = stats.topGainer, l = stats.topLoser, v = stats.topVolume;

    final lines = <String>[
      '${stats.up} of ${stats.total} USDT markets are up over 24h — '
          'sentiment looks ${stats.sentimentLabel.toLowerCase()}.',
      if (g != null && l != null)
        '${g.baseAsset} leads the gainers at ${formatPercent(g.priceChangePercent24h)}, '
            'while ${l.baseAsset} is the weakest at ${formatPercent(l.priceChangePercent24h)}.',
      if (v != null)
        '${v.baseAsset} is the most traded pair with ${formatCompact(v.quoteVolume24h)} in 24h volume.',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.watchlistStar),
              const SizedBox(width: 8),
              const Text('TLDR',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(width: 8),
              Text('· Live snapshot',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          color: cs.primary, shape: BoxShape.circle),
                    ),
                  ),
                  Expanded(
                    child: Text(line,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 140,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => openCoin(context, coin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CoinAvatar(symbol: coin.baseAsset, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(coin.baseAsset,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
            Text(coin.priceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ChangePill(percent: coin.priceChangePercent24h),
          ],
        ),
      ),
    );
  }
}