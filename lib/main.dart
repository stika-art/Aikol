import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Инициализация Supabase. 
  // Вставьте ваши реальные данные здесь для облачного хранения.
  // Если данные не верны, приложение будет работать в демо-режиме (локально).
  try {
    await Supabase.initialize(
      url: 'https://ippqhsonlujxevoscdvz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlwcHFoc29ubHVqeGV2b3NjZHZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3NTMzMTAsImV4cCI6MjA4ODMyOTMxMH0.bWniqxu_TPI10BqVOMYaA8JtN3H4ecxgwRh79_02BFo',
    );
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  runApp(const DebtlyApp());
}

class DebtlyApp extends StatefulWidget {
  const DebtlyApp({super.key});

  @override
  State<DebtlyApp> createState() => _DebtlyAppState();
}

class _DebtlyAppState extends State<DebtlyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Это предотвращает появление "синего цвета" при возврате в приложение
      _updateSystemUI();
    }
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0F0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aikol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Принудительно темная тема
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

