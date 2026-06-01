import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class SeedItem {
  final String concept;
  final String category;
  final double amount;
  const SeedItem(this.concept, this.category, this.amount);
}

// Repositorio y Estado para Transacciones
class TransactionNotifier extends StateNotifier<AsyncValue<List<model.Transaction>>> {
  final SupabaseClient _client;
  final String? _userId;

  // A local list to hold bypass mode transactions in memory during app run
  static final List<model.Transaction> _localBypassTransactions = [];

  static const List<SeedItem> _seedItems = [
    SeedItem('WIN', 'Internet', 130.0),
    SeedItem('AGUA CHORRILLOS', 'Agua', 65.3),
    SeedItem('AGUA SURCO', 'Agua', 112.0),
    SeedItem('LUZ CHORRILLOS', 'Luz', 141.6),
    SeedItem('LUZ SURCO', 'Luz', 969.6),
    SeedItem('GAS CHORRILLOS 01', 'Gas', 22.0),
    SeedItem('GAS CHORRILLOS 02', 'Gas', 33.0),
    SeedItem('MOVISTAR SURCO', 'Celular', 126.67),
    SeedItem('SAGA', 'Compras / Crédito', 158.0),
    SeedItem('CELULAR BRENDA', 'Celular', 29.0),
    SeedItem('CELULAR MARIO', 'Celular', 62.0),
    SeedItem('CELULAR DIANA', 'Celular', 43.0),
  ];

  TransactionNotifier(this._client, this._userId) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> seedBypassIfNeeded() async {
    bool hasChanges = false;
    for (int month = 1; month <= 5; month++) {
      final date = DateTime(2026, month, 1, 12, 0);
      for (final item in _seedItems) {
        final exists = _localBypassTransactions.any((tx) =>
            tx.concept == item.concept &&
            tx.amount == item.amount &&
            tx.transactionType == model.TransactionType.gasto &&
            tx.targetModule == model.TargetModule.casa &&
            tx.createdAt.year == 2026 &&
            tx.createdAt.month == month);

        if (!exists) {
          final newTx = model.Transaction(
            id: 'seed-bypass-${item.concept}-$month',
            userId: 'guest-user-id',
            amount: item.amount,
            concept: item.concept,
            category: item.category,
            transactionType: model.TransactionType.gasto,
            targetModule: model.TargetModule.casa,
            createdAt: date,
          );
          _localBypassTransactions.add(newTx);
          hasChanges = true;
        }
      }
    }
    if (hasChanges) {
      _localBypassTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<void> seedSupabaseIfNeeded(List<model.Transaction> currentList) async {
    if (_userId == null) return;
    final List<Map<String, dynamic>> toInsert = [];
    
    for (int month = 1; month <= 5; month++) {
      final date = DateTime(2026, month, 1, 12, 0);
      for (final item in _seedItems) {
        final exists = currentList.any((tx) =>
            tx.concept == item.concept &&
            tx.amount == item.amount &&
            tx.transactionType == model.TransactionType.gasto &&
            tx.targetModule == model.TargetModule.casa &&
            tx.createdAt.year == 2026 &&
            tx.createdAt.month == month);

        if (!exists) {
          toInsert.add({
            'user_id': _userId,
            'amount': item.amount,
            'concept': item.concept,
            'category': item.category,
            'transaction_type': 'gasto',
            'target_module': 'casa',
            'created_at': date.toIso8601String(),
          });
        }
      }
    }
    
    if (toInsert.isNotEmpty) {
      try {
        await _client.from('transactions').insert(toInsert);
        // Reload silently to refresh state
        final response = await _client
            .from('transactions')
            .select()
            .eq('user_id', _userId)
            .order('created_at', ascending: false);

        final List<dynamic> data = response as List<dynamic>;
        final list = data.map((json) => model.Transaction.fromJson(json)).toList();
        state = AsyncValue.data(list);
      } catch (e) {
        developer.log('Error seeding Supabase', error: e);
      }
    }
  }

  Future<void> loadTransactions() async {
    if (_userId == null) {
      await seedBypassIfNeeded();
      state = AsyncValue.data(List.from(_localBypassTransactions));
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((json) => model.Transaction.fromJson(json)).toList();
      state = AsyncValue.data(list);
      await seedSupabaseIfNeeded(list);
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
    if (_userId == null) {
      final newTx = model.Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'guest-user-id',
        amount: amount,
        concept: concept,
        category: category,
        transactionType: type,
        targetModule: target,
        createdAt: DateTime.now(),
      );
      _localBypassTransactions.insert(0, newTx);
      state = AsyncValue.data(List.from(_localBypassTransactions));
      return;
    }
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

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String concept,
    required String category,
    required model.TransactionType type,
    required model.TargetModule target,
  }) async {
    if (_userId == null) {
      final index = _localBypassTransactions.indexWhere((tx) => tx.id == id);
      if (index >= 0) {
        final oldTx = _localBypassTransactions[index];
        _localBypassTransactions[index] = model.Transaction(
          id: oldTx.id,
          userId: oldTx.userId,
          amount: amount,
          concept: concept,
          category: category,
          transactionType: type,
          targetModule: target,
          createdAt: oldTx.createdAt, // Keep original createdAt
        );
        state = AsyncValue.data(List.from(_localBypassTransactions));
      }
      return;
    }
    try {
      final updatedData = {
        'amount': amount,
        'concept': concept,
        'category': category,
        'transaction_type': type == model.TransactionType.gasto ? 'gasto' : 'abono',
        'target_module': target == model.TargetModule.personal ? 'personal' : 'casa',
      };

      await _client
          .from('transactions')
          .update(updatedData)
          .eq('id', id);

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

  // A local budget in memory during app run for bypass mode
  static Budget? _localBypassBudget;

  BudgetNotifier(this._client, this._userId) : super(const AsyncValue.loading()) {
    loadBudgetForCurrentMonth();
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return "${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  Future<void> loadBudgetForCurrentMonth() async {
    if (_userId == null) {
      state = AsyncValue.data(_localBypassBudget);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final currentMY = _getCurrentMonthYear();
      final response = await _client
          .from('budgets')
          .select()
          .eq('user_id', _userId)
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
    if (_userId == null) {
      _localBypassBudget = Budget(
        id: 'bypass-budget-id',
        userId: 'guest-user-id',
        limitAmount: limitAmount,
        monthYear: _getCurrentMonthYear(),
      );
      state = AsyncValue.data(_localBypassBudget);
      return;
    }
    try {
      final currentMY = _getCurrentMonthYear();
      
      // Buscar si ya existe presupuesto para este mes
      final existingResponse = await _client
          .from('budgets')
          .select('id')
          .eq('user_id', _userId)
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
