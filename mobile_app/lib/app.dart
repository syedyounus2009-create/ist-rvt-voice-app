import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/translator/translator_screen.dart';
import 'presentation/screens/calls/voice_call_screen.dart';
import 'presentation/screens/calls/video_call_screen.dart';
import 'presentation/screens/chat/chat_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/contacts/contacts_screen.dart';
import 'presentation/screens/history/history_screen.dart';

class ISTRVTApp extends StatefulWidget {
  const ISTRVTApp({super.key});

  @override
  State<ISTRVTApp> createState() => _ISTRVTAppState();
}

class _ISTRVTAppState extends State<ISTRVTApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isLoggedIn = auth.isAuthenticated;
        final loc = state.matchedLocation;
        final publicRoutes = ['/login', '/register', '/splash', '/onboarding', '/home', '/translator'];
        final isPublic = publicRoutes.contains(loc);

        if (!isLoggedIn && !isPublic) return '/home';
        if (isLoggedIn && (loc == '/login' || loc == '/register')) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/translator', builder: (_, __) => const TranslatorScreen()),
        GoRoute(path: '/contacts', builder: (_, __) => const ContactsScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(
          path: '/voice-call/:roomId',
          builder: (_, state) => VoiceCallScreen(
            roomId: state.pathParameters['roomId']!,
            contactName: state.uri.queryParameters['name'] ?? 'Unknown',
            targetLang: state.uri.queryParameters['lang'] ?? 'ar',
          ),
        ),
        GoRoute(
          path: '/video-call/:roomId',
          builder: (_, state) => VideoCallScreen(
            roomId: state.pathParameters['roomId']!,
            contactName: state.uri.queryParameters['name'] ?? 'Unknown',
          ),
        ),
        GoRoute(
          path: '/chat/:userId',
          builder: (_, state) => ChatScreen(
            userId: state.pathParameters['userId']!,
            contactName: state.uri.queryParameters['name'] ?? 'Chat',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp.router(
          title: 'IST-RVT',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: _router,
        );
      },
    );
  }
}
