import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../models/coin.dart';
import 'coin_details_screen.dart';
import 'coin_list_screen.dart' show ChangePill, avatarColorFor;

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights'), centerTitle: false),
      body: BlocBuilder<CoinListBloc, CoinListState>(
        builder: (context, state) {
          if (state.status != CoinListStatus.success || state.allCoins.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final coins = state.allCoins;
          final gainers = [...coins]
            ..sort((a, b) =>
                b.priceChangePercent24h.compareTo(a.priceChangePercent24h));
          final losers = [...coins]
            ..sort((a, b) =>
                a.priceChangePercent24h.compareTo(b.priceChangePercent24h));
          final byVolume = [...coins]
            ..sort((a, b) => b.quoteVolume24h.compareTo(a.quoteVolume24h));

          final totalQuoteVolume =
              coins.fold<double>(0, (sum, c) => sum + c.quoteVolume24h);
          final gainersCount =
              coins.where((c) => c.priceChangePercent24h > 0).length;
          final losersCount = coins.length - gainersCount;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _OverviewCard(
                totalQuoteVolume: totalQuoteVolume,
                gainersCount: gainersCount,
                losersCount: losersCount,
                totalCoins: coins.length,
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Top Gainers (24h)',
                icon: Icons.trending_up_rounded,
                color: AppColors.gain,
              ),
              _HorizontalCoinStrip(coins: gainers.take(10).toList()),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Top Losers (24h)',
                icon: Icons.trending_down_rounded,
                color: AppColors.loss,
              ),
              _HorizontalCoinStrip(coins: losers.take(10).toList()),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Highest Volume',
                icon: Icons.bar_chart_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              ...byVolume.take(5).map((c) => _VolumeRow(coin: c)),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.totalQuoteVolume,
    required this.gainersCount,
    required this.losersCount,
    required this.totalCoins,
  });

  final double totalQuoteVolume;
  final int gainersCount;
  final int losersCount;
  final int totalCoins;

  @override
  Widget build(BuildContext context) {
    final gainerRatio = totalCoins == 0 ? 0.5 : gainersCount / totalCoins;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market Sentiment',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: gainerRatio,
              minHeight: 10,
              backgroundColor: AppColors.loss.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation(AppColors.gain),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$gainersCount gainers',
                  style: const TextStyle(
                      color: AppColors.gain, fontSize: 12)),
              Text('$losersCount losers',
                  style: const TextStyle(color: AppColors.loss, fontSize: 12)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total 24h Quote Volume',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(_formatLarge(totalQuoteVolume),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatLarge(double value) {
    if (value >= 1e9) return '\$${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '\$${(value / 1e6).toStringAsFixed(2)}M';
    if (value >= 1e3) return '\$${(value / 1e3).toStringAsFixed(2)}K';
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}

class _HorizontalCoinStrip extends StatelessWidget {
  const _HorizontalCoinStrip({required this.coins});
  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coins.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final coin = coins[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CoinDetailsScreen(coin: coin)),
            ),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: avatarColorFor(coin.baseAsset),
                        child: Text(coin.baseAsset.characters.first,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(coin.baseAsset,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ],
                  ),
                  Text('\$${coin.lastPrice.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12)),
                  ChangePill(percent: coin.priceChangePercent24h, compact: true),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CoinDetailsScreen(coin: coin)),
      ),
      leading: CircleAvatar(
        backgroundColor: avatarColorFor(coin.baseAsset),
        child: Text(coin.baseAsset.characters.first,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      title: Text(coin.baseAsset),
      subtitle: Text(coin.symbol,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12)),
      trailing: Text(
        _OverviewCard._formatLarge(coin.quoteVolume24h),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
