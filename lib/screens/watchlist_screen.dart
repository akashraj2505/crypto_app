import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import '../models/coin.dart';
import '../widgets/coin_widgets.dart';
import 'main_shell.dart';

enum _WatchSort { best, worst, volume, name }

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  static const _sortMeta = {
    _WatchSort.best: ('Best 24h', Icons.trending_up_rounded),
    _WatchSort.worst: ('Worst 24h', Icons.trending_down_rounded),
    _WatchSort.volume: ('Volume', Icons.bar_chart_rounded),
    _WatchSort.name: ('Name', Icons.sort_by_alpha_rounded),
  };

  _WatchSort _sort = _WatchSort.best;

  void _sortList(List<Coin> list) {
    switch (_sort) {
      case _WatchSort.best:
        list.sort((a, b) =>
            b.priceChangePercent24h.compareTo(a.priceChangePercent24h));
      case _WatchSort.worst:
        list.sort((a, b) =>
            a.priceChangePercent24h.compareTo(b.priceChangePercent24h));
      case _WatchSort.volume:
        list.sort((a, b) => b.quoteVolume24h.compareTo(a.quoteVolume24h));
      case _WatchSort.name:
        list.sort((a, b) => a.baseAsset.compareTo(b.baseAsset));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<WatchlistBloc, WatchlistState>(
          builder: (context, watchlistState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, watchlistState.symbols.length),
                Expanded(
                  child: watchlistState.symbols.isEmpty
                      ? StateMessage(
                          icon: Icons.star_border_rounded,
                          title: 'No coins in your watchlist yet',
                          message:
                              'Tap the star on any coin to track its price here.',
                          actionLabel: 'Browse markets',
                          onAction: () =>
                              MainShell.maybeOf(context)?.switchTo(0),
                        )
                      : _buildList(watchlistState),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int count) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const BrandMark(size: 38),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Watchlist',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
              Text(count == 0 ? 'Track your favourites' : '$count coin${count == 1 ? '' : 's'} tracked',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(WatchlistState watchlistState) {
    return BlocBuilder<CoinListBloc, CoinListState>(
      builder: (context, coinListState) {
        if (coinListState.status == CoinListStatus.failure) {
          return StateMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Couldn\'t load prices',
            message: coinListState.errorMessage,
            actionLabel: 'Retry',
            onAction: () =>
                context.read<CoinListBloc>().add(const CoinListStarted()),
          );
        }
        if (coinListState.status != CoinListStatus.success) {
          return const SingleChildScrollView(child: CoinListShimmer(count: 5));
        }

        final watched = coinListState.allCoins
            .where((c) => watchlistState.symbols.contains(c.symbol))
            .toList();
        _sortList(watched);

        if (watched.isEmpty) {
          return const StateMessage(
            icon: Icons.hourglass_empty_rounded,
            title: 'Prices unavailable',
            message: 'Your saved coins aren\'t in the current market data.',
          );
        }

        final avg = watched
                .map((c) => c.priceChangePercent24h)
                .reduce((a, b) => a + b) /
            watched.length;
        final cs = Theme.of(context).colorScheme;
        final bg = Theme.of(context).scaffoldBackgroundColor;

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Avg. 24h change',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(formatPercent(avg),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color:
                                    avg >= 0 ? AppColors.gain : AppColors.loss,
                              )),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Best performer',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          _bestOf(watched),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final e in _sortMeta.entries) ...[
                    PillChip(
                      label: e.value.$1,
                      icon: e.value.$2,
                      selected: _sort == e.key,
                      onTap: () => setState(() => _sort = e.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < watched.length; i++)
              _dismissible(context, watched[i], i + 1, bg),
          ],
        );
      },
    );
  }

  String _bestOf(List<Coin> coins) {
    var best = coins.first;
    for (final c in coins) {
      if (c.priceChangePercent24h > best.priceChangePercent24h) best = c;
    }
    return '${best.baseAsset} ${formatPercent(best.priceChangePercent24h)}';
  }

  Widget _dismissible(BuildContext context, Coin coin, int rank, Color bg) {
    final bloc = context.read<WatchlistBloc>();
    final messenger = ScaffoldMessenger.of(context);
    return Dismissible(
      key: ValueKey(coin.symbol),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.loss.withValues(alpha: 0.85),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        bloc.add(WatchlistToggled(coin.symbol));
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${coin.baseAsset} removed from watchlist'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => bloc.add(WatchlistToggled(coin.symbol)),
              ),
            ),
          );
      },
      child: ColoredBox(color: bg, child: CoinRow(coin: coin, rank: rank)),
    );
  }
}