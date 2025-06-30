// // lib/core/services/supabase_client.dart
// import 'package:supabase_flutter/supabase_flutter.dart';

// class SupabaseClient {
//   static late final SupabaseClient _instance;
//   static bool _initialized = false;

//   static Future<void> initialize({
//     required String supabaseUrl,
//     required String supabaseAnonKey,
//   }) async {
//     if (!_initialized) {
//       await Supabase.initialize(
//         url: supabaseUrl,
//         anonKey: supabaseAnonKey,
//       );
//       _initialized = true;
//     }
//   }

//   static SupabaseClient get instance {
//     if (!_initialized) {
//       throw Exception('SupabaseClient must be initialized before use');
//     }
//     return SupabaseClient.instance;
//   }
// }
