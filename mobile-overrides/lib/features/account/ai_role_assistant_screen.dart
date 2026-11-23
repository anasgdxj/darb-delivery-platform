import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/darb_design_system.dart';
import '../../core/widgets/darb_glass.dart';

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

  Future<void> _send() async {
    final text = _inputController.text.trim();
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
        setState(() => _messages.add(_ChatTurn(isUser: false, text: reply)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _messages.add(_ChatTurn(isUser: false, text: e.message, isError: true)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _messages.add(_ChatTurn(isUser: false, text: dt('حدث خطأ غير متوقع، حاول مجدداً'), isError: true)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DarbGlassAppBar(title: dt('مساعد دَرْب الشخصي')),
      body: DarbAmbientBackground(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: DarbGlassSurface(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 38, color: DarbColors.primaryOf(context)),
                              const SizedBox(height: 12),
                              Text(
                                dt('اسأل مساعد دَرْب عن طلباتك أو مهامك الحالية وفق صلاحية حسابك'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: DarbColors.inkOf(context), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: _messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return Align(
                          alignment: msg.isUser
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                            child: DarbGlassSurface(
                              tintColor: msg.isError
                                  ? DarbColors.dangerSoftOf(context)
                                  : (msg.isUser ? DarbColors.forest : null),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Text(
                                msg.text,
                                style: TextStyle(
                                  color: msg.isError
                                      ? DarbColors.dangerOf(context)
                                      : (msg.isUser ? Colors.white : DarbColors.inkOf(context)),
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        style: IconButton.styleFrom(backgroundColor: DarbColors.primaryOf(context)),
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DarbColors.onPrimaryOf(context),
                                ),
                              )
                            : Icon(Icons.send_rounded, color: DarbColors.onPrimaryOf(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTurn {
  const _ChatTurn({required this.isUser, required this.text, this.isError = false});
  final bool isUser;
  final String text;
  final bool isError;
}
