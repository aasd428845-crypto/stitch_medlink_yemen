import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

/// One-time Supabase client initialization, called once from `main()`.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: AppConstants.supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
