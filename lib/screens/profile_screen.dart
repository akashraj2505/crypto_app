import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/watchlist/watchlist_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final watchedCount = context.watch<WatchlistBloc>().state.symbols.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  child: Icon(Icons.person_rounded, size: 36),
                ),
                const SizedBox(height: 12),
                Text('Guest', style: Theme.of(context).textTheme.titleMedium),
                Text('No account needed — data is stored on this device',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _StatCard(label: 'Coins Watched', value: '$watchedCount'),
          const SizedBox(height: 24),
          const _SectionLabel('Preferences'),
          _SettingsTile(
              icon: Icons.dark_mode_outlined, title: 'Theme', trailing: 'Dark'),
          _SettingsTile(
              icon: Icons.attach_money_rounded,
              title: 'Currency',
              trailing: 'USD'),
          _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Price Alerts',
              trailing: 'Off'),
          const SizedBox(height: 16),
          const _SectionLabel('About'),
          _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Data Source',
              trailing: 'Binance API'),
          _SettingsTile(
              icon: Icons.code_rounded, title: 'App Version', trailing: '1.0.0'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
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
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text,
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(
      {required this.icon, required this.title, required this.trailing});
  final IconData icon;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(trailing, style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}