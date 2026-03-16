import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://njxitwuvtrelvndbcgnk.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qeGl0d3V2dHJlbHZuZGJjZ25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5ODY4NDgsImV4cCI6MjA4MzU2Mjg0OH0.9dLvE6xxwT4Gx6AUIvHo9zvWG69uVoP72lP039V7VyQ',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
