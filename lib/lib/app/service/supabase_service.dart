import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://ctlduplupiswmlvpnvki.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bGR1cGx1cGlzd21sdnBudmtpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MTExNzIsImV4cCI6MjA4MTA4NzE3Mn0.OsDUFv-AiTegVG6hJfJFWX83ZsKd5u9B4ISnJ8qliZM',
    );
  }
}