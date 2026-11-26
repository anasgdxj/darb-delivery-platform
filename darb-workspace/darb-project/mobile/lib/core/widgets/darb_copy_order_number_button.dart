import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

class DarbCopyOrderNumberButton extends StatelessWidget {
  const DarbCopyOrderNumberButton({
    super.key,
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    final orderNumber = value.trim();
    if (orderNumber.isEmpty) return const SizedBox.shrink();

    return IconButton(
      tooltip: dt('نسخ رقم الطلب'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      icon: const Icon(Icons.copy_rounded, size: 17),
      onPressed: () async {
        try {
          await Clipboard.setData(ClipboardData(text: orderNumber));
          if (!context.mounted) return;
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(dt('تم نسخ رقم الطلب'))),
            );
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(dt('تعذر نسخ رقم الطلب'))),
          );
        }
      },
    );
  }
}
