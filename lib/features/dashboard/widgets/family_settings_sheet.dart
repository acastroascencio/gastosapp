import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
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
                                          '• ${member.fullName ?? "Miembro"} (${member.role == "admin" ? "Administrador" : "Miembro"})' + (isMe ? ' (Tú)' : ''),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CREAR NUEVA FAMILIA',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _familyNameController,
                style: TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Familia (Ej. Familia Castro)',
                  prefixIcon: Icon(RemixIcons.home_gear_line),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa un nombre';
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
        const SizedBox(height: 24),

        // UNIRSE A FAMILIA
        Form(
          key: _joinFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'UNIRSE A UNA FAMILIA',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inviteCodeController,
                style: TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Código de Invitación (Ej. CASTRO-8392)',
                  prefixIcon: Icon(RemixIcons.qr_code_line),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el código';
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: GodfatherTheme.surfaceDark,
        title: Text('Regenerar Código', style: TextStyle(color: GodfatherTheme.primaryGold)),
        content: const Text(
          'Al regenerar el código de invitación, el anterior dejará de funcionar de forma inmediata. ¿Deseas continuar?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCELAR', style: TextStyle(color: GodfatherTheme.primaryGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GodfatherTheme.primaryGold),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(familyProvider.notifier).regenerateInviteCode(familyId);
                _showSnackBar('¡Código de invitación regenerado con éxito!', GodfatherTheme.successGreen);
              } catch (e) {
                _showSnackBar('Error al regenerar: $e', GodfatherTheme.alertRed);
              }
            },
            child: const Text('SÍ, REGENERAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _kickMember(String familyId, String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GodfatherTheme.surfaceDark,
        title: Text('Expulsar Miembro', style: TextStyle(color: GodfatherTheme.alertRed)),
        content: Text(
          '¿Estás seguro de que deseas expulsar a $userName de la familia?',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCELAR', style: TextStyle(color: GodfatherTheme.primaryGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GodfatherTheme.alertRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(familyProvider.notifier).removeMember(familyId, userId);
                _showSnackBar('Miembro expulsado.', GodfatherTheme.successGreen);
              } catch (e) {
                _showSnackBar('Error al expulsar: $e', GodfatherTheme.alertRed);
              }
            },
            child: const Text('SÍ, EXPULSAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
