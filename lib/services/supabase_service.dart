import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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

  static Future<Debt> addDebt(Debt debt) async {
    final response = await _client.from('debts').insert(debt.toJson()).select().single();
    return Debt.fromJson(response);
  }

  static Future<void> updateDebt(String id, Map<String, dynamic> updates) async {
    try {
      // Удаляем id из обновлений, если он там случайно оказался, чтобы не менять первичный ключ
      updates.remove('id');
      
      // Если user_id пустой или не похож на UUID (длинная строка), удаляем его из обновлений
      if (updates['user_id'] != null && (updates['user_id'] as String).length < 20) {
        updates.remove('user_id');
      }

      final response = await _client.from('debts').update(updates).eq('id', id).select();
      
      if (response.isEmpty) {
        debugPrint('Warning: No rows updated for ID: $id');
        throw Exception('Запись не найдена в базе (возможно, неверный ID)');
      }
    } catch (e) {
      debugPrint('Supabase updateDebt error: $e');
      rethrow;
    }
  }

  static Future<void> deleteDebt(String id) async {
    try {
      await _client.from('debts').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase deleteDebt error: $e');
      rethrow;
    }
  }
}
