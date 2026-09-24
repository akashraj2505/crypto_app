import 'package:crypto_app/constants/app_theme.dart';
import 'package:crypto_app/widgets/coin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import '../models/coin.dart';

// Re-exported so any old `import 'coin_list_screen.dart' show ChangePill...`
// keeps compiling.
export '../widgets/coin_widgets.dart' show ChangePill, avatarColorFor;

enum MarketFilter { all, trending, gainers, losers, watchlist }

class CoinListScreen extends StatefulWidget {
  const CoinListScreen({super.key});

  @override
  State<CoinListScreen> createState() => _CoinListScreenState();
}

class _CoinListScreenState extends State<CoinListScreen> {
  static const _quotes = [
    'ALL', 'USDT', 'USDC', 'FDUSD', 'BTC', 'ETH', 'BNB', 'EUR', 'TRY',
  ];
  static const _sortLabels = <CoinSortBy, String>{
    CoinSortBy.volume: 'Volume',
    CoinSortBy.priceChange: '% Change',
    CoinSortBy.price: 'Price',
    CoinSortBy.name: 'Name',
  };
  static const _chips = [
    (MarketFilter.all, 'All', Icons.apps_rounded),
    (MarketFilter.trending, 'Trending', Icons.local_fire_department_rounded),
    (MarketFilter.gainers, 'Top Gainers', Icons.rocket_launch_rounded),
    (MarketFilter.losers, 'Top Losers', Icons.trending_down_rounded),
    (MarketFilter.watchlist, 'Watchlist', Icons.star_rounded),
  ];

  final _search = TextEditingController();

  MarketFilter _filter = MarketFilter.all;
  String _quote = 'USDT';
  bool _hideZeroVolume = true;
  CoinSortBy? _sortBy;
  bool _reversed = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtersActive => _quote != 'USDT' || !_hideZeroVolume;

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final bloc = context.read<CoinListBloc>();
    bloc.add(const CoinListRefreshed());
    try {
      await bloc.stream
          .firstWhere((s) =>
              s.status == CoinListStatus.success ||
              s.status == CoinListStatus.failure)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Timed out or stream closed — let the spinner finish either way.
    }
  }

  void _onSort(CoinSortBy by) {
    HapticFeedback.selectionClick();
    if (_sortBy == by) {
      setState(() => _reversed = !_reversed);
      return;
    }
    setState(() {
      _sortBy = by;
      _reversed = false;
      // Sorting only makes sense on the full list.
      if (_filter != MarketFilter.all && _filter != MarketFilter.watchlist) {
        _filter = MarketFilter.all;
      }
    });
    context.read<CoinListBloc>().add(CoinListSortChanged(by));
  }

  void _clearSearch() {
    _search.clear();
    context.read<CoinListBloc>().add(const CoinListSearchChanged(''));
  }

  void _resetFilters() {
    setState(() {
      _filter = MarketFilter.all;
      _quote = 'USDT';
      _hideZeroVolume = true;
    });
    if (_search.text.isNotEmpty) _clearSearch();
  }

  Future<void> _openFilters() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filters',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 16),
                Text('Quote asset',
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final q in _quotes)
                      PillChip(
                        label: q == 'ALL' ? 'All pairs' : q,
                        selected: _quote == q,
                        onTap: () {
                          setState(() => _quote = q);
                          setSheet(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide zero-volume pairs'),
                  subtitle: const Text('Removes inactive / delisted markets'),
                  value: _hideZeroVolume,
                  onChanged: (v) {
                    setState(() => _hideZeroVolume = v);
                    setSheet(() {});
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _quote = 'USDT';
                            _hideZeroVolume = true;
                          });
                          setSheet(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── data ───────────────────────────────────────────────────────────────────

  /// Bloc handles search + sort; we layer quote / volume / quick filters on top.
  List<Coin> _filtered(CoinListState state, Iterable<String> watched) {
    Iterable<Coin> list = state.visibleCoins;
    if (_quote != 'ALL') list = list.where((c) => c.quoteSymbol == _quote);
    if (_hideZeroVolume) list = list.where((c) => c.quoteVolume24h > 0);
    var out = list.toList();

    switch (_filter) {
      case MarketFilter.all:
        break;
      case MarketFilter.trending:
        out.sort((a, b) => b.quoteVolume24h.compareTo(a.quoteVolume24h));
        out = out.take(50).toList();
      case MarketFilter.gainers:
        out = out.where((c) => c.priceChangePercent24h > 0).toList()
          ..sort((a, b) =>
              b.priceChangePercent24h.compareTo(a.priceChangePercent24h));
      case MarketFilter.losers:
        out = out.where((c) => c.priceChangePercent24h < 0).toList()
          ..sort((a, b) =>
              a.priceChangePercent24h.compareTo(b.priceChangePercent24h));
      case MarketFilter.watchlist:
        out = out.where((c) => watched.contains(c.symbol)).toList();
    }
    return _reversed ? out.reversed.toList() : out;
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: BlocBuilder<CoinListBloc, CoinListState>(
            builder: (context, state) {
              final ready = state.status == CoinListStatus.success;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    key: const ValueKey('header'),
                    child: _buildHeader(context),
                  ),
                  if (ready)
                    SliverToBoxAdapter(
                      key: const ValueKey('summary'),
                      child: _SummaryStrip(
                        stats: MarketStats.from(
                            liquidUsdMarkets(state.allCoins)),
                      ),
                    ),
                  SliverToBoxAdapter(
                    key: const ValueKey('search'),
                    child: _buildSearchRow(context),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedDelegate(
                      height: 84,
                      child: _buildStickyHeader(context),
                    ),
                  ),
                  ..._bodySlivers(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          const BrandMark(size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Markets',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
                Text('Live prices · Binance',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _search,
              builder: (context, value, child) => TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search coin (e.g. BTC)',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clearSearch,
                        ),
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (q) => context
                    .read<CoinListBloc>()
                    .add(CoinListSearchChanged(q)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<CoinSortBy>(
            tooltip: 'Sort',
            position: PopupMenuPosition.under,
            onSelected: _onSort,
            itemBuilder: (_) => [
              for (final e in _sortLabels.entries)
                CheckedPopupMenuItem<CoinSortBy>(
                  value: e.key,
                  checked: _sortBy == e.key,
                  child: Text(e.value),
                ),
            ],
            child: _ToolButton(
                icon: Icons.swap_vert_rounded, active: _sortBy != null),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openFilters,
            child: _ToolButton(icon: Icons.tune_rounded, active: _filtersActive),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget sortLabel(String text, CoinSortBy by) {
      final active = _sortBy == by;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onSort(by),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? cs.primary : cs.onSurfaceVariant,
                  )),
              if (active)
                Icon(
                  _reversed
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: cs.primary,
                ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              children: [
                for (final (filter, label, icon) in _chips) ...[
                  PillChip(
                    label: label,
                    icon: icon,
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text('#',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(width: 50),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: sortLabel('Coin', CoinSortBy.name),
                    ),
                  ),
                  sortLabel('Price', CoinSortBy.price),
                  Text('/',
                      style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                  sortLabel('24H', CoinSortBy.priceChange),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bodySlivers(BuildContext context, CoinListState state) {
    switch (state.status) {
      case CoinListStatus.initial:
      case CoinListStatus.loading:
        return const [SliverToBoxAdapter(child: CoinListShimmer())];
      case CoinListStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: StateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Couldn\'t load markets',
              message: state.errorMessage ?? 'Check your connection and retry.',
              actionLabel: 'Retry',
              onAction: () =>
                  context.read<CoinListBloc>().add(const CoinListStarted()),
            ),
          ),
        ];
      case CoinListStatus.success:
        return [
          BlocBuilder<WatchlistBloc, WatchlistState>(
            // Only the "Watchlist" quick-filter depends on watchlist changes.
            buildWhen: (p, c) =>
                _filter == MarketFilter.watchlist &&
                p.symbols.length != c.symbols.length,
            builder: (context, watch) {
              final coins = _filtered(state, watch.symbols);
              if (coins.isEmpty) return _emptySliver(context);
              return SliverFixedExtentList(
                itemExtent: CoinRow.height,
                delegate: SliverChildBuilderDelegate(
                  (context, i) => CoinRow(
                    key: ValueKey(coins[i].symbol),
                    coin: coins[i],
                    rank: i + 1,
                  ),
                  childCount: coins.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];
    }
  }

  Widget _emptySliver(BuildContext context) {
    final isWatch = _filter == MarketFilter.watchlist;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: StateMessage(
        icon: isWatch ? Icons.star_border_rounded : Icons.search_off_rounded,
        title: isWatch ? 'Nothing on your watchlist' : 'No coins match',
        message: isWatch
            ? 'Tap the star on any coin to track it here.'
            : 'Try a different search, or widen the filters.',
        actionLabel: isWatch ? null : 'Reset filters',
        onAction: isWatch ? null : _resetFilters,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PinnedDelegate extends SliverPersistentHeaderDelegate {
  _PinnedDelegate({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant _PinnedDelegate oldDelegate) => true;
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, this.active = false});
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: active
            ? cs.primary.withValues(alpha: 0.18)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: active ? cs.primary : cs.onSurfaceVariant),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.stats});
  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    final gainer = stats.topGainer;
    final loser = stats.topLoser;
    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _SummaryCard(
            title: 'Market Sentiment',
            value: stats.sentimentLabel,
            valueColor: stats.isBullish ? AppColors.gain : AppColors.loss,
            footer: RatioBar(ratio: stats.upRatio),
          ),
          _SummaryCard(
            title: '24H Volume',
            value: formatCompact(stats.totalVolume),
            footer: Text('${stats.total} USDT markets',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          if (gainer != null)
            _SummaryCard(
              title: 'Top Gainer',
              value: gainer.baseAsset,
              footer: ChangePill(
                  percent: gainer.priceChangePercent24h, compact: true),
              onTap: () => openCoin(context, gainer),
            ),
          if (loser != null)
            _SummaryCard(
              title: 'Top Loser',
              value: loser.baseAsset,
              footer:
                  ChangePill(percent: loser.priceChangePercent24h, compact: true),
              onTap: () => openCoin(context, loser),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.footer,
    this.valueColor,
    this.onTap,
  });

  final String title;
  final String value;
  final Widget footer;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 166,
        child: AppCard(
          padding: const EdgeInsets.all(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: valueColor)),
              const SizedBox(height: 8),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}