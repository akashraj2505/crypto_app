import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import 'coin_details_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        builder: (context, watchlistState) {
          if (watchlistState.symbols.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_border_rounded,
                      size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No coins in your watchlist yet'),
                ],
              ),
            );
          }
          return BlocBuilder<CoinListBloc, CoinListState>(
            builder: (context, coinListState) {
              final watched = coinListState.allCoins
                  .where((c) => watchlistState.symbols.contains(c.symbol))
                  .toList();
              return ListView.builder(
                itemCount: watched.length,
                itemBuilder: (context, index) {
                  final coin = watched[index];
                  final isUp = coin.priceChangePercent24h >= 0;
                  return ListTile(
                    title: Text(coin.baseAsset),
                    subtitle: Text(coin.symbol),
                    trailing: Text(
                      '${isUp ? '+' : ''}${coin.priceChangePercent24h.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: isUp ? AppColors.gain : AppColors.loss),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => CoinDetailsScreen(coin: coin)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}