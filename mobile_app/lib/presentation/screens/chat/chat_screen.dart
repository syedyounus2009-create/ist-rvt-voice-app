import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/message_model.dart';
import '../../../data/services/websocket_service.dart';
import '../../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String contactName;
  const ChatScreen({super.key, required this.userId, required this.contactName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<MessageModel> _messages = [];
  final WebSocketService _ws = WebSocketService();
  bool _showTranslation = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _connectChat();
  }

  void _connectChat() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final roomId = _roomId(auth.user!.id, widget.userId);
    _ws.onSignal = (data) {
      if (data['type'] == 'chat_message') {
        setState(() => _messages.add(MessageModel.local(
          senderId: data['from_user'] ?? widget.userId,
          roomId: roomId,
          content: data['content'] ?? '',
          sourceLang: 'en', targetLang: 'ar',
          translatedContent: data['translated'],
        )));
        _scrollToBottom();
      }
    };
    _ws.connect(AppConstants.signalWs(roomId, auth.user!.id));
  }

  String _roomId(String a, String b) {
    final s = [a, b]..sort();
    return 'chat_${s[0]}_${s[1]}';
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _isTyping = false);
    final auth = context.read<AuthProvider>();
    String translated = text;
    try {
      final r = await http.post(Uri.parse(AppConstants.translateText),
          headers: auth.authHeaders,
          body: jsonEncode({'text': text,
            'source_lang': auth.user!.preferredLanguage,
            'target_lang': auth.user!.targetLanguage, 'synthesize': false}));
      if (r.statusCode == 200) translated = jsonDecode(r.body)['translated'] ?? text;
    } catch (_) {}

    setState(() => _messages.add(MessageModel.local(
      senderId: auth.user!.id,
      roomId: _roomId(auth.user!.id, widget.userId),
      content: text, sourceLang: auth.user!.preferredLanguage,
      targetLang: auth.user!.targetLanguage, translatedContent: translated,
    )));
    _scrollToBottom();
    _ws.sendJson({'type': 'chat_message', 'content': text, 'translated': translated});
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients)
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  void dispose() { _ws.dispose(); _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop()),
        title: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(
              widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.contactName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Text('Online', style: TextStyle(fontSize: 11, color: AppColors.accentGreen)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.primary.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            const Icon(Icons.translate_rounded, color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            const Expanded(child: Text('Auto-translation enabled',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Switch(value: _showTranslation, onChanged: (v) => setState(() => _showTranslation = v),
                activeColor: AppColors.primary),
          ]),
        ),
        Expanded(
          child: _messages.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('💬', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Start a conversation', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              ]))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _bubble(_messages[i], auth.user?.id ?? ''),
              ),
        ),
        _inputBar(),
      ]),
    );
  }

  Widget _bubble(MessageModel msg, String myId) {
    final mine = msg.senderId == myId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            Container(width: 28, height: 28,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Center(child: Text('U', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 8),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: mine ? AppColors.primaryGradient : null,
              color: mine ? null : AppColors.surfaceCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 4),
                bottomRight: Radius.circular(mine ? 4 : 18),
              ),
              boxShadow: mine ? [BoxShadow(color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(msg.content ?? '', style: TextStyle(fontSize: 14,
                  color: mine ? Colors.white : AppColors.textPrimary)),
              if (_showTranslation && msg.translatedContent != null &&
                  msg.translatedContent != msg.content) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.translate_rounded, size: 11, color: Colors.white54),
                    const SizedBox(width: 4),
                    Flexible(child: Text(msg.translatedContent!,
                        style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic))),
                  ]),
                ),
              ],
            ]),
          )),
        ],
      ),
    );
  }

  Widget _inputBar() => Container(
    padding: EdgeInsets.only(left: 16, right: 16, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14),
    decoration: const BoxDecoration(color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(children: [
      Expanded(child: Container(
        decoration: BoxDecoration(color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const SizedBox(width: 16),
          Expanded(child: TextField(
            controller: _msgCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Message (auto-translated)...', border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12)),
            onChanged: (v) => setState(() => _isTyping = v.isNotEmpty),
            onSubmitted: (_) => _send(),
          )),
        ]),
      )),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _isTyping ? _send : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: _isTyping ? AppColors.primaryGradient : null,
            color: _isTyping ? null : AppColors.surfaceCard,
            shape: BoxShape.circle),
          child: Icon(_isTyping ? Icons.send_rounded : Icons.mic_rounded,
              color: _isTyping ? Colors.white : AppColors.textHint, size: 20),
        ),
      ),
    ]),
  );
}
