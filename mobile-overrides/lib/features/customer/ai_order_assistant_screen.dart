import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_components.dart';
import '../../core/widgets/darb_glass.dart';
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
      setState(() => _error = dt('اكتب تفاصيل طلبك بشكل أوضح (5 أحرف على الأقل)'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await Api.instance.post('/ai/order-assistant/drafts/text', {
        'cityId': widget.cityId,
        'text': text,
      }) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _draft = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = dt('حدث خطأ غير متوقع، حاول مجدداً'));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        MaterialPageRoute(
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

    final items = (draft['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    String? vendorId = draft['vendorId']?.toString();
    String vendorName = dt('متجر');
    final prefilledCart = <String, int>{};

    for (final item in items) {
      final productId = item['productId']?.toString();
      final candidates = (item['candidates'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      if (productId != null && candidates.isNotEmpty) {
        final match = candidates.firstWhere(
          (c) => c['productId'] == productId,
          orElse: () => candidates.first,
        );
        vendorId ??= match['vendorId']?.toString();
        if (match['vendorName'] != null) vendorName = match['vendorName'].toString();
        if (match['vendorId']?.toString() == vendorId) {
          prefilledCart[productId] = ((item['quantity'] as num?)?.toInt() ?? 1).clamp(1, 50);
        }
      }
    }

    if (vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dt('اختر المتجر من القائمة الرئيسية لإكمال المنتجات المقترحة'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
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
    return Scaffold(
      appBar: DarbGlassAppBar(
        title: dt('مساعد الطلبات الذكي'),
        subtitle: widget.cityName,
      ),
      body: DarbAmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            DarbFadeSlide(
              child: DarbGlassSurface(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: DarbColors.primaryOf(context).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(Icons.auto_awesome_rounded, color: DarbColors.primaryOf(context)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dt('صف طلبك أو الغرض المطلوب توصيله بالعربية وسنجهزه لك للمراجعة'),
                            style: TextStyle(
                              color: DarbColors.inkOf(context),
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: dt('اكتب طلبك هنا'),
                        hintText: dt('مثال: أريد عبوتين زيت وخبز إلى حي الشهباء، أو إرسال مفاتيح من المزة إلى المالكي'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(color: DarbColors.dangerOf(context), fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _analyze,
                      icon: _submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DarbColors.onPrimaryOf(context),
                              ),
                            )
                          : const Icon(Icons.bolt_rounded),
                      label: Text(_submitting ? dt('جارٍ التحليل...') : dt('تحليل الطلب')),
                    ),
                  ],
                ),
              ),
            ),
            if (draft != null) ...[
              const SizedBox(height: 16),
              DarbFadeSlide(
                child: DarbGlassSurface(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dt('مسودة الطلب المستخرجة'),
                              style: TextStyle(
                                color: DarbColors.inkOf(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          DarbStatusBadge(status: draft['status']?.toString() ?? 'NEEDS_REVIEW'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${dt('النوع')}: ${draft['intent'] == 'PEER_DELIVERY' ? dt('توصيل مستقل') : dt('الطلب من المتاجر')}',
                        style: TextStyle(color: DarbColors.primaryOf(context), fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      for (final item in (draft['items'] as List? ?? []).whereType<Map<String, dynamic>>())
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                item['productId'] != null ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                                size: 17,
                                color: item['productId'] != null
                                    ? DarbColors.primaryOf(context)
                                    : DarbColors.warningOf(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item['rawName']} × ${item['quantity'] ?? 1}',
                                  style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w700),
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
                            borderRadius: BorderRadius.circular(DarbRadius.sm),
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
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _proceedWithDraft(draft),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(dt('متابعة لمراجعة وإرسال الطلب')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
