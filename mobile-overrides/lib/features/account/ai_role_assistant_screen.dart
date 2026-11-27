import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_glass.dart';
import '../../core/widgets/darb_motion_components.dart';
import '../../core/widgets/darb_spatial_primitives.dart';

class AiRoleAssistantScreen extends StatefulWidget {
  const AiRoleAssistantScreen({super.key});

  @override
  State<AiRoleAssistantScreen> createState() => _AiRoleAssistantScreenState();
}

class _AiRoleAssistantScreenState extends State<AiRoleAssistantScreen> {
  final _inputController = TextEditingController();
  final List<_ChatTurn> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.length < 2 || _sending) return;
    _inputController.clear();
    setState(() {
      _messages.add(_ChatTurn(isUser: true, text: text));
      _sending = true;
    });
    try {
      final res = await Api.instance.post('/ai/assistant/ask', {'message': text})
          as Map<String, dynamic>;
      final reply = res['answer']?.toString() ?? res['reply']?.toString() ?? '';
      if (mounted) {
        DarbHaptics.selection();
        setState(() => _messages.add(_ChatTurn(isUser: false, text: reply)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _messages.add(
            _ChatTurn(isUser: false, text: e.message, isError: true),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _messages.add(
            _ChatTurn(
              isUser: false,
              text: dt('حدث خطأ غير متوقع، حاول مجدداً'),
              isError: true,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickPrompts = [
      dt('ما حالة طلباتي اليوم؟'),
      dt('لخّص مهامي الحالية'),
      dt('كيف أتابع التوصيل المباشر؟'),
    ];
    final totalItems = _messages.length + (_sending ? 1 : 0);
    final teal = DarbColors.violetOf(context);
    final isDark = DarbColors.isDark(context);

    return Scaffold(
      appBar: DarbGlassAppBar(title: dt('مساعد دازريفو الشخصي')),
      body: DarbAmbientBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          children: [
                            DarbFadeSlide(
                              child: DarbCommandStage(
                                livePulse: true,
                                accentColor: DarbColors.darkViolet,
                                eyebrow: 'DAZREVO AI',
                                title: dt('مساعد دازريفو الشخصي'),
                                subtitle: dt(
                                  'اسأل مساعد دازريفو عن طلباتك أو مهامك الحالية وفق صلاحية حسابك',
                                ),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: DarbColors.darkViolet
                                        .withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: DarbColors.darkViolet
                                          .withValues(alpha: 0.45),
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
                            for (var i = 0; i < quickPrompts.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              DarbFadeSlide(
                                delay: DarbMotion.staggerDelay(i + 1),
                                child: DarbPressScale(
                                  borderRadius: DarbRadius.md,
                                  onTap: () => _send(quickPrompts[i]),
                                  child: DarbGlassSurface(
                                    borderRadius: DarbRadius.md,
                                    elevated: false,
                                    borderColor: teal.withValues(
                                      alpha: isDark ? 0.34 : 0.24,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: teal.withValues(
                                              alpha: isDark ? 0.20 : 0.11,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.bolt_rounded,
                                            size: 17,
                                            color: teal,
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Text(
                                            quickPrompts[i],
                                            style: TextStyle(
                                              color: DarbColors.inkOf(context),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: DarbColors.mutedOf(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: totalItems,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (_sending && index == _messages.length) {
                              return Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DarbColors.surfaceOf(context),
                                    borderRadius:
                                        const BorderRadiusDirectional.only(
                                      topStart: Radius.circular(6),
                                      topEnd: Radius.circular(18),
                                      bottomStart: Radius.circular(18),
                                      bottomEnd: Radius.circular(18),
                                    ),
                                    border: Border.all(
                                      color: teal.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: DarbTypingDots(color: teal),
                                ),
                              );
                            }
                            final msg = _messages[index];
                            final bubbleRadius = msg.isUser
                                ? const BorderRadiusDirectional.only(
                                    topStart: Radius.circular(18),
                                    topEnd: Radius.circular(6),
                                    bottomStart: Radius.circular(18),
                                    bottomEnd: Radius.circular(18),
                                  )
                                : const BorderRadiusDirectional.only(
                                    topStart: Radius.circular(6),
                                    topEnd: Radius.circular(18),
                                    bottomStart: Radius.circular(18),
                                    bottomEnd: Radius.circular(18),
                                  );
                            return DarbFadeSlide(
                              child: Align(
                                alignment: msg.isUser
                                    ? AlignmentDirectional.centerEnd
                                    : AlignmentDirectional.centerStart,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * 0.82,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: msg.isError
                                          ? DarbColors.dangerSoftOf(context)
                                          : (msg.isUser
                                              ? DarbColors.forest
                                              : DarbColors.surfaceOf(context)),
                                      borderRadius: bubbleRadius,
                                      border: Border.all(
                                        color: msg.isError
                                            ? DarbColors.dangerOf(context)
                                                .withValues(alpha: 0.35)
                                            : (msg.isUser
                                                ? DarbColors.lime
                                                    .withValues(alpha: 0.32)
                                                : teal.withValues(alpha: 0.25)),
                                      ),
                                    ),
                                    child: Text(
                                      msg.text,
                                      style: TextStyle(
                                        color: msg.isError
                                            ? DarbColors.dangerOf(context)
                                            : (msg.isUser
                                                ? Colors.white
                                                : DarbColors.inkOf(context)),
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                    child: DarbGlassSurface(
                      borderRadius: DarbRadius.xl,
                      borderColor: teal.withValues(alpha: 0.30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: dt('اكتب سؤالك هنا...'),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatTurn {
  const _ChatTurn({
    required this.isUser,
    required this.text,
    this.isError = false,
  });
  final bool isUser;
  final String text;
  final bool isError;
}
