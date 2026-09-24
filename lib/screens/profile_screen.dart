import 'package:crypto_app/constants/app_theme.dart';
import 'package:crypto_app/constants/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/coin_list/coin_list_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';
import '../widgets/coin_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final bloc = context.read<WatchlistBloc>();
    final symbols = bloc.state.symbols.toList();
    if (symbols.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Your watchlist is already empty')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear watchlist?'),
        content: Text(
            'This removes all ${symbols.length} coin${symbols.length == 1 ? '' : 's'} from your watchlist.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      for (final s in symbols) {
        bloc.add(WatchlistToggled(s));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final watchedCount = context.watch<WatchlistBloc>().state.symbols.length;
    final marketCount = context.watch<CoinListBloc>().state.allCoins.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Row(
              children: [
                BrandMark(size: 38),
                SizedBox(width: 12),
                Text('Profile',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
              ],
            ),
            const SizedBox(height: 20),
            // ── Guest card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.28),
                    cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                ),
                border:
                    Border.all(color: cs.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                    child: Icon(Icons.person_rounded,
                        size: 32, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hello, Guest 👋',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('No account needed — data is stored on this device',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.watchlistStar,
                      label: 'Coins Watched',
                      value: '$watchedCount'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                      icon: Icons.candlestick_chart_rounded,
                      iconColor: cs.primary,
                      label: 'Markets Loaded',
                      value: '$marketCount'),
                ),
              ],
            ),
            const _SectionLabel('Preferences'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Theme',
                    trailing: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                          visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(
                            value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {isDark ? ThemeMode.dark : ThemeMode.light},
                      onSelectionChanged: (s) =>
                          ThemeControllerScope.of(context).setMode(s.first),
                    ),
                  ),
                  const Divider(height: 1),
                  const _SettingsRow(
                    icon: Icons.attach_money_rounded,
                    title: 'Currency',
                    trailing: Text('USD'),
                  ),
                  const Divider(height: 1),
                  const _SettingsRow(
                    icon: Icons.notifications_outlined,
                    title: 'Price Alerts',
                    trailing: Text('Coming soon'),
                  ),
                ],
              ),
            ),
            const _SectionLabel('Data'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () => _confirmClear(context),
                child: const _SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.loss,
                  title: 'Clear watchlist',
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
            const _SectionLabel('About'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Data Source',
                    trailing: Text('Binance API'),
                  ),
                  const Divider(height: 1),
                  InkWell(
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Coinora',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Market data from the Binance public API.',
                    ),
                    child: const _SettingsRow(
                      icon: Icons.code_rounded,
                      title: 'App Version',
                      trailing: Text('1.0.0'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 12),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10, left: 4),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.iconColor,
  });
  final IconData icon;
  final String title;
  final Widget trailing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? cs.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 15)),
          ),
          DefaultTextStyle.merge(
            style: TextStyle(color: cs.onSurfaceVariant),
            child: trailing,
          ),
        ],
      ),
    );
  }
}