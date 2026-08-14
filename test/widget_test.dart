// This is a basic Flutter widget test.
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech4allweb/main.dart';
import 'package:tech4allweb/screens/splash_screen.dart';

void main() {
  setUpAll(() async {
    // Mock the SharedPreferences channel for the test environment
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    
    // Initialize Supabase config before running tests
    await Supabase.initialize(
      url: 'https://nhrpqizxxqiiknwaaxlp.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ocnBxaXp4eHFpaWtud2FheGxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMjUxMDgsImV4cCI6MjA4NzcwMTEwOH0.Tkm5JRnjbn-nSWvpRZWmoRCRvkhlmco8Q-fWMCXdKDQ',
    );
  });


  testWidgets('Splash screen shows on startup test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our SplashScreen is present.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
