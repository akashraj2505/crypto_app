import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../models/coin.dart';
import 'coin_details_screen.dart';
import 'coin_list_screen.dart' show ChangePill, avatarColorFor;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Search coins...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v.trim().toUpperCase()),
        ),
      ),
      body: BlocBuilder<CoinListBloc, CoinListState>(
        builder: (context, state) {
          if (state.status != CoinListStatus.success) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_query.isEmpty) {
            // No query yet: show a trending strip (proxy: top by volume)
            // so the screen isn't a dead end before typing anything.
            final trending = [...state.allCoins]
              ..sort((a, b) => b.quoteVolume24h.compareTo(a.quoteVolume24h));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Trending',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                ...trending.take(15).map((c) => _SearchResultTile(coin: c)),
              ],
            );
          }

          final results = state.allCoins
              .where((c) => c.baseAsset.contains(_query))
              .toList();

          if (results.isEmpty) {
            return const Center(child: Text('No coins found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: results.length,
            itemBuilder: (context, i) => _SearchResultTile(coin: results[i]),
          );
        },
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('\$${coin.lastPrice.toStringAsFixed(4)}'),
          const SizedBox(height: 4),
          ChangePill(percent: coin.priceChangePercent24h, compact: true),
        ],
      ),
    );
  }
}