import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';
import 'peer_delivery_screen.dart';
import 'vendor_catalog_screen.dart';

class AiOrderAssistantScreen extends StatefulWidget {
  const AiOrderAssistantScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    this.onOrderCompleted,
  });

  final String cityId;
  final String cityName;
  final VoidCallback? onOrderCompleted;

  @override
  State<AiOrderAssistantScreen> createState() => _AiOrderAssistantScreenState();
}

class _AiOrderAssistantScreenState extends State<AiOrderAssistantScreen> {
  final _textController = TextEditingController();
  bool _submitting = false;
  DarbActionState _analyzeState = DarbActionState.idle;
  int _errorTrigger = 0;
  String? _error;
  Map<String, dynamic>? _draft;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.length < 5) {
      DarbHaptics.warning();
      setState(() {
        _error = dt('اكتب تفاصيل طلبك بشكل أوضح (5 أحرف على الأقل)');
        _analyzeState = DarbActionState.error;
        _errorTrigger++;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _analyzeState = DarbActionState.loading;
      _error = null;
    });
    try {
      final result = await Api.instance.post('/ai/order-assistant/drafts/text', {
        'cityId': widget.cityId,
        'text': text,
      }) as Map<String, dynamic>;
      if (!mounted) return;
      DarbHaptics.success();
      setState(() {
        _draft = result;
        _analyzeState = DarbActionState.idle;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _analyzeState = DarbActionState.error;
          _errorTrigger++;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = dt('حدث خطأ غير متوقع، حاول مجدداً');
          _analyzeState = DarbActionState.error;
          _errorTrigger++;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          if (_analyzeState == DarbActionState.loading) {
            _analyzeState = DarbActionState.idle;
          }
        });
      }
    }
  }

  void _proceedWithDraft(Map<String, dynamic> draft) {
    final intent = draft['intent']?.toString() ?? 'UNCLEAR';
    if (intent == 'PEER_DELIVERY') {
      final notes = draft['extraction'] is Map
          ? (draft['extraction'] as Map)['deliveryDescription']?.toString()
          : draft['originalText']?.toString();
      Navigator.push(
        context,
        DarbPageRoute(
          builder: (_) => PeerDeliveryScreen(
            cityId: widget.cityId,
            cityName: widget.cityName,
            initialDescription: notes,
            onCreated: widget.onOrderCompleted,
          ),
        ),
      );
      return;
    }

    final items = (draft['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    String? vendorId = draft['vendorId']?.toString();
    String vendorName = dt('متجر');
    final prefilledCart = <String, int>{};

    for (final item in items) {
      final productId = item['productId']?.toString();
      final candidates = (item['candidates'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (productId != null && candidates.isNotEmpty) {
        final match = candidates.firstWhere(
          (c) => c['productId'] == productId,
          orElse: () => candidates.first,
        );
        vendorId ??= match['vendorId']?.toString();
        if (match['vendorName'] != null) {
          vendorName = match['vendorName'].toString();
        }
        if (match['vendorId']?.toString() == vendorId) {
          prefilledCart[productId] =
              ((item['quantity'] as num?)?.toInt() ?? 1).clamp(1, 50);
        }
      }
    }

    if (vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dt('اختر المتجر من القائمة الرئيسية لإكمال المنتجات المقترحة'),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      DarbPageRoute(
        builder: (_) => VendorCatalogScreen(
          vendor: {
            'id': vendorId,
            'translations': [
              {'name': vendorName}
            ],
          },
          cityId: widget.cityId,
          initialCart: prefilledCart,
          onOrderCompleted: widget.onOrderCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final teal = DarbColors.violetOf(context);
    final isDark = DarbColors.isDark(context);

    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('مساعد الطلبات الذكي'),
        subtitle: widget.cityName,
      ),
      body: DarbAmbientBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                DarbFadeSlide(
                  child: DarbCommandStage(
                    livePulse: true,
                    accentColor: DarbColors.darkViolet,
                    eyebrow: widget.cityName,
                    title: dt('مساعد الطلبات الذكي'),
                    subtitle: dt(
                      'صف طلبك أو الغرض المطلوب توصيله بالعربية وسنجهزه لك للمراجعة',
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DarbColors.darkViolet.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DarbColors.darkViolet.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: DarbColors.darkViolet,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DarbFadeSlide(
                  delay: DarbMotion.staggerDelay(1),
                  child: DarbGlassSurface(
                    padding: const EdgeInsets.all(18),
                    borderColor: teal.withValues(alpha: 0.34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final sample in [
                          dt('أريد عبوتين زيت وخبز إلى حي الشهباء'),
                          dt('إرسال مفاتيح من المزة إلى المالكي'),
                        ]) ...[
                          DarbPressScale(
                            borderRadius: DarbRadius.md,
                            onTap: _submitting
                                ? null
                                : () {
                                    DarbHaptics.selection();
                                    setState(() {
                                      _textController.text = sample;
                                      _error = null;
                                      _analyzeState = DarbActionState.idle;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: teal.withValues(alpha: isDark ? 0.14 : 0.08),
                                borderRadius: BorderRadius.circular(DarbRadius.md),
                                border: Border.all(
                                  color: teal.withValues(alpha: 0.26),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 16,
                                    color: teal,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sample,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: DarbColors.inkOf(context),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 4),
                        TextField(
                          controller: _textController,
                          maxLines: 4,
                          onChanged: (_) {
                            if (_analyzeState == DarbActionState.error) {
                              setState(() => _analyzeState = DarbActionState.idle);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: dt('اكتب طلبك هنا'),
                            hintText: dt(
                              'مثال: أريد عبوتين زيت وخبز إلى حي الشهباء، أو إرسال مفاتيح من المزة إلى المالكي',
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: DarbColors.dangerOf(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (_submitting) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              DarbTypingDots(color: teal),
                              const SizedBox(width: 10),
                              Text(
                                dt('جارٍ التحليل...'),
                                style: TextStyle(
                                  color: DarbColors.mutedOf(context),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        DarbActionButton(
                          label: dt('تحليل الطلب'),
                          loadingLabel: dt('جارٍ التحليل...'),
                          state: _analyzeState,
                          errorTrigger: _errorTrigger,
                          icon: Icons.bolt_rounded,
                          onPressed: _submitting ? null : _analyze,
                        ),
                      ],
                    ),
                  ),
                ),
                if (draft != null) ...[
                  const SizedBox(height: 16),
                  DarbFadeSlide(
                    child: DarbTicketPass(
                      leadingIcon: Icons.auto_awesome_rounded,
                      accentColor: teal,
                      title: dt('مسودة الطلب المستخرجة'),
                      subtitle: draft['intent'] == 'PEER_DELIVERY'
                          ? dt('توصيل مستقل')
                          : dt('الطلب من المتاجر'),
                      status: draft['status']?.toString() ?? 'NEEDS_REVIEW',
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${dt('النوع')}: ${draft['intent'] == 'PEER_DELIVERY' ? dt('توصيل مستقل') : dt('الطلب من المتاجر')}',
                            style: TextStyle(
                              color: teal,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final item in (draft['items'] as List? ?? [])
                              .whereType<Map<String, dynamic>>())
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    item['productId'] != null
                                        ? Icons.check_circle_rounded
                                        : Icons.help_outline_rounded,
                                    size: 17,
                                    color: item['productId'] != null
                                        ? teal
                                        : DarbColors.warningOf(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${item['rawName']} × ${item['quantity'] ?? 1}',
                                      style: TextStyle(
                                        color: DarbColors.inkOf(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if ((draft['warnings'] as List? ?? []).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: DarbColors.warningSoftOf(context),
                                borderRadius:
                                    BorderRadius.circular(DarbRadius.sm),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final w in (draft['warnings'] as List))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $w',
                                        style: TextStyle(
                                          color: DarbColors.warningOf(context),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      footer: DarbActionButton(
                        label: dt('متابعة لمراجعة وإرسال الطلب'),
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => _proceedWithDraft(draft),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
