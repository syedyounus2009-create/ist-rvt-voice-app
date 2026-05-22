import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/language_utils.dart';

class LanguagePicker extends StatelessWidget {
  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  const LanguagePicker({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 10,
                color: AppColors.textHint, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(LanguageUtils.getFlag(value), style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(LanguageUtils.getName(value),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint, size: 16),
            ]),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _LanguagePickerSheet(
        selected: value, label: label, onChanged: onChanged,
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  final String selected;
  final String label;
  final ValueChanged<String> onChanged;

  const _LanguagePickerSheet({
    required this.selected, required this.label, required this.onChanged,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String _filter = '';
  late List<Map<String, String>> _langs;

  @override
  void initState() {
    super.initState();
    _langs = LanguageUtils.allLanguages;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _langs.where((l) =>
      (l['name'] ?? '').toLowerCase().contains(_filter.toLowerCase()) ||
      (l['native'] ?? '').toLowerCase().contains(_filter.toLowerCase())).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Select Language — ${widget.label}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: (v) => setState(() => _filter = v),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search languages...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true, fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: ctrl,
            itemCount: filtered.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (_, i) {
              final lang = filtered[i];
              final isSelected = lang['code'] == widget.selected;
              return ListTile(
                onTap: () {
                  widget.onChanged(lang['code']!);
                  Navigator.of(context).pop();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                leading: Text(lang['flag'] ?? '', style: const TextStyle(fontSize: 26)),
                title: Text(lang['name'] ?? '',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                subtitle: Text(lang['native'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
              );
            },
          ),
        ),
      ]),
    );
  }
}
