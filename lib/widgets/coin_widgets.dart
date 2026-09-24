import 'package:crypto_app/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../blocs/watchlist/watchlist_bloc.dart';
import '../models/coin.dart';
import '../screens/coin_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Formatting helpers
// ─────────────────────────────────────────────────────────────────────────────

const _usdQuotes = {'USDT', 'USDC', 'FDUSD', 'BUSD', 'TUSD', 'USD1'};

/// Price with sensible precision: 2 decimals for big prices, up to 8 for
/// micro-cap coins, with thousands separators.
String formatPrice(double v) {
  if (v.isNaN || v.isInfinite) return '--';
  final abs = v.abs();
  final decimals = (abs >= 100 || abs == 0)
      ? 2
      : abs >= 1
          ? 4
          : abs >= 0.01
              ? 5
              : abs >= 0.0001
                  ? 6
                  : 8;
  return _group(v.toStringAsFixed(decimals));
}

String _group(String s) {
  final neg = s.startsWith('-');
  final body = neg ? s.substring(1) : s;
  final parts = body.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final frac = parts.length > 1 ? '.${parts[1]}' : '';
  return '${neg ? '-' : ''}$buf$frac';
}

/// 1.23K / 4.56M / 7.89B / 1.02T
String formatCompact(double v, {String prefix = '\$'}) {
  final abs = v.abs();
  final String body;
  if (abs >= 1e12) {
    body = '${(v / 1e12).toStringAsFixed(2)}T';
  } else if (abs >= 1e9) {
    body = '${(v / 1e9).toStringAsFixed(2)}B';
  } else if (abs >= 1e6) {
    body = '${(v / 1e6).toStringAsFixed(2)}M';
  } else if (abs >= 1e3) {
    body = '${(v / 1e3).toStringAsFixed(2)}K';
  } else {
    body = v.toStringAsFixed(2);
  }
  return '$prefix$body';
}

String formatPercent(double p) =>
    '${p >= 0 ? '+' : ''}${p.toStringAsFixed(2)}%';

extension CoinDisplay on Coin {
  /// "BTCUSDT" with base "BTC" -> "USDT"
  String get quoteSymbol =>
      symbol.length > baseAsset.length && symbol.startsWith(baseAsset)
          ? symbol.substring(baseAsset.length)
          : '';

  bool get isUsdMarket => _usdQuotes.contains(quoteSymbol);

  /// `$` only for USD-like quote assets. Other quotes (BTC, IDR...) get no
  /// misleading dollar sign.
  String get pricePrefix => isUsdMarket ? '\$' : '';

  String get priceLabel => '$pricePrefix${formatPrice(lastPrice)}';

  String get volumeLabel =>
      'Vol ${formatCompact(quoteVolume24h, prefix: pricePrefix)}${isUsdMarket ? '' : ' $quoteSymbol'}';

  /// (high - low) / low over 24h — a simple volatility gauge.
  double get rangePercent24h =>
      lowPrice24h <= 0 ? 0 : (highPrice24h - lowPrice24h) / lowPrice24h * 100;
}

/// Only USDT pairs that actually trade — hides delisted / dead pairs that
/// otherwise pollute rankings (e.g. 3,000+ "losers" with 0 volume).
List<Coin> liquidUsdMarkets(List<Coin> all) => all
    .where((c) => c.quoteSymbol == 'USDT' && c.quoteVolume24h > 0)
    .toList();

void openCoin(BuildContext context, Coin coin) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CoinDetailsScreen(coin: coin)),
  );
}

Color avatarColorFor(String symbol) {
  const palette = [
    Color(0xFFF0B90B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF14B8A6),
  ];
  final hash = symbol.codeUnits.fold<int>(0, (a, b) => a + b);
  return palette[hash % palette.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// Market stats (shared by Markets + Insights)
// ─────────────────────────────────────────────────────────────────────────────

class MarketStats {
  MarketStats._({
    required this.total,
    required this.up,
    required this.down,
    required this.totalVolume,
    required this.avgChange,
    this.topGainer,
    this.topLoser,
    this.topVolume,
  });

  final int total;
  final int up;
  final int down;
  final double totalVolume;
  final double avgChange;
  final Coin? topGainer;
  final Coin? topLoser;
  final Coin? topVolume;

  factory MarketStats.from(List<Coin> coins) {
    var up = 0, down = 0;
    var volume = 0.0, sum = 0.0;
    Coin? gainer, loser, vol;
    for (final c in coins) {
      final ch = c.priceChangePercent24h;
      if (ch > 0) up++;
      if (ch < 0) down++;
      volume += c.quoteVolume24h;
      sum += ch;
      if (gainer == null || ch > gainer.priceChangePercent24h) gainer = c;
      if (loser == null || ch < loser.priceChangePercent24h) loser = c;
      if (vol == null || c.quoteVolume24h > vol.quoteVolume24h) vol = c;
    }
    return MarketStats._(
      total: coins.length,
      up: up,
      down: down,
      totalVolume: volume,
      avgChange: coins.isEmpty ? 0 : sum / coins.length,
      topGainer: gainer,
      topLoser: loser,
      topVolume: vol,
    );
  }

  double get upRatio => total == 0 ? 0.5 : up / total;
  bool get isBullish => upRatio >= 0.5;

  String get sentimentLabel {
    final r = upRatio;
    if (r >= 0.65) return 'Bullish';
    if (r >= 0.5) return 'Leaning Bullish';
    if (r >= 0.35) return 'Leaning Bearish';
    return 'Bearish';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small building blocks
// ─────────────────────────────────────────────────────────────────────────────

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, Color.lerp(cs.primary, AppColors.gain, 0.6)!],
        ),
      ),
      child: Icon(Icons.show_chart_rounded,
          size: size * 0.62, color: cs.onPrimary),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.primary : cs.onSurfaceVariant;
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.16)
          : cs.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? cs.primary.withValues(alpha: 0.7) : Colors.transparent,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.icon, this.color, this.trailing});
  final String title;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 17)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 34, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 17)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class RatioBar extends StatelessWidget {
  const RatioBar({super.key, required this.ratio, this.height = 6});
  final double ratio;
  final double height;

  @override
  Widget build(BuildContext context) {
    final up = (ratio * 100).round().clamp(1, 99).toInt();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(flex: up, child: const ColoredBox(color: AppColors.gain)),
            const SizedBox(width: 2),
            Expanded(
                flex: 100 - up, child: const ColoredBox(color: AppColors.loss)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coin widgets
// ─────────────────────────────────────────────────────────────────────────────

class CoinAvatar extends StatelessWidget {
  const CoinAvatar({super.key, required this.symbol, this.size = 40});
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = avatarColorFor(symbol);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, Colors.black, 0.28)!],
        ),
      ),
      child: Text(
        symbol.isEmpty ? '?' : symbol[0],
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Rounded green/red chip with an arrow — CoinGecko style.
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.percent, this.compact = false});
  final double percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isUp = percent >= 0;
    final color = isUp ? AppColors.gain : AppColors.loss;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8, vertical: compact ? 1 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: compact ? 18 : 22,
            color: color,
          ),
          Text(
            '${percent.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: compact ? 2 : 4),
        ],
      ),
    );
  }
}

class WatchStar extends StatelessWidget {
  const WatchStar({super.key, required this.symbol, this.size = 22});
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      buildWhen: (prev, curr) =>
          prev.contains(symbol) != curr.contains(symbol),
      builder: (context, state) {
        final watched = state.contains(symbol);
        return IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: watched ? 'Remove from watchlist' : 'Add to watchlist',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<WatchlistBloc>().add(WatchlistToggled(symbol));
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              watched ? Icons.star_rounded : Icons.star_border_rounded,
              key: ValueKey(watched),
              size: size,
              color: watched
                  ? AppColors.watchlistStar
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

/// One market row: rank · avatar · name / volume · price / change · star.
/// Fixed 68px height so it works inside `SliverFixedExtentList`.
class CoinRow extends StatelessWidget {
  const CoinRow({
    super.key,
    required this.coin,
    this.rank,
    this.showStar = true,
    this.subtitle,
    this.onTap,
  });

  final Coin coin;
  final int? rank;
  final bool showStar;
  final String? subtitle;
  final VoidCallback? onTap;

  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(color: cs.onSurfaceVariant, fontSize: 12);
    return SizedBox(
      height: height,
      child: InkWell(
        onTap: onTap ?? () => openCoin(context, coin),
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: showStar ? 10 : 16),
          child: Row(
            children: [
              if (rank != null) SizedBox(width: 26, child: Text('$rank', style: muted)),
              CoinAvatar(symbol: coin.baseAsset, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: coin.baseAsset,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (coin.quoteSymbol.isNotEmpty)
                          TextSpan(text: ' /${coin.quoteSymbol}', style: muted),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle ?? coin.volumeLabel,
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(coin.priceLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  ChangePill(
                      percent: coin.priceChangePercent24h, compact: true),
                ],
              ),
              if (showStar) WatchStar(symbol: coin.symbol),
            ],
          ),
        ),
      ),
    );
  }
}

class CoinListShimmer extends StatelessWidget {
  const CoinListShimmer({super.key, this.count = 9});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Keep the shimmer lighter than its base in both themes. In light mode
    // the old divider color was darker than the base, making the sweep look
    // like a shadow instead of a loading highlight.
    final baseColor = isDark ? AppColors.surfaceElevated : cs.surfaceContainerHighest;
    final highlightColor = isDark ? AppColors.border : cs.surface;
    final placeholderColor = isDark ? AppColors.textPrimary : cs.onSurface;

    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(
          count,
          (_) => SizedBox(
            height: CoinRow.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: placeholderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [bar(70, 12), const SizedBox(height: 8), bar(48, 10)],
                  ),
                  const Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [bar(80, 12), const SizedBox(height: 8), bar(52, 14)],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
