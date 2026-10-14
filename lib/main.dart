import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Jalankan aplikasi dengan Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: MotoCareApp(),
    ),
  );
}
