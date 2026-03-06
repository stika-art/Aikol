import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/debt.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Auth
  static User? get currentUser => _client.auth.currentUser;

  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Debt CRUD
  static Future<List<Debt>> getDebts() async {
    final response = await _client
        .from('debts')
        .select()
        .limit(1000);
    
    return (response as List).map((json) => Debt.fromJson(json)).toList();
  }

  static Future<void> addDebt(Debt debt) async {
    await _client.from('debts').insert(debt.toJson());
  }

  static Future<void> updateDebt(String id, Map<String, dynamic> updates) async {
    await _client.from('debts').update(updates).eq('id', id);
  }

  static Future<void> deleteDebt(String id) async {
    await _client.from('debts').delete().eq('id', id);
  }
}
