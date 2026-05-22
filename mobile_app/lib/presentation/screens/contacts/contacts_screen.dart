import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/language_utils.dart';
import '../../../data/models/contact_model.dart';
import '../../../providers/auth_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchCtrl = TextEditingController();
  List<ContactModel> _results = [];
  bool _loading = false;
  String _query = '';

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    try {
      final r = await http.get(
        Uri.parse('${AppConstants.searchContacts}?query=${Uri.encodeComponent(q)}'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body) as List;
        setState(() => _results = list.map((e) => ContactModel.fromJson(e)).toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              const Text('Contacts', style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
              ),
            ]),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) { setState(() => _query = v); _search(v); },
              decoration: InputDecoration(
                hintText: 'Search by username or name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _searchCtrl.clear(); setState(() { _query = ''; _results = []; }); })
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Results
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _results.isEmpty && _query.isEmpty
                ? _buildDefaultView()
                : _results.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🔍', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No users found for "$_query"',
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _contactTile(_results[i]),
                    ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDefaultView() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick Actions', style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _quickBtn('📞', 'New Call', AppColors.primary, () {})),
        const SizedBox(width: 12),
        Expanded(child: _quickBtn('💬', 'New Chat', AppColors.secondary, () {})),
        const SizedBox(width: 12),
        Expanded(child: _quickBtn('📹', 'Video', AppColors.accent, () {})),
      ]),
      const SizedBox(height: 28),
      const Text('Search users above to start translating calls!',
          style: TextStyle(fontSize: 14, color: AppColors.textHint)),
    ]),
  );

  Widget _quickBtn(String emoji, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );

  Widget _contactTile(ContactModel contact) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient, shape: BoxShape.circle,
          ),
          child: Center(child: Text(contact.initials,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
        if (contact.isOnline)
          Positioned(right: 0, bottom: 0, child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: AppColors.online, shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2)),
          )),
      ]),
      title: Text(contact.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Row(children: [
        Text('@${contact.username}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(width: 8),
        Text(LanguageUtils.getFlag(contact.preferredLanguage),
            style: const TextStyle(fontSize: 14)),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _iconBtn(Icons.message_outlined, () => context.go(
            '/chat/${contact.id}?name=${Uri.encodeComponent(contact.displayTitle)}')),
        const SizedBox(width: 4),
        _iconBtn(Icons.call_outlined, () => context.go(
            '/voice-call/${contact.id}?name=${Uri.encodeComponent(contact.displayTitle)}')),
      ]),
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 18),
    ),
  );
}
