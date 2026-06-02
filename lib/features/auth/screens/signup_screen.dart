import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      
      // Iniciar flujo OAuth de Google nativo de Supabase
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Ocurrió un problema al iniciar sesión con Google. Intenta nuevamente.';
        final msg = e.message.toLowerCase();
        if (msg.contains('cancelled') || msg.contains('canceled') || msg.contains('cancelado') || msg.contains('user_cancelled')) {
          errorMessage = 'Inicio con Google cancelado.';
        } else if (msg.contains('network') || msg.contains('connection') || msg.contains('conexión') || msg.contains('internet')) {
          errorMessage = 'No se pudo conectar con Google. Revisa tu conexión e intenta nuevamente.';
        } else if (msg.contains('block') || msg.contains('disable') || msg.contains('bloqueada') || msg.contains('suspended')) {
          errorMessage = 'Esta cuenta no está activa. Contacta al administrador.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ocurrió un problema al iniciar sesión. Intenta nuevamente.'),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Registro exitoso. ¡Te damos la bienvenida a la familia Corleone! Accediendo...',
              style: TextStyle(fontSize: 15),
            ),
            backgroundColor: GodfatherTheme.successGreen,
          ),
        );
        // Supabase automáticamente iniciará sesión o mandará confirmación de correo
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ocurrió un error inesperado al registrar el usuario.'),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('NUEVO REGISTRO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ÚNETE A LA FAMILIA',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Registra tus datos mínimos para iniciar la contabilidad familiar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: GodfatherTheme.textLight.withValues(alpha: 0.7),
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Botón "Continuar con Google" para registro (Accesible para adultos mayores, alto de 56px)
                    ElevatedButton.icon(
                      key: const Key('google_signup_button'),
                      onPressed: _isLoading ? null : _signUpWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GodfatherTheme.primaryGold,
                        foregroundColor: GodfatherTheme.backgroundBlack,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: Icon(
                        RemixIcons.google_fill,
                        color: GodfatherTheme.backgroundBlack,
                        size: 26,
                      ),
                      label: Text(
                        'Continuar con Google'.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Texto divisorio decorativo en oro
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: GodfatherTheme.borderColor,
                            thickness: 1.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'o regístrate con correo',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: GodfatherTheme.textLight.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: GodfatherTheme.borderColor,
                            thickness: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo Nombre Completo
                    TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(color: GodfatherTheme.textLight),
                      decoration: InputDecoration(
                        labelText: 'Nombre y Apellido',
                        prefixIcon: Icon(Icons.person_outline, color: GodfatherTheme.primaryGold),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu nombre completo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo de Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(color: GodfatherTheme.textLight),
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email_outlined, color: GodfatherTheme.primaryGold),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo de Contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(color: GodfatherTheme.textLight),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outlined, color: GodfatherTheme.primaryGold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: GodfatherTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        if (value.length < 8) {
                          return 'La contraseña debe tener al menos 8 caracteres';
                        }
                        // Validación alfanumérica y símbolos básica
                        if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&.]).{8,}$').hasMatch(value)) {
                          return 'Debe incluir letras, números y al menos un símbolo (ej. @,\$,!,.)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
  
                    // Confirmar Contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(color: GodfatherTheme.textLight),
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        prefixIcon: Icon(Icons.lock_reset_outlined, color: GodfatherTheme.primaryGold),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),
                    
                    // Botón Registrarse
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(GodfatherTheme.backgroundBlack),
                              ),
                            )
                          : const Text('CREAR CUENTA'),
                    ),
                    const SizedBox(height: 24),
                    
                    // Regresar al Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya eres de la familia?',
                          style: TextStyle(color: GodfatherTheme.textLight, fontSize: 17),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: GodfatherTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
