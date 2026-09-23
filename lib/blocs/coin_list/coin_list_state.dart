part of 'coin_list_bloc.dart';

enum CoinListStatus { initial, loading, success, failure }

class CoinListState extends Equatable {
  const CoinListState({
    this.status = CoinListStatus.initial,
    this.allCoins = const [],
    this.visibleCoins = const [],
    this.searchQuery = '',
    this.sortBy = CoinSortBy.volume,
    this.sortDescending = true,
    this.quoteAssetFilter,
    this.onlyGainers = false,
    this.errorMessage,
  });

  final CoinListStatus status;
  final List<Coin> allCoins;
  final List<Coin> visibleCoins; // after search/filter/sort applied
  final String searchQuery;
  final CoinSortBy sortBy;
  final bool sortDescending;
  final String? quoteAssetFilter;
  final bool onlyGainers;
  final String? errorMessage;

  bool get isEmpty =>
      status == CoinListStatus.success && visibleCoins.isEmpty;

  CoinListState copyWith({
    CoinListStatus? status,
    List<Coin>? allCoins,
    List<Coin>? visibleCoins,
    String? searchQuery,
    CoinSortBy? sortBy,
    bool? sortDescending,
    String? quoteAssetFilter,
    bool? onlyGainers,
    String? errorMessage,
  }) {
    return CoinListState(
      status: status ?? this.status,
      allCoins: allCoins ?? this.allCoins,
      visibleCoins: visibleCoins ?? this.visibleCoins,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      quoteAssetFilter: quoteAssetFilter ?? this.quoteAssetFilter,
      onlyGainers: onlyGainers ?? this.onlyGainers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allCoins,
        visibleCoins,
        searchQuery,
        sortBy,
        sortDescending,
        quoteAssetFilter,
        onlyGainers,
        errorMessage,
      ];
}
