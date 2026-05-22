import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/translation_provider.dart';
import 'providers/call_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive local storage
  await Hive.initFlutter();
  await Hive.openBox('ist_rvt_settings');
  await Hive.openBox('ist_rvt_messages');
  await Hive.openBox('ist_rvt_calls');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: const ISTRVTApp(),
    ),
  );
}
