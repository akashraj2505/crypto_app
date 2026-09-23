import 'package:flutter/material.dart';

import 'coin_list_screen.dart';
import 'watchlist_screen.dart';
import 'insights_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

/// Root shell with a persistent bottom nav bar, CoinGecko-style:
/// Markets, Watchlist, Insights, Search, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // IndexedStack keeps each tab's scroll position and bloc state alive
  // when switching tabs, instead of rebuilding from scratch every time.
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
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Markets',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
