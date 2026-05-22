/// Language utilities for IST-RVT
class LanguageUtils {
  LanguageUtils._();

  static const Map<String, Map<String, String>> languages = {
    'en': {'name': 'English',    'native': 'English',    'flag': '🇺🇸', 'rtl': 'false'},
    'ar': {'name': 'Arabic',     'native': 'العربية',    'flag': '🇸🇦', 'rtl': 'true'},
    'zh': {'name': 'Chinese',    'native': '中文',        'flag': '🇨🇳', 'rtl': 'false'},
    'ur': {'name': 'Urdu',       'native': 'اردو',       'flag': '🇵🇰', 'rtl': 'true'},
    'fr': {'name': 'French',     'native': 'Français',   'flag': '🇫🇷', 'rtl': 'false'},
    'es': {'name': 'Spanish',    'native': 'Español',    'flag': '🇪🇸', 'rtl': 'false'},
    'de': {'name': 'German',     'native': 'Deutsch',    'flag': '🇩🇪', 'rtl': 'false'},
    'hi': {'name': 'Hindi',      'native': 'हिन्दी',     'flag': '🇮🇳', 'rtl': 'false'},
    'tr': {'name': 'Turkish',    'native': 'Türkçe',     'flag': '🇹🇷', 'rtl': 'false'},
    'pt': {'name': 'Portuguese', 'native': 'Português',  'flag': '🇧🇷', 'rtl': 'false'},
    'ru': {'name': 'Russian',    'native': 'Русский',    'flag': '🇷🇺', 'rtl': 'false'},
    'ja': {'name': 'Japanese',   'native': '日本語',      'flag': '🇯🇵', 'rtl': 'false'},
    'ko': {'name': 'Korean',     'native': '한국어',      'flag': '🇰🇷', 'rtl': 'false'},
    'it': {'name': 'Italian',    'native': 'Italiano',   'flag': '🇮🇹', 'rtl': 'false'},
    'fa': {'name': 'Persian',    'native': 'فارسی',      'flag': '🇮🇷', 'rtl': 'true'},
  };

  static String getName(String code) =>
      languages[code]?['name'] ?? code.toUpperCase();

  static String getNative(String code) =>
      languages[code]?['native'] ?? code.toUpperCase();

  static String getFlag(String code) =>
      languages[code]?['flag'] ?? '🌐';

  static bool isRTL(String code) =>
      languages[code]?['rtl'] == 'true';

  static String getDisplayName(String code) {
    final lang = languages[code];
    if (lang == null) return code.toUpperCase();
    return '${lang['flag']} ${lang['name']}';
  }

  static List<Map<String, String>> get allLanguages =>
      languages.entries.map((e) => {'code': e.key, ...e.value}).toList();
}
