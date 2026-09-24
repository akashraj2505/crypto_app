import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../models/coin.dart';
import '../widgets/coin_widgets.dart';

enum _Highlight { trending, gainers, losers }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _highlightMeta = {
    _Highlight.trending: ('Trending', Icons.local_fire_department_rounded),
    _Highlight.gainers: ('Top Gainers', Icons.rocket_launch_rounded),
    _Highlight.losers: ('Top Losers', Icons.trending_down_rounded),
  };

  final _controller = TextEditingController();
  String _query = '';
  bool _usdtOnly = true;
  bool _activeOnly = true;
  _Highlight _highlight = _Highlight.trending;
  final List<Coin> _recent = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(Coin coin) {
    setState(() {
      _recent.removeWhere((c) => c.symbol == coin.symbol);
      _recent.insert(0, coin);
      if (_recent.length > 8) _recent.removeLast();
    });
    openCoin(context, coin);
  }

  List<Coin> _pool(List<Coin> all) => all
      .where((c) =>
          (!_usdtOnly || c.quoteSymbol == 'USDT') &&
          (!_activeOnly || c.quoteVolume24h > 0))
      .toList();

  int _matchRank(Coin c) {
    if (c.baseAsset == _query) return 0;
    if (c.baseAsset.startsWith(_query)) return 1;
    if (c.symbol.startsWith(_query)) return 2;
    return 3;
  }

  List<Coin> _results(List<Coin> pool) {
    final list = pool.where((c) => c.symbol.contains(_query)).toList()
      ..sort((a, b) {
        final r = _matchRank(a).compareTo(_matchRank(b));
        return r != 0 ? r : b.quoteVolume24h.compareTo(a.quoteVolume24h);
      });
    return list.take(100).toList();
  }

  List<Coin> _highlights(List<Coin> pool) {
    final list = switch (_highlight) {
      _Highlight.trending => [...pool]
        ..sort((a, b) => b.quoteVolume24h.compareTo(a.quoteVolume24h)),
      _Highlight.gainers => pool.where((c) => c.priceChangePercent24h > 0).toList()
        ..sort((a, b) =>
            b.priceChangePercent24h.compareTo(a.priceChangePercent24h)),
      _Highlight.losers => pool.where((c) => c.priceChangePercent24h < 0).toList()
        ..sort((a, b) =>
            a.priceChangePercent24h.compareTo(b.priceChangePercent24h)),
    };
    return list.take(15).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const BrandMark(size: 38),
                  const SizedBox(width: 12),
                  const Text('Search',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search coins (e.g. BTC, ETH)',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toUpperCase()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  PillChip(
                    label: 'USDT only',
                    icon: Icons.attach_money_rounded,
                    selected: _usdtOnly,
                    onTap: () => setState(() => _usdtOnly = !_usdtOnly),
                  ),
                  const SizedBox(width: 8),
                  PillChip(
                    label: 'Active only',
                    icon: Icons.bolt_rounded,
                    selected: _activeOnly,
                    onTap: () => setState(() => _activeOnly = !_activeOnly),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<CoinListBloc, CoinListState>(
                builder: (context, state) {
                  if (state.status == CoinListStatus.failure) {
                    return StateMessage(
                      icon: Icons.wifi_off_rounded,
                      title: 'Couldn\'t load coins',
                      message: state.errorMessage,
                      actionLabel: 'Retry',
                      onAction: () => context
                          .read<CoinListBloc>()
                          .add(const CoinListStarted()),
                    );
                  }
                  if (state.status != CoinListStatus.success) {
                    return const SingleChildScrollView(
                        child: CoinListShimmer());
                  }

                  final pool = _pool(state.allCoins);

                  if (_query.isEmpty) {
                    final trending = _highlights(pool);
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (_recent.isNotEmpty) ...[
                          SectionTitle(
                            'Recent',
                            icon: Icons.history_rounded,
                            color: cs.onSurfaceVariant,
                            trailing: TextButton(
                              onPressed: () => setState(_recent.clear),
                              child: const Text('Clear'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final c in _recent)
                                  ActionChip(
                                    avatar: CoinAvatar(
                                        symbol: c.baseAsset, size: 22),
                                    label: Text(c.baseAsset),
                                    onPressed: () => _open(c),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        SectionTitle('Coin Highlights',
                            icon: _highlightMeta[_highlight]!.$2,
                            color: cs.primary),
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
                                  onTap: () =>
                                      setState(() => _highlight = e.key),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < trending.length; i++)
                          CoinRow(
                            key: ValueKey('${_highlight.name}-${trending[i].symbol}'),
                            coin: trending[i],
                            rank: i + 1,
                            onTap: () => _open(trending[i]),
                          ),
                      ],
                    );
                  }

                  final results = _results(pool);
                  if (results.isEmpty) {
                    return StateMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No coins found',
                      message: (_usdtOnly || _activeOnly)
                          ? 'Nothing matches "$_query". Try turning off a filter above.'
                          : 'Nothing matches "$_query".',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemExtent: CoinRow.height,
                    itemCount: results.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Text(
                            '${results.length} result${results.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13),
                          ),
                        );
                      }
                      final coin = results[i - 1];
                      return CoinRow(
                        key: ValueKey(coin.symbol),
                        coin: coin,
                        onTap: () => _open(coin),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}