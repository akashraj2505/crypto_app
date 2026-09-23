import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../models/coin.dart';
import '../../services/binance_api_service.dart';

part 'coin_list_event.dart';
part 'coin_list_state.dart';

/// Debounce transformer so rapid search keystrokes don't each trigger a
/// full re-filter/re-sort pass — keeps typing in the search bar smooth.
EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

class CoinListBloc extends Bloc<CoinListEvent, CoinListState> {
  CoinListBloc({required BinanceApiService apiService})
      : _apiService = apiService,
        super(const CoinListState()) {
    on<CoinListStarted>(_onStarted);
    on<CoinListRefreshed>(_onRefreshed);
    on<CoinListSearchChanged>(
      _onSearchChanged,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
    on<CoinListSortChanged>(_onSortChanged);
    on<CoinListFilterChanged>(_onFilterChanged);
  }

  final BinanceApiService _apiService;

  Future<void> _onStarted(
      CoinListStarted event, Emitter<CoinListState> emit) async {
    emit(state.copyWith(status: CoinListStatus.loading));
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefreshed(
      CoinListRefreshed event, Emitter<CoinListState> emit) async {
    // Keep showing current list while refreshing (pull-to-refresh feel)
    // instead of flashing back to a loading skeleton.
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<CoinListState> emit) async {
    try {
      final coins = await _apiService.fetchTicker24hr();
      emit(state.copyWith(
        status: CoinListStatus.success,
        allCoins: coins,
        visibleCoins: _applyRules(coins, state),
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CoinListStatus.failure,
        errorMessage: _friendlyError(e),
      ));
    }
  }

  void _onSearchChanged(
      CoinListSearchChanged event, Emitter<CoinListState> emit) {
    final newState = state.copyWith(searchQuery: event.query);
    emit(newState.copyWith(
        visibleCoins: _applyRules(state.allCoins, newState)));
  }

  void _onSortChanged(
      CoinListSortChanged event, Emitter<CoinListState> emit) {
    final newState = state.copyWith(
      sortBy: event.sortBy,
      sortDescending: event.descending,
    );
    emit(newState.copyWith(
        visibleCoins: _applyRules(state.allCoins, newState)));
  }

  void _onFilterChanged(
      CoinListFilterChanged event, Emitter<CoinListState> emit) {
    final newState = state.copyWith(
      quoteAssetFilter: event.quoteAsset,
      onlyGainers: event.onlyGainers,
    );
    emit(newState.copyWith(
        visibleCoins: _applyRules(state.allCoins, newState)));
  }

  /// Single source of truth for turning the raw coin list into what's
  /// actually shown, given the current search/filter/sort state.
  List<Coin> _applyRules(List<Coin> coins, CoinListState s) {
    var result = coins.where((c) {
      final matchesSearch = s.searchQuery.isEmpty ||
          c.baseAsset.toLowerCase().contains(s.searchQuery.toLowerCase());
      final matchesQuote =
          s.quoteAssetFilter == null || c.symbol.endsWith(s.quoteAssetFilter!);
      final matchesGainers = !s.onlyGainers || c.priceChangePercent24h > 0;
      return matchesSearch && matchesQuote && matchesGainers;
    }).toList();

    int compare(Coin a, Coin b) {
      switch (s.sortBy) {
        case CoinSortBy.priceChange:
          return a.priceChangePercent24h.compareTo(b.priceChangePercent24h);
        case CoinSortBy.volume:
          return a.quoteVolume24h.compareTo(b.quoteVolume24h);
        case CoinSortBy.price:
          return a.lastPrice.compareTo(b.lastPrice);
        case CoinSortBy.name:
          return a.baseAsset.compareTo(b.baseAsset);
      }
    }

    result.sort(s.sortDescending ? (a, b) => compare(b, a) : compare);
    return result;
  }

  String _friendlyError(Object e) {
    // Keep this simple; expand with Dio-specific error type checks if needed.
    return 'Couldn\'t load market data. Pull down to try again.';
  }
}
