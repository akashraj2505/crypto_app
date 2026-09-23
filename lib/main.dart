import 'package:crypto_app/screens/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'blocs/coin_list/coin_list_bloc.dart';
import 'blocs/watchlist/watchlist_bloc.dart';
import 'services/binance_api_service.dart';
import 'screens/coin_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('watchlist');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = BinanceApiService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CoinListBloc(apiService: apiService)
            ..add(const CoinListStarted()),
        ),
        BlocProvider(
          create: (_) => WatchlistBloc()..add(const WatchlistStarted()),
        ),
      ],
      child: MaterialApp(
        title: 'Crypto Research',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFFF0B90B), // Binance-ish gold accent
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0B0E11),
        ),
        home: const MainShell(),
      ),
    );
  }
}
