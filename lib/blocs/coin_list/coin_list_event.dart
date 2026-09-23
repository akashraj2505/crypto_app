part of 'coin_list_bloc.dart';

sealed class CoinListEvent extends Equatable {
  const CoinListEvent();

  @override
  List<Object?> get props => [];
}

class CoinListStarted extends CoinListEvent {
  const CoinListStarted();
}

class CoinListRefreshed extends CoinListEvent {
  const CoinListRefreshed();
}

class CoinListSearchChanged extends CoinListEvent {
  const CoinListSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

enum CoinSortBy { priceChange, volume, price, name }

class CoinListSortChanged extends CoinListEvent {
  const CoinListSortChanged(this.sortBy, {this.descending = true});
  final CoinSortBy sortBy;
  final bool descending;

  @override
  List<Object?> get props => [sortBy, descending];
}

/// e.g. filter to only USDT pairs, or only gainers
class CoinListFilterChanged extends CoinListEvent {
  const CoinListFilterChanged({this.quoteAsset, this.onlyGainers = false});
  final String? quoteAsset;
  final bool onlyGainers;

  @override
  List<Object?> get props => [quoteAsset, onlyGainers];
}
