import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';

sealed class WatchlistEvent extends Equatable {
  const WatchlistEvent();
  @override
  List<Object?> get props => [];
}

class WatchlistStarted extends WatchlistEvent {
  const WatchlistStarted();
}

class WatchlistToggled extends WatchlistEvent {
  const WatchlistToggled(this.symbol);
  final String symbol;
  @override
  List<Object?> get props => [symbol];
}

class WatchlistState extends Equatable {
  const WatchlistState({this.symbols = const {}});
  final Set<String> symbols;

  bool contains(String symbol) => symbols.contains(symbol);

  @override
  List<Object?> get props => [symbols];
}

/// Persists the watchlist locally via Hive (no backend needed — confirmed
/// no auth/persistence requirement from the client side).
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc({Box<dynamic>? box})
      : _box = box ?? Hive.box('watchlist'),
        super(const WatchlistState()) {
    on<WatchlistStarted>(_onStarted);
    on<WatchlistToggled>(_onToggled);
  }

  final Box<dynamic> _box;
  static const _key = 'symbols';

  void _onStarted(WatchlistStarted event, Emitter<WatchlistState> emit) {
    final stored = (_box.get(_key) as List?)?.cast<String>() ?? <String>[];
    emit(WatchlistState(symbols: stored.toSet()));
  }

  void _onToggled(WatchlistToggled event, Emitter<WatchlistState> emit) {
    final updated = Set<String>.from(state.symbols);
    if (!updated.remove(event.symbol)) {
      updated.add(event.symbol);
    }
    _box.put(_key, updated.toList());
    emit(WatchlistState(symbols: updated));
  }
}
