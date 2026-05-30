import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import '../../models/profile.dart';
import '../../models/transaction.dart' as model;
import '../../models/budget.dart';

// Proveedor de Supabase Client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Proveedor del estado de autenticación de Supabase (Escucha cambios de sesión)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

// Proveedor del usuario actual autenticado
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? ref.watch(supabaseClientProvider).auth.currentUser;
});

// Repositorio y Estado para el Perfil
class ProfileNotifier extends StateNotifier<AsyncValue<Profile?>> {
  final SupabaseClient _client;
  
  ProfileNotifier(this._client) : super(const AsyncValue.loading());

  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        state = AsyncValue.data(Profile.fromJson(response));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(String fullName) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('profiles')
          .update({'full_name': fullName})
          .eq('id', userId);
      
      // Recargar perfil para mantener consistencia local
      await loadProfile(userId);
    } catch (e) {
      rethrow;
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  
  final notifier = ProfileNotifier(client);
  if (user != null) {
    notifier.loadProfile(user.id);
  } else {
    notifier.clear();
  }
  return notifier;
});

// Repositorio y Estado para Transacciones
class TransactionNotifier extends StateNotifier<AsyncValue<List<model.Transaction>>> {
  final SupabaseClient _client;
  final String? _userId;

  TransactionNotifier(this._client, this._userId) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((json) => model.Transaction.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTransaction({
    required double amount,
    required String concept,
    required String category,
    required model.TransactionType type,
    required model.TargetModule target,
  }) async {
    if (_userId == null) return;
    try {
      final newTx = {
        'user_id': _userId,
        'amount': amount,
        'concept': concept,
        'category': category,
        'transaction_type': type == model.TransactionType.gasto ? 'gasto' : 'abono',
        'target_module': target == model.TargetModule.personal ? 'personal' : 'casa',
      };

      await _client.from('transactions').insert(newTx);
      // Recargar transacciones para reflejar el cambio
      await loadTransactions();
    } catch (e) {
      rethrow;
    }
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<model.Transaction>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return TransactionNotifier(client, user?.id);
});

// Repositorio y Estado para Presupuestos (Budgets)
class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  final SupabaseClient _client;
  final String? _userId;

  BudgetNotifier(this._client, this._userId) : super(const AsyncValue.loading()) {
    loadBudgetForCurrentMonth();
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return "${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  Future<void> loadBudgetForCurrentMonth() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final currentMY = _getCurrentMonthYear();
      final response = await _client
          .from('budgets')
          .select()
          .eq('user_id', _userId!)
          .eq('month_year', currentMY)
          .maybeSingle();

      if (response != null) {
        state = AsyncValue.data(Budget.fromJson(response));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setBudget(double limitAmount) async {
    if (_userId == null) return;
    try {
      final currentMY = _getCurrentMonthYear();
      
      // Buscar si ya existe presupuesto para este mes
      final existingResponse = await _client
          .from('budgets')
          .select('id')
          .eq('user_id', _userId!)
          .eq('month_year', currentMY)
          .maybeSingle();

      if (existingResponse != null) {
        // Actualizar
        final budgetId = existingResponse['id'] as String;
        await _client
            .from('budgets')
            .update({'limit_amount': limitAmount})
            .eq('id', budgetId);
      } else {
        // Insertar nuevo
        await _client.from('budgets').insert({
          'user_id': _userId,
          'limit_amount': limitAmount,
          'month_year': currentMY,
        });
      }
      await loadBudgetForCurrentMonth();
    } catch (e) {
      rethrow;
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return BudgetNotifier(client, user?.id);
});
