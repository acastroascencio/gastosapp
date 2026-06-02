import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile.dart';
import '../../models/transaction.dart' as model;
import '../../models/budget.dart';
import '../../models/family.dart';
import '../../models/audit.dart';
import '../../models/notification.dart';
import '../../models/detected_movement.dart';
import '../../models/learning_rule.dart';

// Proveedor de Supabase Client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Proveedor del estado de autenticación de Supabase
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
  final Ref _ref;

  // Local lists for in-memory bypass
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

  TransactionNotifier(this._client, this._userId, this._ref) : super(const AsyncValue.loading()) {
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
            familyId: 'fam-castro-id',
            createdByName: 'Mario Castro',
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
    
    // Check if user belongs to a family to assign family_id
    final familiesAsync = _ref.read(familyProvider);
    String? defaultFamilyId;
    if (familiesAsync is AsyncData<List<Family>> && familiesAsync.value.isNotEmpty) {
      defaultFamilyId = familiesAsync.value.first.id;
    }

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
            'family_id': defaultFamilyId,
            'created_at': date.toIso8601String(),
          });
        }
      }
    }
    
    if (toInsert.isNotEmpty) {
      try {
        await _client.from('transactions').insert(toInsert);
        await loadTransactions();
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
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((json) {
        String? fullName;
        if (json['profiles'] != null) {
          fullName = json['profiles']['full_name'] as String?;
        }
        return model.Transaction.fromJson(json, userFullName: fullName);
      }).toList();
      
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
    String? familyId,
  }) async {
    final now = DateTime.now();
    final currentUserName = _ref.read(profileProvider).value?.fullName ?? 'Mario Castro';

    if (target == model.TargetModule.casa && familyId != null) {
      final families = _ref.read(familyProvider).value ?? [];
      final hasActiveFamily = families.any((f) => f.id == familyId && !f.deleted);
      if (!hasActiveFamily) {
        throw Exception('No se pueden registrar gastos en una familia inactiva o eliminada.');
      }
    }
    
    if (_userId == null) {
      final newTx = model.Transaction(
        id: 'tx-${now.millisecondsSinceEpoch}',
        userId: 'guest-user-id',
        amount: amount,
        concept: concept,
        category: category,
        transactionType: type,
        targetModule: target,
        createdAt: now,
        familyId: target == model.TargetModule.casa ? (familyId ?? 'fam-castro-id') : null,
        createdByName: currentUserName,
      );
      _localBypassTransactions.insert(0, newTx);
      state = AsyncValue.data(List.from(_localBypassTransactions));

      // Trigger audit log and notification if shared family
      if (target == model.TargetModule.casa) {
        final fid = familyId ?? 'fam-castro-id';
        _ref.read(auditProvider.notifier).addLocalAudit(
              transactionId: newTx.id,
              familyId: fid,
              action: 'created',
              newData: newTx.toJson(),
            );
        
        _ref.read(notificationProvider.notifier).triggerLocalNotification(
              familyId: fid,
              type: 'transaction_created',
              title: 'Nuevo gasto familiar',
              message: '$currentUserName agregó un gasto de $concept por S/. ${amount.toStringAsFixed(2)}.',
            );
      }
      return;
    }
    
    try {
      final newTxData = {
        'user_id': _userId,
        'amount': amount,
        'concept': concept,
        'category': category,
        'transaction_type': type == model.TransactionType.gasto ? 'gasto' : 'abono',
        'target_module': target == model.TargetModule.personal ? 'personal' : 'casa',
        'family_id': target == model.TargetModule.casa ? familyId : null,
      };

      final response = await _client.from('transactions').insert(newTxData).select().single();
      final insertedTx = model.Transaction.fromJson(response, userFullName: currentUserName);

      // Trigger audit log and notification if shared family
      if (target == model.TargetModule.casa && familyId != null) {
        await _client.from('transaction_audits').insert({
          'transaction_id': insertedTx.id,
          'family_id': familyId,
          'action': 'created',
          'performed_by': _userId,
          'new_data': insertedTx.toJson(),
        });

        // Trigger notifications to other members
        final membersResponse = await _client
            .from('family_members')
            .select('user_id')
            .eq('family_id', familyId);
        
        for (var member in membersResponse) {
          final recipientId = member['user_id'] as String;
          if (recipientId != _userId) {
            await _client.from('notifications').insert({
              'family_id': familyId,
              'recipient_user_id': recipientId,
              'triggered_by': _userId,
              'type': 'transaction_created',
              'title': 'Gasto familiar registrado',
              'message': '$currentUserName registró un gasto de $concept por S/. ${amount.toStringAsFixed(2)}.',
            });
          }
        }
        
        _ref.read(notificationProvider.notifier).loadNotifications();
        _ref.read(auditProvider.notifier).loadAudits(familyId);
      }

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
    String? familyId,
  }) async {
    final now = DateTime.now();
    final currentUserName = _ref.read(profileProvider).value?.fullName ?? 'Mario Castro';

    if (target == model.TargetModule.casa && familyId != null) {
      final families = _ref.read(familyProvider).value ?? [];
      final hasActiveFamily = families.any((f) => f.id == familyId && !f.deleted);
      if (!hasActiveFamily) {
        throw Exception('No se pueden registrar gastos en una familia inactiva o eliminada.');
      }
    }

    if (_userId == null) {
      final index = _localBypassTransactions.indexWhere((tx) => tx.id == id);
      if (index >= 0) {
        final oldTx = _localBypassTransactions[index];
        final updatedTx = oldTx.copyWith(
          amount: amount,
          concept: concept,
          category: category,
          transactionType: type,
          targetModule: target,
          familyId: target == model.TargetModule.casa ? (familyId ?? oldTx.familyId ?? 'fam-castro-id') : null,
          updatedBy: 'guest-user-id',
        );
        _localBypassTransactions[index] = updatedTx;
        state = AsyncValue.data(List.from(_localBypassTransactions));

        // Trigger audit and notification if shared family
        if (target == model.TargetModule.casa || oldTx.targetModule == model.TargetModule.casa) {
          final fid = familyId ?? oldTx.familyId ?? 'fam-castro-id';
          _ref.read(auditProvider.notifier).addLocalAudit(
                transactionId: id,
                familyId: fid,
                action: 'updated',
                previousData: oldTx.toJson(),
                newData: updatedTx.toJson(),
              );
          
          _ref.read(notificationProvider.notifier).triggerLocalNotification(
                familyId: fid,
                type: 'transaction_updated',
                title: 'Gasto familiar editado',
                message: '$currentUserName editó el gasto $concept. Monto anterior: S/. ${oldTx.amount.toStringAsFixed(2)}. Nuevo monto: S/. ${amount.toStringAsFixed(2)}.',
              );
        }
      }
      return;
    }

    try {
      // Get previous data
      final prevResponse = await _client.from('transactions').select().eq('id', id).single();
      final oldTx = model.Transaction.fromJson(prevResponse);

      final updatedData = {
        'amount': amount,
        'concept': concept,
        'category': category,
        'transaction_type': type == model.TransactionType.gasto ? 'gasto' : 'abono',
        'target_module': target == model.TargetModule.personal ? 'personal' : 'casa',
        'family_id': target == model.TargetModule.casa ? familyId : null,
        'updated_by': _userId,
        'updated_at': now.toIso8601String(),
      };

      await _client.from('transactions').update(updatedData).eq('id', id);

      // Audit and notify if family
      final fid = familyId ?? oldTx.familyId;
      if (fid != null && (target == model.TargetModule.casa || oldTx.targetModule == model.TargetModule.casa)) {
        await _client.from('transaction_audits').insert({
          'transaction_id': id,
          'family_id': fid,
          'action': 'updated',
          'performed_by': _userId,
          'previous_data': oldTx.toJson(),
          'new_data': updatedData,
        });

        final membersResponse = await _client
            .from('family_members')
            .select('user_id')
            .eq('family_id', fid);
        
        for (var member in membersResponse) {
          final recipientId = member['user_id'] as String;
          if (recipientId != _userId) {
            await _client.from('notifications').insert({
              'family_id': fid,
              'recipient_user_id': recipientId,
              'triggered_by': _userId,
              'type': 'transaction_updated',
              'title': 'Gasto familiar editado',
              'message': '$currentUserName editó el gasto $concept. Monto anterior: S/. ${oldTx.amount.toStringAsFixed(2)}. Nuevo monto: S/. ${amount.toStringAsFixed(2)}.',
            });
          }
        }
        
        _ref.read(notificationProvider.notifier).loadNotifications();
        _ref.read(auditProvider.notifier).loadAudits(fid);
      }

      await loadTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> softDeleteTransaction(String id, String? familyId) async {
    final now = DateTime.now();
    final currentUserName = _ref.read(profileProvider).value?.fullName ?? 'Mario Castro';

    if (_userId == null) {
      final index = _localBypassTransactions.indexWhere((tx) => tx.id == id);
      if (index >= 0) {
        final oldTx = _localBypassTransactions[index];
        final deletedTx = oldTx.copyWith(
          deleted: true,
          deletedBy: 'guest-user-id',
          deletedAt: now,
        );
        
        // Remove from list or flag as deleted
        _localBypassTransactions[index] = deletedTx;
        state = AsyncValue.data(List.from(_localBypassTransactions));

        // Audit and notification
        final fid = familyId ?? oldTx.familyId ?? 'fam-castro-id';
        _ref.read(auditProvider.notifier).addLocalAudit(
              transactionId: id,
              familyId: fid,
              action: 'deleted',
              previousData: oldTx.toJson(),
            );
        
        _ref.read(notificationProvider.notifier).triggerLocalNotification(
              familyId: fid,
              type: 'transaction_deleted',
              title: 'Gasto familiar eliminado',
              message: '$currentUserName eliminó el gasto ${oldTx.concept}.',
            );
      }
      return;
    }

    try {
      final prevResponse = await _client.from('transactions').select().eq('id', id).single();
      final oldTx = model.Transaction.fromJson(prevResponse);

      final updateData = {
        'deleted': true,
        'deleted_by': _userId,
        'deleted_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _client.from('transactions').update(updateData).eq('id', id);

      final fid = familyId ?? oldTx.familyId;
      if (fid != null) {
        await _client.from('transaction_audits').insert({
          'transaction_id': id,
          'family_id': fid,
          'action': 'deleted',
          'performed_by': _userId,
          'previous_data': oldTx.toJson(),
        });

        final membersResponse = await _client
            .from('family_members')
            .select('user_id')
            .eq('family_id', fid);
        
        for (var member in membersResponse) {
          final recipientId = member['user_id'] as String;
          if (recipientId != _userId) {
            await _client.from('notifications').insert({
              'family_id': fid,
              'recipient_user_id': recipientId,
              'triggered_by': _userId,
              'type': 'transaction_deleted',
              'title': 'Gasto familiar eliminado',
              'message': '$currentUserName eliminó el gasto ${oldTx.concept}.',
            });
          }
        }
        
        _ref.read(notificationProvider.notifier).loadNotifications();
        _ref.read(auditProvider.notifier).loadAudits(fid);
      }

      await loadTransactions();
    } catch (e) {
      rethrow;
    }
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<model.Transaction>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return TransactionNotifier(client, user?.id, ref);
});

// Repositorio y Estado para Presupuestos
class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  final SupabaseClient _client;
  final String? _userId;

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
      
      final existingResponse = await _client
          .from('budgets')
          .select('id')
          .eq('user_id', _userId)
          .eq('month_year', currentMY)
          .maybeSingle();

      if (existingResponse != null) {
        final budgetId = existingResponse['id'] as String;
        await _client
            .from('budgets')
            .update({'limit_amount': limitAmount})
            .eq('id', budgetId);
      } else {
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

// ==========================================
// 1. FAMILIAS COMPARTIDAS PROVIDER
// ==========================================
final selectedFamilyProvider = StateProvider<Family?>((ref) {
  final familiesAsync = ref.watch(familyProvider);
  return familiesAsync.when(
    data: (list) => list.isNotEmpty ? list.first : null,
    error: (_, __) => null,
    loading: () => null,
  );
});

class FamilyNotifier extends StateNotifier<AsyncValue<List<Family>>> {
  final SupabaseClient _client;
  final String? _userId;
  final Ref _ref;

  static final List<Family> _localBypassFamilies = [
    Family(
      id: 'fam-castro-id',
      name: 'Familia Castro',
      inviteCode: 'CASTRO-8392',
      createdBy: 'guest-user-id',
      adminUserId: 'guest-user-id',
      members: [
        FamilyMember(userId: 'guest-user-id', role: 'admin', joinedAt: DateTime(2026, 1, 1), fullName: 'Mario Castro'),
        FamilyMember(userId: 'brenda-user-id', role: 'member', joinedAt: DateTime(2026, 1, 2), fullName: 'Brenda Castro'),
        FamilyMember(userId: 'diana-user-id', role: 'member', joinedAt: DateTime(2026, 1, 3), fullName: 'Diana Castro'),
      ],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Family(
      id: 'fam-gutierrez-id',
      name: 'Familia Gutiérrez',
      inviteCode: 'GUTIERREZ-1049',
      createdBy: 'guest-user-id',
      adminUserId: 'guest-user-id',
      members: [
        FamilyMember(userId: 'guest-user-id', role: 'admin', joinedAt: DateTime(2026, 2, 1), fullName: 'Mario Castro'),
        FamilyMember(userId: 'carlos-user-id', role: 'member', joinedAt: DateTime(2026, 2, 2), fullName: 'Carlos Gutiérrez'),
      ],
      createdAt: DateTime(2026, 2, 1),
      updatedAt: DateTime(2026, 2, 1),
    ),
  ];

  FamilyNotifier(this._client, this._userId, this._ref) : super(const AsyncValue.loading()) {
    loadFamilies();
  }

  Future<void> loadFamilies() async {
    if (_userId == null) {
      state = AsyncValue.data(List.from(_localBypassFamilies.where((f) => !f.deleted)));
      return;
    }
    state = const AsyncValue.loading();
    try {
      // Fetch families where user is a member
      final membersResponse = await _client
          .from('family_members')
          .select('family_id')
          .eq('user_id', _userId);
      
      final List<String> familyIds = (membersResponse as List<dynamic>)
          .map((item) => item['family_id'] as String)
          .toList();

      if (familyIds.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final familiesResponse = await _client
          .from('families')
          .select('*, family_members(*, profiles(full_name))')
          .eq('deleted', false)
          .inFilter('id', familyIds);

      final List<dynamic> data = familiesResponse as List<dynamic>;
      final families = data.map((json) {
        final rawMembers = json['family_members'] as List<dynamic>? ?? [];
        final parsedMembers = rawMembers.map((m) {
          String? name;
          if (m['profiles'] != null) {
            name = m['profiles']['full_name'] as String?;
          }
          return FamilyMember.fromJson(m, userFullName: name);
        }).toList();

        return Family(
          id: json['id'] as String,
          name: json['name'] as String,
          inviteCode: json['invite_code'] as String,
          createdBy: json['created_by'] as String,
          adminUserId: json['admin_user_id'] as String,
          members: parsedMembers,
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          deleted: json['deleted'] as bool? ?? false,
          deletedBy: json['deleted_by'] as String?,
          deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
        );
      }).toList();

      state = AsyncValue.data(families);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createFamily(String name) async {
    final now = DateTime.now();
    final randomCode = '${name.replaceAll(' ', '').toUpperCase()}-${1000 + Random().nextInt(9000)}';
    
    if (_userId == null) {
      final newFamily = Family(
        id: 'fam-${now.millisecondsSinceEpoch}',
        name: name,
        inviteCode: randomCode,
        createdBy: 'guest-user-id',
        adminUserId: 'guest-user-id',
        members: [
          FamilyMember(userId: 'guest-user-id', role: 'admin', joinedAt: now, fullName: 'Mario Castro'),
        ],
        createdAt: now,
        updatedAt: now,
      );
      _localBypassFamilies.add(newFamily);
      state = AsyncValue.data(List.from(_localBypassFamilies));
      _ref.read(selectedFamilyProvider.notifier).update((_) => newFamily);
      return;
    }

    try {
      final familyData = {
        'name': name,
        'invite_code': randomCode,
        'created_by': _userId,
        'admin_user_id': _userId,
      };

      final response = await _client.from('families').insert(familyData).select().single();
      final familyId = response['id'] as String;

      // Automatically join as admin member
      await _client.from('family_members').insert({
        'family_id': familyId,
        'user_id': _userId,
        'role': 'admin',
      });

      await loadFamilies();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinFamily(String inviteCode) async {
    final now = DateTime.now();
    final uppercaseCode = inviteCode.trim().toUpperCase();

    if (_userId == null) {
      final index = _localBypassFamilies.indexWhere((f) => f.inviteCode == uppercaseCode && !f.deleted);
      if (index >= 0) {
        final family = _localBypassFamilies[index];
        if (!family.members.any((m) => m.userId == 'guest-user-id')) {
          final updatedMembers = List<FamilyMember>.from(family.members)
            ..add(FamilyMember(userId: 'guest-user-id', role: 'member', joinedAt: now, fullName: 'Mario Castro'));
          
          final updatedFamily = family.copyWith(members: updatedMembers);
          _localBypassFamilies[index] = updatedFamily;
          state = AsyncValue.data(List.from(_localBypassFamilies.where((f) => !f.deleted)));
          _ref.read(selectedFamilyProvider.notifier).update((_) => updatedFamily);
        }
      } else {
        throw Exception('Código de invitación inválido o familia no disponible.');
      }
      return;
    }

    try {
      final familyResponse = await _client
          .from('families')
          .select('id, deleted')
          .eq('invite_code', uppercaseCode)
          .eq('deleted', false)
          .maybeSingle();

      if (familyResponse == null) {
        throw Exception('El código de invitación no existe o la familia fue eliminada.');
      }

      final familyId = familyResponse['id'] as String;

      // Join
      await _client.from('family_members').insert({
        'family_id': familyId,
        'user_id': _userId,
        'role': 'member',
      });

      await loadFamilies();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> regenerateInviteCode(String familyId) async {
    final now = DateTime.now();
    final family = state.value?.firstWhere((f) => f.id == familyId);
    if (family == null) return;
    
    final newCode = '${family.name.replaceAll(' ', '').toUpperCase()}-${1000 + Random().nextInt(9000)}';

    if (_userId == null) {
      final index = _localBypassFamilies.indexWhere((f) => f.id == familyId);
      if (index >= 0) {
        final previousFamily = _localBypassFamilies[index];
        final updatedFamily = previousFamily.copyWith(
          inviteCode: newCode,
          updatedAt: now,
        );
        _localBypassFamilies[index] = updatedFamily;

        // Audit log
        _ref.read(auditProvider.notifier).addLocalAudit(
          transactionId: 'regen-$familyId',
          familyId: familyId,
          action: 'updated',
          previousData: {'invite_code': previousFamily.inviteCode},
          newData: {'invite_code': newCode},
        );

        // Notifications
        for (var member in family.members) {
          if (member.userId != 'guest-user-id') {
            _ref.read(notificationProvider.notifier).addLocalNotification(
              familyId: familyId,
              recipientUserId: member.userId,
              type: 'code_regenerated',
              title: 'Código regenerado',
              message: 'El código de invitación de la familia ${family.name} fue regenerado por Mario Castro.',
            );
          }
        }

        state = AsyncValue.data(List.from(_localBypassFamilies.where((f) => !f.deleted)));
        _ref.read(selectedFamilyProvider.notifier).update((_) => updatedFamily);
      }
      return;
    }

    try {
      await _client
          .from('families')
          .update({'invite_code': newCode, 'updated_at': now.toIso8601String()})
          .eq('id', familyId);

      // Audit log
      await _client.from('transaction_audits').insert({
        'transaction_id': 'regen-$familyId',
        'family_id': familyId,
        'action': 'updated',
        'performed_by': _userId,
        'previous_data': {'invite_code': family.inviteCode},
        'new_data': {'invite_code': newCode},
      });

      // Get profile name
      final profileResponse = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', _userId)
          .single();
      final String performerName = profileResponse['full_name'] as String? ?? 'Administrador';

      // Notifications
      final notifications = family.members
          .where((m) => m.userId != _userId)
          .map((m) => {
                'family_id': familyId,
                'recipient_user_id': m.userId,
                'triggered_by': _userId,
                'type': 'code_regenerated',
                'title': 'Código regenerado',
                'message': 'El código de invitación de la familia ${family.name} fue regenerado por $performerName.',
              })
          .toList();

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
      }

      await loadFamilies();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFamily(String familyId) async {
    final now = DateTime.now();
    final family = state.value?.firstWhere((f) => f.id == familyId);
    if (family == null) return;

    final currentUserId = _userId ?? 'guest-user-id';
    if (family.createdBy != currentUserId) {
      throw Exception('Solo el creador puede eliminar esta familia');
    }

    if (_userId == null) {
      final index = _localBypassFamilies.indexWhere((f) => f.id == familyId);
      if (index >= 0) {
        final updatedFamily = _localBypassFamilies[index].copyWith(
          deleted: true,
          deletedBy: 'guest-user-id',
          deletedAt: now,
        );
        _localBypassFamilies[index] = updatedFamily;
        
        // Remove from active selection if selected
        final selectedFam = _ref.read(selectedFamilyProvider);
        if (selectedFam?.id == familyId) {
          _ref.read(selectedFamilyProvider.notifier).update((_) => null);
        }
        
        // Trigger local audit
        _ref.read(auditProvider.notifier).addLocalAudit(
          transactionId: 'deletion-$familyId',
          familyId: familyId,
          action: 'family_deleted',
          previousData: family.toJson(),
          newData: {
            'deleted': true,
            'deleted_by': 'guest-user-id',
            'deleted_at': now.toIso8601String(),
          },
        );

        // Trigger local notification for all members (except current user)
        for (var member in family.members) {
          if (member.userId != 'guest-user-id') {
            _ref.read(notificationProvider.notifier).addLocalNotification(
              familyId: familyId,
              recipientUserId: member.userId,
              type: 'family_deleted',
              title: 'Familia eliminada',
              message: 'La familia ${family.name} fue eliminada por Mario Castro.',
            );
          }
        }

        await loadFamilies();
      }
      return;
    }

    try {
      // 1. Soft-delete family in Supabase
      await _client
          .from('families')
          .update({
            'deleted': true,
            'deleted_by': _userId,
            'deleted_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', familyId);

      // 2. Fetch current user's profile to get name
      final profileResponse = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', _userId)
          .single();
      final String performerName = profileResponse['full_name'] as String? ?? 'Administrador';

      // 3. Create Audit log
      await _client.from('transaction_audits').insert({
        'transaction_id': 'deletion-$familyId',
        'family_id': familyId,
        'action': 'family_deleted',
        'performed_by': _userId,
        'previous_data': family.toJson(),
        'new_data': {
          'deleted': true,
          'deleted_by': _userId,
          'deleted_at': now.toIso8601String(),
        },
      });

      // 4. Send notifications to all members (except current user)
      final notifications = family.members
          .where((m) => m.userId != _userId)
          .map((m) => {
                'family_id': familyId,
                'recipient_user_id': m.userId,
                'triggered_by': _userId,
                'type': 'family_deleted',
                'title': 'Familia eliminada',
                'message': 'La familia ${family.name} fue eliminada por $performerName.',
              })
          .toList();

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
      }

      // 5. Remove from active selection if selected
      final selectedFam = _ref.read(selectedFamilyProvider);
      if (selectedFam?.id == familyId) {
        _ref.read(selectedFamilyProvider.notifier).update((_) => null);
      }

      await loadFamilies();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember(String familyId, String memberUserId) async {
    if (_userId == null) {
      final index = _localBypassFamilies.indexWhere((f) => f.id == familyId);
      if (index >= 0) {
        final family = _localBypassFamilies[index];
        final updatedMembers = family.members.where((m) => m.userId != memberUserId).toList();
        final updatedFamily = family.copyWith(members: updatedMembers);
        _localBypassFamilies[index] = updatedFamily;
        state = AsyncValue.data(List.from(_localBypassFamilies));
        _ref.read(selectedFamilyProvider.notifier).update((_) => updatedFamily);
      }
      return;
    }

    try {
      await _client
          .from('family_members')
          .delete()
          .eq('family_id', familyId)
          .eq('user_id', memberUserId);

      await loadFamilies();
    } catch (e) {
      rethrow;
    }
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, AsyncValue<List<Family>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return FamilyNotifier(client, user?.id, ref);
});

// ==========================================
// 2. AUDITORÍA DE CAMBIOS PROVIDER
// ==========================================
class AuditNotifier extends StateNotifier<AsyncValue<List<TransactionAudit>>> {
  final SupabaseClient _client;
  final String? _userId;

  static final List<TransactionAudit> _localBypassAudits = [
    TransactionAudit(
      id: 'audit-1',
      transactionId: 'seed-bypass-AGUA SURCO-5',
      familyId: 'fam-castro-id',
      action: 'updated',
      performedBy: 'brenda-user-id',
      previousData: {'concept': 'AGUA SURCO', 'amount': 100.0, 'category': 'Agua'},
      newData: {'concept': 'AGUA SURCO', 'amount': 112.0, 'category': 'Agua'},
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      performedByName: 'Brenda Castro',
    ),
    TransactionAudit(
      id: 'audit-2',
      transactionId: 'seed-bypass-MOVISTAR SURCO-5',
      familyId: 'fam-castro-id',
      action: 'deleted',
      performedBy: 'diana-user-id',
      previousData: {'concept': 'MOVISTAR SURCO', 'amount': 126.67, 'category': 'Celular'},
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      performedByName: 'Diana Castro',
    ),
  ];

  AuditNotifier(this._client, this._userId) : super(const AsyncValue.loading());

  Future<void> loadAudits(String familyId) async {
    if (_userId == null) {
      final list = _localBypassAudits.where((a) => a.familyId == familyId).toList();
      state = AsyncValue.data(list);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('transaction_audits')
          .select('*, profiles(full_name)')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((json) {
        String? name;
        if (json['profiles'] != null) {
          name = json['profiles']['full_name'] as String?;
        }
        return TransactionAudit.fromJson(json, userFullName: name);
      }).toList();

      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void addLocalAudit({
    required String transactionId,
    required String familyId,
    required String action,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
  }) {
    final now = DateTime.now();
    final newAudit = TransactionAudit(
      id: 'audit-${now.millisecondsSinceEpoch}',
      transactionId: transactionId,
      familyId: familyId,
      action: action,
      performedBy: 'guest-user-id',
      previousData: previousData,
      newData: newData,
      createdAt: now,
      performedByName: 'Mario Castro',
    );
    _localBypassAudits.insert(0, newAudit);
    state = AsyncValue.data(_localBypassAudits.where((a) => a.familyId == familyId).toList());
  }

  void setEmpty() {
    state = const AsyncValue.data([]);
  }
}

final auditProvider = StateNotifierProvider<AuditNotifier, AsyncValue<List<TransactionAudit>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  final selectedFamily = ref.watch(selectedFamilyProvider);
  
  final notifier = AuditNotifier(client, user?.id);
  if (selectedFamily != null) {
    notifier.loadAudits(selectedFamily.id);
  } else {
    notifier.setEmpty();
  }
  return notifier;
});

// ==========================================
// 3. NOTIFICACIONES PROVIDER
// ==========================================
class NotificationNotifier extends StateNotifier<AsyncValue<List<FamilyNotification>>> {
  final SupabaseClient _client;
  final String? _userId;

  static final List<FamilyNotification> _localBypassNotifications = [
    FamilyNotification(
      id: 'notif-1',
      familyId: 'fam-castro-id',
      recipientUserId: 'guest-user-id',
      triggeredBy: 'brenda-user-id',
      type: 'transaction_created',
      title: 'Gasto familiar registrado',
      message: 'Brenda agregó un gasto de Agua por S/. 112.00 en Familia Castro.',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      triggeredByName: 'Brenda Castro',
    ),
    FamilyNotification(
      id: 'notif-2',
      familyId: 'fam-castro-id',
      recipientUserId: 'guest-user-id',
      triggeredBy: 'diana-user-id',
      type: 'transaction_deleted',
      title: 'Gasto familiar eliminado',
      message: 'Diana eliminó el gasto Movistar Surco.',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      triggeredByName: 'Diana Castro',
    ),
  ];

  NotificationNotifier(this._client, this._userId) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    if (_userId == null) {
      state = AsyncValue.data(List.from(_localBypassNotifications));
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('notifications')
          .select('*, profiles!notifications_triggered_by_fkey(full_name)')
          .eq('recipient_user_id', _userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((json) {
        String? name;
        if (json['profiles'] != null) {
          name = json['profiles']['full_name'] as String?;
        }
        return FamilyNotification.fromJson(json, triggeredByName: name);
      }).toList();

      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) {
      final index = _localBypassNotifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        _localBypassNotifications[index] = _localBypassNotifications[index].copyWith(read: true);
        state = AsyncValue.data(List.from(_localBypassNotifications));
      }
      return;
    }

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      
      await loadNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) {
      for (int i = 0; i < _localBypassNotifications.length; i++) {
        _localBypassNotifications[i] = _localBypassNotifications[i].copyWith(read: true);
      }
      state = AsyncValue.data(List.from(_localBypassNotifications));
      return;
    }

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('recipient_user_id', _userId);
      
      await loadNotifications();
    } catch (e) {
      rethrow;
    }
  }

  void triggerLocalNotification({
    required String familyId,
    required String type,
    required String title,
    required String message,
  }) {
    final now = DateTime.now();
    final newNotif = FamilyNotification(
      id: 'notif-${now.millisecondsSinceEpoch}',
      familyId: familyId,
      recipientUserId: 'guest-user-id',
      triggeredBy: 'brenda-user-id',
      type: type,
      title: title,
      message: message,
      read: false,
      createdAt: now,
      triggeredByName: 'Brenda Castro',
    );
    _localBypassNotifications.insert(0, newNotif);
    state = AsyncValue.data(List.from(_localBypassNotifications));
  }

  void addLocalNotification({
    required String familyId,
    required String recipientUserId,
    required String type,
    required String title,
    required String message,
  }) {
    final now = DateTime.now();
    final newNotif = FamilyNotification(
      id: 'notif-${now.millisecondsSinceEpoch}',
      familyId: familyId,
      recipientUserId: recipientUserId,
      triggeredBy: 'guest-user-id',
      type: type,
      title: title,
      message: message,
      read: false,
      createdAt: now,
      triggeredByName: 'Mario Castro',
    );
    _localBypassNotifications.insert(0, newNotif);
    state = AsyncValue.data(List.from(_localBypassNotifications));
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<FamilyNotification>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return NotificationNotifier(client, user?.id);
});

// ==========================================
// 4. DETECCIÓN GMAIL/BCP PROVIDER
// ==========================================
class EmailSyncNotifier extends StateNotifier<AsyncValue<List<DetectedMovement>>> {
  final SupabaseClient _client;
  final String? _userId;
  final Ref _ref;

  static final List<DetectedMovement> _localBypassEmails = [];

  EmailSyncNotifier(this._client, this._userId, this._ref) : super(const AsyncValue.loading()) {
    loadDetectedMovements();
  }

  Future<void> loadDetectedMovements() async {
    if (_userId == null) {
      state = AsyncValue.data(List.from(_localBypassEmails));
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('email_detected_movements')
          .select()
          .eq('user_id', _userId)
          .eq('status', 'pending')
          .order('detected_date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((json) => DetectedMovement.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> scanEmailsNow() async {
    final now = DateTime.now();
    // Simulate secure Gmail reading of BCP emails
    if (_userId == null) {
      // Add 3 mock movements if empty to let user play with it
      if (_localBypassEmails.isEmpty) {
        final mockMovements = [
          DetectedMovement(
            id: 'email-tx-1',
            userId: 'guest-user-id',
            provider: 'gmail',
            bank: 'BCP',
            emailMessageId: 'msg-plaza-vea-9382',
            detectedAmount: 43.00,
            detectedDate: now,
            detectedConcept: 'Consumo BCP PLAZA VEA',
            detectedCurrency: 'PEN',
            detectedType: 'expense',
            suggestedCategory: 'Compras',
            status: 'pending',
            createdAt: now,
            updatedAt: now,
          ),
          DetectedMovement(
            id: 'email-tx-2',
            userId: 'guest-user-id',
            provider: 'gmail',
            bank: 'BCP',
            emailMessageId: 'msg-sedapal-4820',
            detectedAmount: 85.00,
            detectedDate: now.subtract(const Duration(minutes: 30)),
            detectedConcept: 'Pago de servicio SEDAPAL',
            detectedCurrency: 'PEN',
            detectedType: 'expense',
            suggestedCategory: 'Agua',
            status: 'pending',
            createdAt: now,
            updatedAt: now,
          ),
          DetectedMovement(
            id: 'email-tx-3',
            userId: 'guest-user-id',
            provider: 'gmail',
            bank: 'BCP',
            emailMessageId: 'msg-abono-haberes-8219',
            detectedAmount: 500.00,
            detectedDate: now.subtract(const Duration(hours: 1)),
            detectedConcept: 'Abono de haberes BCP',
            detectedCurrency: 'PEN',
            detectedType: 'income',
            suggestedCategory: 'Otros',
            status: 'pending',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // Apply automatic suggestions learned by category learning rules
        for (int i = 0; i < mockMovements.length; i++) {
          final resolved = _ref.read(learningRulesProvider.notifier).suggestCategoryAndScope(mockMovements[i].detectedConcept);
          if (resolved != null) {
            mockMovements[i] = mockMovements[i].copyWith(
              suggestedCategory: resolved['category'] as String,
              detectedType: resolved['type'] as String,
            );
          }
        }

        _localBypassEmails.addAll(mockMovements);
      }
      state = AsyncValue.data(List.from(_localBypassEmails));
      return;
    }

    try {
      // Simulate OAuth BCP Inbox Scanner
      final mockData = [
        {
          'user_id': _userId,
          'email_message_id': 'msg-plaza-vea-${now.millisecondsSinceEpoch}',
          'detected_amount': 43.00,
          'detected_date': now.toIso8601String(),
          'detected_concept': 'Consumo BCP PLAZA VEA',
          'suggested_category': 'Compras',
          'detected_type': 'expense',
        },
        {
          'user_id': _userId,
          'email_message_id': 'msg-sedapal-${now.millisecondsSinceEpoch}',
          'detected_amount': 85.00,
          'detected_date': now.subtract(const Duration(minutes: 30)).toIso8601String(),
          'detected_concept': 'Pago de servicio SEDAPAL',
          'suggested_category': 'Agua',
          'detected_type': 'expense',
        },
        {
          'user_id': _userId,
          'email_message_id': 'msg-abono-haberes-${now.millisecondsSinceEpoch}',
          'detected_amount': 500.00,
          'detected_date': now.subtract(const Duration(hours: 1)).toIso8601String(),
          'detected_concept': 'Abono de haberes BCP',
          'suggested_category': 'Otros',
          'detected_type': 'income',
        }
      ];

      for (var data in mockData) {
        // Apply heuristics first
        final resolvedHeuristics = _ref.read(learningRulesProvider.notifier).suggestCategoryAndScope(data['detected_concept'] as String);
        if (resolvedHeuristics != null) {
          data['suggested_category'] = resolvedHeuristics['category'] as String;
          data['detected_type'] = resolvedHeuristics['type'] as String;
        }

        await _client.from('email_detected_movements').upsert(data, onConflict: 'email_message_id');
      }

      await loadDetectedMovements();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveMovement({
    required DetectedMovement movement,
    required String scope, // 'personal' | 'family'
    String? familyId,
    required double amount,
    required String concept,
    required String category,
  }) async {
    // Add to real transactions
    await _ref.read(transactionProvider.notifier).addTransaction(
          amount: amount,
          concept: concept,
          category: category,
          type: movement.detectedType == 'income' ? model.TransactionType.abono : model.TransactionType.gasto,
          target: scope == 'personal' ? model.TargetModule.personal : model.TargetModule.casa,
          familyId: familyId,
        );

    // Update learning rules heuristically!
    await _ref.read(learningRulesProvider.notifier).learnFromApproval(
          keyword: movement.detectedConcept,
          category: category,
          scope: scope,
          familyId: familyId,
        );

    if (_userId == null) {
      _localBypassEmails.removeWhere((m) => m.id == movement.id);
      state = AsyncValue.data(List.from(_localBypassEmails));
      return;
    }

    try {
      await _client
          .from('email_detected_movements')
          .update({'status': 'approved', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', movement.id);

      await loadDetectedMovements();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> ignoreMovement(String movementId) async {
    if (_userId == null) {
      _localBypassEmails.removeWhere((m) => m.id == movementId);
      state = AsyncValue.data(List.from(_localBypassEmails));
      return;
    }

    try {
      await _client
          .from('email_detected_movements')
          .update({'status': 'ignored', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', movementId);

      await loadDetectedMovements();
    } catch (e) {
      rethrow;
    }
  }
}

final emailSyncProvider = StateNotifierProvider<EmailSyncNotifier, AsyncValue<List<DetectedMovement>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return EmailSyncNotifier(client, user?.id, ref);
});

// ==========================================
// 5. APRENDIZAJE DE CATEGORÍAS PROVIDER
// ==========================================
class LearningRulesNotifier extends StateNotifier<AsyncValue<List<CategoryLearningRule>>> {
  final SupabaseClient _client;
  final String? _userId;

  static final List<CategoryLearningRule> _localBypassRules = [
    CategoryLearningRule(
      id: 'rule-1',
      userId: 'guest-user-id',
      keyword: 'PLAZA VEA',
      suggestedCategory: 'Compras',
      suggestedScope: 'personal',
      confidence: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CategoryLearningRule(
      id: 'rule-2',
      userId: 'guest-user-id',
      keyword: 'SEDAPAL',
      suggestedCategory: 'Agua',
      suggestedScope: 'family',
      confidence: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  LearningRulesNotifier(this._client, this._userId) : super(const AsyncValue.loading()) {
    loadLearningRules();
  }

  Future<void> loadLearningRules() async {
    if (_userId == null) {
      state = AsyncValue.data(List.from(_localBypassRules));
      return;
    }
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('category_learning_rules')
          .select()
          .eq('user_id', _userId)
          .order('confidence', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data.map((json) => CategoryLearningRule.fromJson(json)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Map<String, dynamic>? suggestCategoryAndScope(String rawConcept) {
    final rules = state.value ?? [];
    for (var rule in rules) {
      if (rawConcept.toUpperCase().contains(rule.keyword.toUpperCase())) {
        return {
          'category': rule.suggestedCategory,
          'scope': rule.suggestedScope,
          'familyId': rule.suggestedFamilyId,
          'type': (rule.suggestedCategory == 'Abono / Sueldo' || rule.suggestedCategory == 'Ingresos') ? 'income' : 'expense',
        };
      }
    }
    
    // Fallback heurístico básico
    final conceptUpper = rawConcept.toUpperCase();
    if (conceptUpper.contains('LUZ') || conceptUpper.contains('ELECTRI')) {
      return {'category': 'Luz', 'scope': 'family', 'type': 'expense'};
    } else if (conceptUpper.contains('AGUA') || conceptUpper.contains('SEDAPAL')) {
      return {'category': 'Agua', 'scope': 'family', 'type': 'expense'};
    } else if (conceptUpper.contains('INTERNET') || conceptUpper.contains('WIN') || conceptUpper.contains('MOVISTAR')) {
      return {'category': 'Internet', 'scope': 'family', 'type': 'expense'};
    } else if (conceptUpper.contains('COMIDA') || conceptUpper.contains('PLAZA VEA') || conceptUpper.contains('METRO') || conceptUpper.contains('TOTTUS') || conceptUpper.contains('WONG')) {
      return {'category': 'Compras', 'scope': 'personal', 'type': 'expense'};
    }
    return null;
  }

  Future<void> learnFromApproval({
    required String keyword,
    required String category,
    String? scope,
    String? familyId,
  }) async {
    final cleanedKeyword = _extractKeyword(keyword);
    final now = DateTime.now();

    if (_userId == null) {
      final index = _localBypassRules.indexWhere((r) => r.keyword.toUpperCase() == cleanedKeyword.toUpperCase());
      if (index >= 0) {
        final existing = _localBypassRules[index];
        _localBypassRules[index] = existing.copyWith(
          suggestedCategory: category,
          suggestedScope: scope,
          suggestedFamilyId: familyId,
          confidence: existing.confidence + 1,
          updatedAt: now,
        );
      } else {
        _localBypassRules.add(CategoryLearningRule(
          id: 'rule-${now.millisecondsSinceEpoch}',
          userId: 'guest-user-id',
          keyword: cleanedKeyword,
          suggestedCategory: category,
          suggestedScope: scope,
          suggestedFamilyId: familyId,
          confidence: 1,
          createdAt: now,
          updatedAt: now,
        ));
      }
      state = AsyncValue.data(List.from(_localBypassRules));
      return;
    }

    try {
      final existingRuleResponse = await _client
          .from('category_learning_rules')
          .select()
          .eq('user_id', _userId)
          .eq('keyword', cleanedKeyword)
          .maybeSingle();

      if (existingRuleResponse != null) {
        final ruleId = existingRuleResponse['id'] as String;
        final currentConfidence = existingRuleResponse['confidence'] as int? ?? 1;
        
        await _client.from('category_learning_rules').update({
          'suggested_category': category,
          'suggested_scope': scope,
          'suggested_family_id': familyId,
          'confidence': currentConfidence + 1,
          'updated_at': now.toIso8601String(),
        }).eq('id', ruleId);
      } else {
        await _client.from('category_learning_rules').insert({
          'user_id': _userId,
          'keyword': cleanedKeyword,
          'suggested_category': category,
          'suggested_scope': scope,
          'suggested_family_id': familyId,
          'confidence': 1,
        });
      }

      await loadLearningRules();
    } catch (e) {
      developer.log('Error updating category learning rules', error: e);
    }
  }

  String _extractKeyword(String rawConcept) {
    // Clean up strings like "Consumo BCP PLAZA VEA" -> "PLAZA VEA"
    final replaced = rawConcept
        .replaceAll('Consumo BCP ', '')
        .replaceAll('Pago de servicio ', '')
        .replaceAll('Transferencia BCP ', '')
        .replaceAll('Abono BCP ', '')
        .trim();
    return replaced.isNotEmpty ? replaced : rawConcept;
  }
}

final learningRulesProvider = StateNotifierProvider<LearningRulesNotifier, AsyncValue<List<CategoryLearningRule>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return LearningRulesNotifier(client, user?.id);
});
