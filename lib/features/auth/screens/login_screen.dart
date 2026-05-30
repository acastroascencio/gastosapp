import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Animaciones del Padrino
  late AnimationController _breathingController;
  late AnimationController _spinController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _spinAnimation;

  // Globo de diálogo y citas célebres financieras
  String _currentQuote = '';
  bool _showQuote = false;
  Timer? _quoteTimer;

  final List<String> _godfatherQuotes = [
    '“Te haré una oferta que no podrás rechazar...”',
    '“Un hombre sin honor no es nadie, Don.”',
    '“Maneja tus finanzas con sigilo y control.”',
    '“La familia es lo primero. Tus cuentas también.”',
    '“Nunca dejes que nadie sepa lo que estás gastando.”',
    '“El respeto se gana, y la Caja Chica se cuida.”',
  ];

  @override
  void initState() {
    super.initState();

    // Animación de respiración suave (continua)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // Animación de giro 3D rápido (al hacer clic)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _spinAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _breathingController.dispose();
    _spinController.dispose();
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _triggerAvatarInteraction() {
    if (_spinController.isAnimating) return;

    // Ejecutar el giro
    _spinController.forward(from: 0.0);

    // Escoger frase aleatoria
    final random = DateTime.now().millisecond % _godfatherQuotes.length;
    setState(() {
      _currentQuote = _godfatherQuotes[random];
      _showQuote = true;
    });

    // Ocultar frase tras 4 segundos
    _quoteTimer?.cancel();
    _quoteTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showQuote = false;
        });
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso concedido, Don.'),
            backgroundColor: GodfatherTheme.successGreen,
          ),
        );
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
          const SnackBar(
            content: Text('Error inesperado al iniciar sesión.'),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recoveryPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu correo para enviar el enlace de recuperación.'),
          backgroundColor: GodfatherTheme.primaryGold,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.resetPasswordForEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enlace de recuperación enviado al correo registrado.'),
            backgroundColor: GodfatherTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar recuperación: $e'),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Globo de diálogo del Padrino (si se activa al hacer tap)
                  Center(
                    child: AnimatedOpacity(
                      opacity: _showQuote ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _showQuote
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16161A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: GodfatherTheme.primaryGold, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                _currentQuote,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: GodfatherTheme.primaryGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : const SizedBox(height: 0),
                    ),
                  ),

                  // Avatar del Padrino Interactivo e Inteligente con giro 3D y respiración
                  Center(
                    child: AnimatedBuilder(
                      animation: _spinAnimation,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // Perspectiva para 3D
                            ..rotateY(_spinAnimation.value * 2 * 3.141592653589793), // Rotación Y
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                      child: ScaleTransition(
                        scale: _breathingAnimation,
                        child: GestureDetector(
                          onTap: _triggerAvatarInteraction,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: GodfatherTheme.primaryGold.withOpacity(0.35),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF5D77F), // Oro brillante
                                  Color(0xFFD4AF37), // Oro metálico
                                  Color(0xFF996515), // Oro bronce
                                  Color(0xFFD4AF37),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(4.0), // Anillo exterior
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: GodfatherTheme.backgroundBlack,
                              ),
                              padding: const EdgeInsets.all(2.0),
                              child: ClipOval(
                                child: Container(
                                  color: Colors.black,
                                  child: Transform.scale(
                                    scale: 1.38, // Elimina la cuadrícula externa del recurso
                                    child: Image.asset(
                                      'assets/images/godfather_asistente.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/godfather_asistente.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: GodfatherTheme.primaryGold,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título Premium
                  Text(
                    'THE GODFATHER',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mantén tus finanzas personales y del hogar bajo control',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: GodfatherTheme.textMuted,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Campo de Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: GodfatherTheme.textLight),
                    decoration: const InputDecoration(
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
                  const SizedBox(height: 18),
                  
                  // Campo de Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: GodfatherTheme.textLight),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined, color: GodfatherTheme.primaryGold),
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
                      return null;
                    },
                  ),
                  
                  // Olvidé mi contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _recoveryPassword,
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: GodfatherTheme.primaryGold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Botón Iniciar Sesión
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(GodfatherTheme.backgroundBlack),
                            ),
                          )
                        : const Text('ACCEDER'),
                  ),
                  const SizedBox(height: 12),

                  // Botón de ACCESO DIRECTO premium en oro (bypass)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GodfatherTheme.primaryGold,
                      side: const BorderSide(color: GodfatherTheme.primaryGold, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Acceso Directo concedido. Ingresando en modo desarrollador.'),
                          backgroundColor: GodfatherTheme.primaryGold,
                          duration: Duration(seconds: 1),
                        ),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                    },
                    child: Text(
                      'ACCESO DIRECTO (DESARROLLADOR)',
                      style: GoogleFonts.cinzel(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Registrarse
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Nuevo en el clan?',
                        style: TextStyle(color: GodfatherTheme.textMuted),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                                );
                              },
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            color: GodfatherTheme.primaryGold,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
