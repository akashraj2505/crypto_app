import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/watchlist/watchlist_bloc.dart';
import 'coin_list_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';

/// Root shell with a persistent bottom nav bar, CoinGecko-style:
/// Markets, Watchlist, Insights, Search, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Lets child screens jump tabs, e.g. `MainShell.maybeOf(context)?.switchTo(0)`.
  static MainShellState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;

  void switchTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  // Keeping the screen widgets here preserves their configuration, but only
  // the selected screen is mounted. This resets a tab's local UI state (such
  // as scroll position) when the user leaves it and returns later.
  static const _screens = [
    CoinListScreen(),
    WatchlistScreen(),
    InsightsScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BlocBuilder<WatchlistBloc, WatchlistState>(
        // Only the badge count depends on the watchlist.
        buildWhen: (p, c) => p.symbols.length != c.symbols.length,
        builder: (context, watch) {
          final count = watch.symbols.length;
          Widget starIcon(IconData icon) => Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: Icon(icon),
              );
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: switchTo,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.show_chart_rounded),
                selectedIcon: Icon(Icons.candlestick_chart_rounded),
                label: 'Markets',
              ),
              NavigationDestination(
                icon: starIcon(Icons.star_border_rounded),
                selectedIcon: starIcon(Icons.star_rounded),
                label: 'Watchlist',
              ),
              const NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Insights',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
