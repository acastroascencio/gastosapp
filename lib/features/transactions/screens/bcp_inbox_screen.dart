// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/detected_movement.dart';
import '../../../models/family.dart';

class BcpInboxScreen extends ConsumerStatefulWidget {
  const BcpInboxScreen({super.key});

  @override
  ConsumerState<BcpInboxScreen> createState() => _BcpInboxScreenState();
}

class _BcpInboxScreenState extends ConsumerState<BcpInboxScreen> {
  bool _isSyncing = false;

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

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(emailSyncProvider.notifier).scanEmailsNow();
      _showSnackBar('Escaneo de Gmail finalizado. Se detectaron nuevos movimientos del BCP.', GodfatherTheme.successGreen);
    } catch (e) {
      _showSnackBar('Error al conectar con Gmail: $e', GodfatherTheme.alertRed);
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(emailSyncProvider);
    final familiesAsync = ref.watch(familyProvider);
    final families = familiesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BUZÓN GMAIL / BCP',
          style: GoogleFonts.cinzel(
            color: GodfatherTheme.primaryGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(RemixIcons.arrow_left_s_line, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(RemixIcons.mail_send_fill, color: GodfatherTheme.primaryGold, size: 26),
            tooltip: 'Buscar movimientos ahora',
            onPressed: _isSyncing ? null : _syncNow,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de seguridad
            Container(
              color: GodfatherTheme.surfaceDarkAlt,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(RemixIcons.shield_check_fill, color: GodfatherTheme.primaryGold, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONEXIÓN SEGURA OAUTH',
                          style: TextStyle(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No guardamos contraseñas de tu correo. Buscamos de forma encriptada transacciones del BCP.',
                          style: TextStyle(
                            color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: movementsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(GodfatherTheme.primaryGold)),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error al cargar bandeja: $err',
                    style: TextStyle(color: GodfatherTheme.alertRed, fontSize: 18),
                  ),
                ),
                data: (movements) {
                  final pending = movements.where((m) => m.status == 'pending').toList();

                  if (pending.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(RemixIcons.mail_line, size: 80, color: GodfatherTheme.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Buzón al día, Don.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: GodfatherTheme.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Pulsa el botón de arriba para escanear correos nuevos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: GodfatherTheme.textMuted, fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 56),
                              ),
                              onPressed: _isSyncing ? null : _syncNow,
                              icon: const Icon(RemixIcons.scan_line),
                              label: const Text('BUSCAR MOVIMIENTOS'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pending.length,
                    itemBuilder: (context, idx) {
                      final movement = pending[idx];
                      return _buildMovementCard(movement, families);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementCard(DetectedMovement movement, List<Family> families) {
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(movement.detectedDate);
    final isExpense = movement.detectedType == 'expense';

    return Card(
      color: GodfatherTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: GodfatherTheme.primaryGold, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header del banco
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1.5),
                      ),
                      child: Text(
                        movement.bank,
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sugerencia: ${movement.suggestedCategory}',
                      style: TextStyle(
                        color: GodfatherTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Concepto y monto detectados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.detectedConcept,
                        style: GoogleFonts.inter(
                          color: GodfatherTheme.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID de correo: ${movement.emailMessageId}',
                        style: TextStyle(
                          color: GodfatherTheme.isDarkMode ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${isExpense ? "-" : "+"} S/. ${movement.detectedAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey, thickness: 1.0),
            const SizedBox(height: 6),

            // Título de Aprobación
            Text(
              '¿DÓNDE DESEAS REGISTRARLO?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            // Botones de acción principales
            Row(
              children: [
                // Registrar en Caja Chica Personal
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GodfatherTheme.successGreen.withValues(alpha: 0.1),
                      side: BorderSide(color: GodfatherTheme.successGreen, width: 2.0),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _approveDirect(movement, 'personal'),
                    child: Text(
                      'PERSONAL',
                      style: TextStyle(color: GodfatherTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Ignorar
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: GodfatherTheme.textMuted, width: 1.5),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _ignore(movement.id),
                    child: Text(
                      'IGNORAR',
                      style: TextStyle(color: GodfatherTheme.textLight, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Selector de familias si pertenece a alguna
            if (families.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: families.map((family) {
                  return InkWell(
                    onTap: () => _approveDirect(movement, 'family', familyId: family.id),
                    child: Chip(
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      backgroundColor: GodfatherTheme.primaryGold.withValues(alpha: 0.1),
                      side: BorderSide(color: GodfatherTheme.primaryGold, width: 1.5),
                      avatar: Icon(RemixIcons.home_heart_fill, color: GodfatherTheme.primaryGold, size: 18),
                      label: Text(
                        family.name.toUpperCase(),
                        style: TextStyle(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Botón de Edición manual antes de aprobar
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GodfatherTheme.surfaceDarkAlt,
                side: BorderSide(color: GodfatherTheme.secondaryGold, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showEditApprovalDialog(movement, families),
              icon: Icon(RemixIcons.edit_2_line, color: GodfatherTheme.secondaryGold, size: 18),
              label: Text(
                'EDITAR ANTES DE REGISTRAR',
                style: TextStyle(color: GodfatherTheme.secondaryGold, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveDirect(DetectedMovement movement, String scope, {String? familyId}) async {
    try {
      await ref.read(emailSyncProvider.notifier).approveMovement(
            movement: movement,
            scope: scope,
            familyId: familyId,
            amount: movement.detectedAmount,
            concept: movement.detectedConcept,
            category: movement.suggestedCategory,
          );
      _showSnackBar('Movimiento registrado con éxito.', GodfatherTheme.successGreen);
    } catch (e) {
      _showSnackBar('Error al registrar movimiento: $e', GodfatherTheme.alertRed);
    }
  }

  Future<void> _ignore(String id) async {
    try {
      await ref.read(emailSyncProvider.notifier).ignoreMovement(id);
      _showSnackBar('Movimiento ignorado.', GodfatherTheme.textMuted);
    } catch (e) {
      _showSnackBar('Error al ignorar: $e', GodfatherTheme.alertRed);
    }
  }

  void _showEditApprovalDialog(DetectedMovement movement, List<Family> families) {
    final conceptController = TextEditingController(text: movement.detectedConcept);
    final amountController = TextEditingController(text: movement.detectedAmount.toString());
    String selectedCategory = movement.suggestedCategory;
    String selectedScope = 'personal';
    String? selectedFamilyId = families.isNotEmpty ? families.first.id : null;

    final categories = const [
      'Luz', 'Agua', 'Internet', 'Gas', 'Celular', 'Compras', 'Comida', 'Servicios',
      'Caja Chica', 'Abono / Sueldo', 'Otros'
    ];

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
                side: BorderSide(color: GodfatherTheme.primaryGold, width: 2),
              ),
              title: Text(
                'EDITAR Y REGISTRAR',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edita los datos del movimiento detectado antes de guardarlo en tu cuenta.',
                      style: TextStyle(
                        color: GodfatherTheme.isDarkMode ? const Color(0xFFD0D0D0) : const Color(0xFF4A4A4A),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Concepto
                    Text(
                      'Concepto',
                      style: TextStyle(
                        color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: conceptController,
                      style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'Concepto de la transacción',
                        hintStyle: TextStyle(color: GodfatherTheme.textMuted.withOpacity(0.5), fontSize: 16),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Monto
                    Text(
                      'Monto (S/.)',
                      style: TextStyle(
                        color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: GodfatherTheme.textMuted.withOpacity(0.5), fontSize: 16),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categoría
                    Text(
                      'Categoría',
                      style: TextStyle(
                        color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: GodfatherTheme.surfaceDark,
                      value: categories.contains(selectedCategory) ? selectedCategory : 'Otros',
                      style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: GodfatherTheme.textLight,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Destino (Personal / Familia)
                    Text(
                      'Destino / Cuenta',
                      style: TextStyle(
                        color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: GodfatherTheme.surfaceDark,
                      value: selectedScope,
                      style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'personal',
                          child: Text(
                            'Personal',
                            style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                          ),
                        ),
                        if (families.isNotEmpty)
                          DropdownMenuItem(
                            value: 'family',
                            child: Text(
                              'Familia Compartida',
                              style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                            ),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedScope = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selección de Familia si destino es Familia
                    if (selectedScope == 'family' && families.isNotEmpty) ...[
                      Text(
                        'Familia Específica',
                        style: TextStyle(
                          color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: GodfatherTheme.surfaceDark,
                        value: selectedFamilyId,
                        style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        items: families.map((fam) {
                          return DropdownMenuItem(
                            value: fam.id,
                            child: Text(
                              fam.name,
                              style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedFamilyId = val);
                          }
                        },
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
                          backgroundColor: GodfatherTheme.successGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: () async {
                          final double? amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            _showSnackBar('Ingresa un monto válido', GodfatherTheme.alertRed);
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            await ref.read(emailSyncProvider.notifier).approveMovement(
                                  movement: movement,
                                  scope: selectedScope,
                                  familyId: selectedScope == 'family' ? selectedFamilyId : null,
                                  amount: amount,
                                  concept: conceptController.text.trim(),
                                  category: selectedCategory,
                                );
                            _showSnackBar('Movimiento registrado con éxito.', GodfatherTheme.successGreen);
                          } catch (e) {
                            _showSnackBar('Error al registrar: $e', GodfatherTheme.alertRed);
                          }
                        },
                        child: const Text(
                          'REGISTRAR',
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
            );
          },
        );
      },
    );
  }
}
