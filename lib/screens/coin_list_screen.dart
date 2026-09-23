import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import '../models/coin.dart';
import 'coin_details_screen.dart';

class CoinListScreen extends StatelessWidget {
  const CoinListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markets'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _SearchAndSortBar(),
          Expanded(
            child: BlocBuilder<CoinListBloc, CoinListState>(
              builder: (context, state) {
                switch (state.status) {
                  case CoinListStatus.initial:
                  case CoinListStatus.loading:
                    return const _CoinListShimmer();
                  case CoinListStatus.failure:
                    return _ErrorView(message: state.errorMessage ?? 'Error');
                  case CoinListStatus.success:
                    if (state.isEmpty) {
                      return const _EmptyView();
                    }
                    return RefreshIndicator(
                      onRefresh: () async => context
                          .read<CoinListBloc>()
                          .add(const CoinListRefreshed()),
                      child: ListView.builder(
                        itemExtent: 72,
                        itemCount: state.visibleCoins.length,
                        itemBuilder: (context, index) {
                          final coin = state.visibleCoins[index];
                          return _CoinTile(coin: coin, rank: index + 1);
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndSortBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search coin (e.g. BTC)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (query) => context
                  .read<CoinListBloc>()
                  .add(CoinListSearchChanged(query)),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<CoinSortBy>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (sortBy) => context
                .read<CoinListBloc>()
                .add(CoinListSortChanged(sortBy)),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: CoinSortBy.volume, child: Text('Volume')),
              PopupMenuItem(
                  value: CoinSortBy.priceChange, child: Text('% Change')),
              PopupMenuItem(value: CoinSortBy.price, child: Text('Price')),
              PopupMenuItem(value: CoinSortBy.name, child: Text('Name')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Deterministic color per coin so avatars aren't all the same shade —
/// mimics the varied coin-logo colors you'd see in a real CoinGecko list.
Color avatarColorFor(String symbol) {
  const palette = [
    Color(0xFFF0B90B), // gold
    Color(0xFF3B82F6), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFF10B981), // green
    Color(0xFFEC4899), // pink
    Color(0xFFF97316), // orange
    Color(0xFF14B8A6), // teal
  ];
  final hash = symbol.codeUnits.fold<int>(0, (a, b) => a + b);
  return palette[hash % palette.length];
}

/// Small rounded pill for the 24h % change — matches CoinGecko's green/red
/// chip look rather than plain colored text.
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.percent, this.compact = false});
  final double percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isUp = percent >= 0;
    final color = isUp ? AppColors.gain : AppColors.loss;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isUp ? '+' : ''}${percent.toStringAsFixed(2)}%',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CoinTile extends StatelessWidget {
  const _CoinTile({required this.coin, required this.rank});
  final Coin coin;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      buildWhen: (prev, curr) =>
          prev.contains(coin.symbol) != curr.contains(coin.symbol),
      builder: (context, watchlistState) {
        final isWatched = watchlistState.contains(coin.symbol);
        return ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CoinDetailsScreen(coin: coin)),
          ),
          leading: SizedBox(
            width: 66,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  child: Text('$rank',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12)),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: avatarColorFor(coin.baseAsset),
                  child: Text(coin.baseAsset.characters.first,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          title: Text(coin.baseAsset,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(coin.symbol,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('\$${coin.lastPrice.toStringAsFixed(4)}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  ChangePill(percent: coin.priceChangePercent24h, compact: true),
                ],
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context
                    .read<WatchlistBloc>()
                    .add(WatchlistToggled(coin.symbol)),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isWatched ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 18,
                    color: isWatched
                        ? AppColors.watchlistStar
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinListShimmer extends StatelessWidget {
  const _CoinListShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).dividerColor,
      child: ListView.builder(
        itemExtent: 72,
        itemCount: 8,
        itemBuilder: (_, _) => const ListTile(
          leading: CircleAvatar(backgroundColor: Colors.white),
          title: SizedBox(height: 12, child: ColoredBox(color: Colors.white)),
          subtitle:
              SizedBox(height: 10, child: ColoredBox(color: Colors.white)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                context.read<CoinListBloc>().add(const CoinListStarted()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('No coins match your search'),
        ],
      ),
    );
  }
}
