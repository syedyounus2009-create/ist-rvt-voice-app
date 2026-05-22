import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/language_utils.dart';
import '../../../data/models/contact_model.dart';
import '../../../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<CallHistoryModel> _calls = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() => _loading = true);
    try {
      final r = await http.get(Uri.parse(AppConstants.callHistory),
          headers: {'Authorization': 'Bearer ${auth.token}'});
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        setState(() => _calls = list.map((e) => CallHistoryModel.fromJson(e)).toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(children: [
            const Text('History', style: TextStyle(fontSize: 24,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                onPressed: _load),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14)),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10)),
            labelColor: Colors.white, unselectedLabelColor: AppColors.textHint,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: '📞  Calls'), Tab(text: '📊  Stats')],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _callsTab(), _statsTab(),
        ])),
      ])),
    );
  }

  Widget _callsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_calls.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('📞', style: TextStyle(fontSize: 48)),
      SizedBox(height: 12),
      Text('No calls yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
    ]));
    return RefreshIndicator(onRefresh: _load, color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _calls.length,
        itemBuilder: (_, i) => _tile(_calls[i]),
      ));
  }

  Widget _tile(CallHistoryModel c) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(width: 44, height: 44,
        decoration: BoxDecoration(
          color: c.isMissed ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
        child: Icon(c.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            color: c.isMissed ? AppColors.error : AppColors.primary, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${LanguageUtils.getFlag(c.sourceLang)} → ${LanguageUtils.getFlag(c.targetLang)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 3),
        Text('${c.durationFormatted} · ${c.totalTranslations} translations · ⚡${c.avgLatencyMs.toStringAsFixed(0)}ms',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.isMissed ? AppColors.error.withOpacity(0.1) : AppColors.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(c.status.toUpperCase(), style: TextStyle(fontSize: 9,
            fontWeight: FontWeight.w700,
            color: c.isMissed ? AppColors.error : AppColors.accentGreen))),
    ]),
  );

  Widget _statsTab() {
    final total = _calls.length;
    final totalMins = _calls.fold(0, (s, c) => s + c.durationSeconds) ~/ 60;
    final totalTrans = _calls.fold(0, (s, c) => s + c.totalTranslations);
    final avgLat = _calls.isEmpty ? 0.0
        : _calls.fold(0.0, (s, c) => s + c.avgLatencyMs) / _calls.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        Row(children: [
          Expanded(child: _card('Calls', '$total', Icons.call_rounded, AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _card('Minutes', '$totalMins', Icons.timer_outlined, AppColors.secondary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _card('Translated', '$totalTrans', Icons.translate_rounded, AppColors.accent)),
          const SizedBox(width: 12),
          Expanded(child: _card('Avg Latency', '${avgLat.toStringAsFixed(0)}ms',
              Icons.bolt, AppColors.accentGreen)),
        ]),
      ]),
    );
  }

  Widget _card(String label, String value, IconData icon, Color color) =>
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]));
}
