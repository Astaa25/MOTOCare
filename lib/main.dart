import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase bila URL dan Anon Key tersedia
  if (AppEnv.supabaseUrl.isNotEmpty && AppEnv.supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppEnv.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialize info/error: $e');
    }
  }

  // Jalankan aplikasi dengan Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: MotoCareApp(),
    ),
  );
}
