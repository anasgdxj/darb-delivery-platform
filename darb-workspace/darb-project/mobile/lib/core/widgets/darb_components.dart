import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/darb_design_system.dart';
import 'darb_glass.dart';

class DarbBrandMark extends StatelessWidget {
  const DarbBrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DarbColors.forest, DarbColors.forestSoft],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: DarbColors.forest.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.route_rounded,
        color: DarbColors.mint,
        size: size * 0.56,
      ),
    );
  }
}

class DarbSectionHeader extends StatelessWidget {
  const DarbSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ink = DarbColors.inkOf(context);
    final muted = DarbColors.mutedOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DarbMetricCard extends StatelessWidget {
  const DarbMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? DarbColors.primaryOf(context);
    return DarbGlassSurface(
      padding: const EdgeInsets.all(14),
      borderRadius: DarbRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.inkOf(context),
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: DarbColors.mutedOf(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DarbStatusBadge extends StatelessWidget {
  const DarbStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isDark = DarbColors.isDark(context);

    final (Color fg, Color bg, String label) = switch (normalized) {
      'DELIVERED' || 'APPROVED' || 'OPEN' || 'ONLINE' || 'ACCEPTED' => (
          isDark ? DarbColors.mint : DarbColors.success,
          isDark
              ? DarbColors.forestSoft.withValues(alpha: 0.9)
              : DarbColors.mintTint,
          _translateStatus(normalized),
        ),
      'CANCELLED' || 'REJECTED' || 'SUSPENDED' || 'CLOSED' || 'OFFLINE' => (
          DarbColors.dangerOf(context),
          DarbColors.dangerOf(context).withValues(alpha: isDark ? 0.20 : 0.11),
          _translateStatus(normalized),
        ),
      'PICKED_UP' || 'ASSIGNED' || 'READY' || 'PREPARING' => (
          DarbColors.infoOf(context),
          DarbColors.infoOf(context).withValues(alpha: isDark ? 0.22 : 0.12),
          _translateStatus(normalized),
        ),
      'WITHDRAWN' => (
          DarbColors.mutedOf(context),
          DarbColors.softSurfaceOf(context),
          _translateStatus(normalized),
        ),
      _ => (
          DarbColors.warningOf(context),
          DarbColors.warningOf(context).withValues(alpha: isDark ? 0.22 : 0.13),
          _translateStatus(normalized),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DarbRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800),
      ),
    );
  }

  static String _translateStatus(String status) => switch (status) {
        'PENDING' => dt('قيد الانتظار'),
        'ACCEPTED' => dt('مقبول'),
        'PREPARING' => dt('قيد التحضير'),
        'READY' => dt('جاهز للاستلام'),
        'ASSIGNED' => dt('تم تعيين مندوب'),
        'PICKED_UP' => dt('في الطريق إليك'),
        'DELIVERED' => dt('تم التسليم'),
        'CANCELLED' => dt('ملغى'),
        'APPROVED' => dt('معتمد'),
        'REJECTED' => dt('مرفوض'),
        'SUSPENDED' => dt('موقوف'),
        'WITHDRAWN' => dt('مسحوب'),
        'OPEN' => dt('مفتوح'),
        'CLOSED' => dt('مغلق'),
        'ONLINE' => dt('متصل'),
        'OFFLINE' => dt('غير متصل'),
        _ => status,
      };
}

class DarbStateView extends StatelessWidget {
  const DarbStateView.loading({super.key, this.message})
      : _kind = _StateKind.loading,
        icon = Icons.hourglass_top_rounded,
        onRetry = null;

  const DarbStateView.empty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
  }) : _kind = _StateKind.empty;

  const DarbStateView.error({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  }) : _kind = _StateKind.error;

  final _StateKind _kind;
  final String? message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (_kind == _StateKind.loading) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, _) => const _DarbSkeletonCard(),
      );
    }

    final isError = _kind == _StateKind.error;
    final tint =
        isError ? DarbColors.dangerOf(context) : DarbColors.primaryOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DarbGlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 28, color: tint),
              ),
              const SizedBox(height: 14),
              Text(
                message ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DarbColors.inkOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(dt('إعادة المحاولة')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _StateKind { loading, empty, error }

class _DarbSkeletonCard extends StatelessWidget {
  const _DarbSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final fill = DarbColors.softSurfaceOf(context);
    return DarbGlassSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 14,
            decoration:
                BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 11,
            decoration:
                BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(height: 8),
          Container(
            width: 210,
            height: 11,
            decoration:
                BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }
}

class DarbRadioOptionTile extends StatelessWidget {
  const DarbRadioOptionTile({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = DarbColors.primaryOf(context);
    final onPrimary = DarbColors.onPrimaryOf(context);
    final isDark = DarbColors.isDark(context);

    return InkWell(
      borderRadius: BorderRadius.circular(DarbRadius.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
        curve: DarbMotion.enter,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DarbRadius.md),
          color: selected
              ? (isDark
                  ? DarbColors.forestSoft.withValues(alpha: 0.72)
                  : DarbColors.mintTint.withValues(alpha: 0.78))
              : DarbColors.softSurfaceOf(context).withValues(alpha: 0.60),
          border: Border.all(
            color: selected ? primary : DarbColors.borderOf(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: DarbMotion.effectiveDuration(context, DarbMotion.fast),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? primary : Colors.transparent,
                border: Border.all(
                  color: selected ? primary : DarbColors.mutedOf(context),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 14, color: onPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: DarbColors.inkOf(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: DarbColors.mutedOf(context),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
