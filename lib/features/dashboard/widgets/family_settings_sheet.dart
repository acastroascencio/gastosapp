// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
import '../../../models/transaction.dart';
import '../../../models/family.dart';
import '../../../core/supabase_service.dart';

class FamilySettingsSheet extends ConsumerStatefulWidget {
  const FamilySettingsSheet({super.key});

  @override
  ConsumerState<FamilySettingsSheet> createState() => _FamilySettingsSheetState();
}

class _FamilySettingsSheetState extends ConsumerState<FamilySettingsSheet> {
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createFamily() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(familyProvider.notifier).createFamily(_familyNameController.text.trim());
      _familyNameController.clear();
      _showSnackBar('¡Familia creada con éxito!', GodfatherTheme.successGreen);
    } catch (e) {
      _showSnackBar('Error al crear familia: $e', GodfatherTheme.alertRed);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinFamily() async {
    if (!_joinFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(familyProvider.notifier).joinFamily(_inviteCodeController.text.trim());
      _inviteCodeController.clear();
      _showSnackBar('¡Te has unido a la familia con éxito!', GodfatherTheme.successGreen);
    } catch (e) {
      _showSnackBar('Error al unirse: Código incorrecto o no encontrado.', GodfatherTheme.alertRed);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(familyProvider);
    final selectedFamily = ref.watch(selectedFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? 'guest-user-id';
    final transactionsAsync = ref.watch(transactionProvider);
    final allTransactions = transactionsAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        color: GodfatherTheme.backgroundBlack,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: GodfatherTheme.primaryGold, width: 1.5),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle visual top bar
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: GodfatherTheme.primaryGold,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Título
            Text(
              'ADMINISTRACIÓN FAMILIAR',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                color: GodfatherTheme.primaryGold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            familiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text(
                'Error al cargar familias: $err',
                style: TextStyle(color: GodfatherTheme.alertRed),
              ),
              data: (families) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Si el usuario pertenece a familias, mostrarlas
                    if (families.isNotEmpty) ...[
                      Text(
                        'MIS FAMILIAS',
                        style: GoogleFonts.cinzel(
                          color: GodfatherTheme.primaryGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...families.map((family) {
                        final isAdmin = family.adminUserId == currentUserId;
                        final isSelected = selectedFamily?.id == family.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: GodfatherTheme.surfaceDarkAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.borderColor,
                              width: isSelected ? 2.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Nombre y Badge de Selección
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      family.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: GodfatherTheme.textLight,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: GodfatherTheme.primaryGold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: GodfatherTheme.primaryGold, width: 1),
                                      ),
                                      child: Text(
                                        'ACTIVA',
                                        style: TextStyle(
                                          color: GodfatherTheme.primaryGold,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Código de Invitación
                              Row(
                                children: [
                                  Text(
                                    'Código de invitación: ',
                                    style: TextStyle(
                                      color: GodfatherTheme.textLight.withValues(alpha: 0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                  SelectableText(
                                    family.inviteCode,
                                    style: TextStyle(
                                      color: GodfatherTheme.primaryGold,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(RemixIcons.file_copy_line, color: GodfatherTheme.primaryGold, size: 20),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: family.inviteCode));
                                      _showSnackBar('Código copiado al portapapeles', GodfatherTheme.successGreen);
                                    },
                                  ),
                                  if (isAdmin)
                                    IconButton(
                                      icon: Icon(RemixIcons.refresh_line, color: GodfatherTheme.secondaryGold, size: 20),
                                      tooltip: 'Regenerar código de invitación',
                                      onPressed: () => _regenerateCode(family.id),
                                    ),
                                ],
                              ),
                              const Divider(color: Colors.grey),

                              // Miembros
                              Text(
                                'Miembros:',
                                style: TextStyle(
                                  color: GodfatherTheme.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...family.members.map((member) {
                                final isMe = member.userId == currentUserId;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '• ${member.fullName ?? "Miembro"} (${member.role == "admin" ? "Administrador" : "Miembro"})${isMe ? ' (Tú)' : ''}',
                                          style: TextStyle(
                                            color: GodfatherTheme.textLight,
                                            fontSize: 16,
                                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isAdmin && !isMe)
                                        IconButton(
                                          icon: const Icon(RemixIcons.user_unfollow_fill, color: Colors.red, size: 22),
                                          tooltip: 'Expulsar miembro',
                                          onPressed: () => _kickMember(family.id, member.userId, member.fullName ?? 'Miembro'),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),

                              // Botón de activación
                              if (!isSelected)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GodfatherTheme.surfaceDarkAlt,
                                    side: BorderSide(color: GodfatherTheme.primaryGold, width: 2),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  onPressed: () {
                                     ref.read(selectedFamilyProvider.notifier).update((_) => family);
                                    _showSnackBar('Familia ${family.name} seleccionada.', GodfatherTheme.successGreen);
                                  },
                                  child: Text(
                                    'SELECCIONAR COMO ACTIVA',
                                    style: TextStyle(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              
                              const SizedBox(height: 16),
                              const Divider(color: Colors.redAccent, thickness: 1.5),
                              const SizedBox(height: 8),
                              Text(
                                'ZONA DE PELIGRO',
                                style: GoogleFonts.cinzel(
                                  color: GodfatherTheme.alertRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (family.createdBy == currentUserId) ? GodfatherTheme.alertRed : Colors.grey.shade800,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: (family.createdBy == currentUserId) ? GodfatherTheme.alertRed : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onPressed: (family.createdBy == currentUserId)
                                    ? () => _showDeleteFamilyDialog(family, allTransactions)
                                    : () => _showSnackBar('Solo el creador puede eliminar esta familia', GodfatherTheme.alertRed),
                                icon: const Icon(RemixIcons.delete_bin_fill, size: 22),
                                label: Text(
                                  (family.createdBy == currentUserId) ? 'ELIMINAR FAMILIA' : 'SOLO EL CREADOR PUEDE ELIMINAR',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const Divider(height: 32, color: Colors.grey),

                    // Formularios de Creación / Unión
                    _buildCreateAndJoinForms(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAndJoinForms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CREAR FAMILIA
        Form(
          key: _createFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CREAR NUEVA FAMILIA',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nombre de la Familia',
                style: TextStyle(
                  color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _familyNameController,
                style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Ej. Familia Castro',
                  hintStyle: TextStyle(color: GodfatherTheme.textMuted.withOpacity(0.5), fontSize: 16),
                  prefixIcon: Icon(RemixIcons.home_gear_line, color: GodfatherTheme.primaryGold),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa un nombre';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: _isLoading ? null : _createFamily,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('CREAR FAMILIA'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // UNIRSE A FAMILIA
        Form(
          key: _joinFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNIRSE A UNA FAMILIA',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Código de Invitación',
                style: TextStyle(
                  color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inviteCodeController,
                style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Ej. CASTRO-8392',
                  hintStyle: TextStyle(color: GodfatherTheme.textMuted.withOpacity(0.5), fontSize: 16),
                  prefixIcon: Icon(RemixIcons.qr_code_line, color: GodfatherTheme.primaryGold),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el código';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: _isLoading ? null : _joinFamily,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('UNIRSE A FAMILIA'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _regenerateCode(String familyId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: GodfatherTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GodfatherTheme.primaryGold, width: 2),
        ),
        title: Text(
          'Regenerar código de invitación',
          style: GoogleFonts.cinzel(
            color: GodfatherTheme.primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Estás seguro de que deseas regenerar el código de invitación de esta familia?',
              style: TextStyle(
                color: GodfatherTheme.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GodfatherTheme.alertRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GodfatherTheme.alertRed, width: 1),
              ),
              child: Text(
                'Advertencia:\nEl código anterior dejará de funcionar de forma inmediata. Los miembros actuales permanecerán dentro de la familia.',
                style: TextStyle(
                  color: GodfatherTheme.alertRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    side: BorderSide(color: GodfatherTheme.textMuted, width: 1.5),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'CANCELAR',
                    style: TextStyle(color: GodfatherTheme.textLight, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GodfatherTheme.primaryGold,
                    foregroundColor: GodfatherTheme.backgroundBlack,
                    minimumSize: const Size(0, 56),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(familyProvider.notifier).regenerateInviteCode(familyId);
                      _showSnackBar('¡Código de invitación regenerado con éxito!', GodfatherTheme.successGreen);
                    } catch (e) {
                      _showSnackBar('Error al regenerar: $e', GodfatherTheme.alertRed);
                    }
                  },
                  child: const Text(
                    'SÍ, REGENERAR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteFamilyDialog(Family family, List<Transaction> allTransactions) {
    final familyTransactions = allTransactions.where((tx) => tx.familyId == family.id && !tx.deleted).toList();
    final memberCount = family.members.length;
    final expensesCount = familyTransactions.where((tx) => tx.transactionType == TransactionType.gasto).length;
    final abonosCount = familyTransactions.where((tx) => tx.transactionType == TransactionType.abono).length;

    final nameConfirmController = TextEditingController();
    bool isMatch = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: GodfatherTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: GodfatherTheme.alertRed, width: 2),
              ),
              title: Row(
                children: [
                  Icon(RemixIcons.delete_bin_fill, color: GodfatherTheme.alertRed, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ELIMINAR FAMILIA',
                      style: GoogleFonts.cinzel(
                        color: GodfatherTheme.alertRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Esta acción eliminará la familia y dejará de estar disponible para todos los miembros.',
                      style: TextStyle(
                        color: GodfatherTheme.textLight,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Los miembros ya no podrán ver ni registrar gastos en esta familia.',
                      style: TextStyle(
                        color: GodfatherTheme.textMuted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Resumen de datos a archivar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GodfatherTheme.primaryGold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GodfatherTheme.primaryGold.withOpacity(0.4), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Esta familia contiene:',
                            style: TextStyle(
                              color: GodfatherTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('• $memberCount miembros actuales', style: TextStyle(fontSize: 15, color: GodfatherTheme.textLight)),
                          Text('• $expensesCount gastos registrados', style: TextStyle(fontSize: 15, color: GodfatherTheme.textLight)),
                          Text('• $abonosCount abonos registrados', style: TextStyle(fontSize: 15, color: GodfatherTheme.textLight)),
                          const SizedBox(height: 8),
                          Text(
                            'Estos datos quedarán archivados y la familia dejará de estar activa.',
                            style: TextStyle(
                              color: GodfatherTheme.textLight.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo de confirmación externa
                    Text(
                      'Para confirmar, escribe el nombre de la familia:\n"${family.name}"',
                      style: TextStyle(
                        color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameConfirmController,
                      style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'Escribir nombre de la familia',
                        hintStyle: TextStyle(color: GodfatherTheme.textMuted.withOpacity(0.5), fontSize: 16),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isMatch ? GodfatherTheme.successGreen : GodfatherTheme.borderColor,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isMatch ? GodfatherTheme.successGreen : GodfatherTheme.alertRed,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          isMatch = val.trim() == family.name.trim();
                        });
                      },
                    ),
                    if (nameConfirmController.text.isNotEmpty && !isMatch) ...[
                      const SizedBox(height: 6),
                      Text(
                        'El nombre ingresado no coincide exactamente.',
                        style: TextStyle(color: GodfatherTheme.alertRed, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          side: BorderSide(color: GodfatherTheme.textMuted, width: 1.5),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'CANCELAR',
                          style: TextStyle(color: GodfatherTheme.textLight, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMatch ? GodfatherTheme.alertRed : Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: isMatch
                            ? () async {
                                Navigator.pop(ctx);
                                try {
                                  await ref.read(familyProvider.notifier).deleteFamily(family.id);
                                  _showSnackBar('Familia eliminada con éxito y archivada.', GodfatherTheme.successGreen);
                                } catch (e) {
                                  _showSnackBar('Error al eliminar: $e', GodfatherTheme.alertRed);
                                }
                              }
                            : null,
                        child: const Text(
                          'ELIMINAR',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _kickMember(String familyId, String userId, String userName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: GodfatherTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GodfatherTheme.alertRed, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: GodfatherTheme.alertRed, size: 28),
            const SizedBox(width: 10),
            Text(
              'EXPULSAR MIEMBRO',
              style: GoogleFonts.cinzel(
                color: GodfatherTheme.alertRed,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas expulsar a $userName de la familia?',
          style: TextStyle(
            color: GodfatherTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    side: BorderSide(color: GodfatherTheme.textMuted, width: 1.5),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: GodfatherTheme.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GodfatherTheme.alertRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 56),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(familyProvider.notifier).removeMember(familyId, userId);
                      _showSnackBar('Miembro expulsado.', GodfatherTheme.successGreen);
                    } catch (e) {
                      _showSnackBar('Error al expulsar: $e', GodfatherTheme.alertRed);
                    }
                  },
                  child: const Text(
                    'EXPULSAR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
