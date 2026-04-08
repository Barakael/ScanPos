import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection_container.dart';
void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();
  // 2. Init Local Database
  await Hive.initFlutter();
  /// Laravel `php artisan serve` — API is at `/api`. Pass full API root, e.g.
  /// `http://127.0.0.1:8000/api` or your deployed `https://example.com/api`.
  const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.137:8000/api',
  );
  await setupDependencies(baseUrl: baseUrl);
  // 4. Start the App
  runApp(const App());    
}
