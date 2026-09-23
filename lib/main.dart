import 'package:crypto_app/screens/main_shell.dart';
import 'package:crypto_app/constants/app_theme.dart';
import 'package:crypto_app/constants/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'blocs/coin_list/coin_list_bloc.dart';
import 'blocs/watchlist/watchlist_bloc.dart';
import 'services/binance_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('watchlist');
  final settings = await Hive.openBox('settings');
  runApp(MyApp(themeController: ThemeController(settings)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.themeController});

  final ThemeController? themeController;

  @override
  Widget build(BuildContext context) {
    final apiService = BinanceApiService();
    final controller = themeController ?? ThemeController();

    return ThemeControllerScope(
      controller: controller,
      child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CoinListBloc(apiService: apiService)
            ..add(const CoinListStarted()),
        ),
        BlocProvider(
          create: (_) => WatchlistBloc()..add(const WatchlistStarted()),
        ),
      ],
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
          title: 'Coinora',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.mode,
          home: const MainShell(),
        ),
      ),
      ),
    );
  }
}
