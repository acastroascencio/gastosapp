import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../core/storage_helper.dart';
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
  bool _rememberEmail = false;
  bool _keepMeLoggedIn = false;

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
    '“Te haré una oferta que no podrás rechazar...” (El Padrino I)',
    '“Mantén cerca a tus amigos, pero aún más cerca a tus enemigos.” (El Padrino II)',
    '“Un hombre que no pasa tiempo con su familia nunca puede ser un hombre de verdad.” (El Padrino I)',
    '“Nunca dejes que nadie fuera de la familia sepa lo que estás pensando.” (El Padrino I)',
    '“La salud es lo más importante, después del amor y del dinero.” (El Padrino III)',
    '“Nunca odies a tus enemigos, afecta tu juicio.” (El Padrino I)',
    '“Justo cuando creía que estaba fuera, ¡me vuelven a meter!” (El Padrino III)',
    '“El poder corrompe a quienes no lo tienen.” (El Padrino III)',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();

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

  Future<void> _loadSavedEmail() async {
    final savedEmail = await StorageHelper.getString('remembered_email');
    final keepLogged = await StorageHelper.getString('keep_me_logged_in') == 'true';
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberEmail = true;
      });
    }
    setState(() {
      _keepMeLoggedIn = keepLogged;
    });
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
      final emailStr = _emailController.text.trim();
      
      // Save/delete email memory depending on checkbox
      if (_rememberEmail) {
        await StorageHelper.saveString('remembered_email', emailStr);
      } else {
        await StorageHelper.deleteString('remembered_email');
      }
      
      await StorageHelper.saveString('keep_me_logged_in', _keepMeLoggedIn.toString());

      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(
        email: emailStr,
        password: _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Acceso concedido, Don.'),
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
          SnackBar(
            content: const Text('Error inesperado al iniciar sesión.'),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      
      // Iniciar flujo OAuth de Google nativo de Supabase
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Ocurrió un problema al iniciar sesión. Intenta nuevamente.';
        final msg = e.message.toLowerCase();
        if (msg.contains('cancelled') || msg.contains('canceled') || msg.contains('cancelado') || msg.contains('user_cancelled')) {
          errorMessage = 'Inicio con Google cancelado.';
        } else if (msg.contains('network') || msg.contains('connection') || msg.contains('conexión') || msg.contains('internet')) {
          errorMessage = 'No se pudo conectar con Google. Revisa tu internet e intenta nuevamente.';
        } else if (msg.contains('block') || msg.contains('disable') || msg.contains('bloqueada') || msg.contains('suspended')) {
          errorMessage = 'Esta cuenta no está disponible. Contacta al administrador.';
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

  Future<void> _recoveryPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, ingresa tu correo para enviar el enlace de recuperación.'),
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
          SnackBar(
            content: const Text('Enlace de recuperación enviado al correo registrado.'),
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
                                  color: GodfatherTheme.primaryGold.withValues(alpha: 0.35),
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
                              decoration: BoxDecoration(
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
                                            return Icon(
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
                      fontSize: 42,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mantén tus finanzas personales y del hogar bajo control',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: GodfatherTheme.textLight.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón "Continuar con Google" (Alto contraste, grande y accesible para adultos mayores)
                  ElevatedButton.icon(
                    key: const Key('google_signin_button'),
                    onPressed: _isLoading ? null : _loginWithGoogle,
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
                  const SizedBox(height: 16),
                  
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
                          'También puedes ingresar con correo y contraseña',
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
                  const SizedBox(height: 18),
                  
                  // Campo de Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: GodfatherTheme.primaryGold,
                            ),
                            child: Checkbox(
                              value: _rememberEmail,
                              activeColor: GodfatherTheme.primaryGold,
                              checkColor: Colors.black,
                              onChanged: (val) {
                                setState(() => _rememberEmail = val ?? false);
                              },
                            ),
                          ),
                          Text(
                            'Recordar correo',
                            style: TextStyle(color: GodfatherTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: GodfatherTheme.primaryGold,
                            ),
                            child: Checkbox(
                              value: _keepMeLoggedIn,
                              activeColor: GodfatherTheme.primaryGold,
                              checkColor: Colors.black,
                              onChanged: (val) {
                                setState(() => _keepMeLoggedIn = val ?? false);
                              },
                            ),
                          ),
                          Text(
                            'Mantener sesión',
                            style: TextStyle(color: GodfatherTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Olvidé mi contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _recoveryPassword,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: GodfatherTheme.primaryGold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Botón Iniciar Sesión
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? SizedBox(
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Acceso Directo concedido. Ingresando en modo desarrollador.'),
                          backgroundColor: GodfatherTheme.primaryGold,
                          duration: const Duration(seconds: 1),
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
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Registrarse
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Nuevo en la familia?',
                        style: TextStyle(color: GodfatherTheme.textLight, fontSize: 17),
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
                        child: Text(
                          'Regístrate aquí',
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
    );
  }
}
