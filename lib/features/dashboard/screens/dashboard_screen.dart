import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/transaction.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';
import '../../reports/screens/reports_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTabIndex = 0; // 0: Dashboard, 1: Gastos Personales, 2: Gastos de Casa, 3: Reportes
  bool _showSelection = false; // Controla si se muestran las tarjetas GASTE/ABONE o el botón AGREGAR GASTO
  
  // Animaciones para las transiciones
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  // Timer para la hora en tiempo real del header
  late Timer _timer;
  String _currentTimeString = '';
  String _localBypassName = 'DON CORLEONE';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateDateTime());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateDateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    // Formatear: VIE. 29 MAYO 12:27 PM
    final dayName = DateFormat('EEE', 'es_PE').format(now).toUpperCase().replaceAll('.', '');
    final dayNum = now.day;
    final monthName = DateFormat('MMMM', 'es_PE').format(now).toUpperCase();
    final timeStr = DateFormat('h:mm a', 'es_PE').format(now).toUpperCase();
    
    setState(() {
      _currentTimeString = '$dayName. $dayNum $monthName $timeStr';
    });
  }

  void _openAddTransaction(TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTransactionSheet(defaultType: type),
    ).then((_) {
      // Regresar al botón principal después de guardar
      setState(() => _showSelection = false);
    });
  }

  // Abre el selector de presupuesto mensual
  void _showConfigureBudgetDialog(double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GodfatherTheme.surfaceDark,
          title: Text(
            'LÍMITE DE CAJA CHICA',
            style: GoogleFonts.cinzel(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Establece el tope de gastos personales del mes. El Padrino vigilará este límite.',
                style: TextStyle(color: GodfatherTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Monto Límite (S/.)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: GodfatherTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newLimit = double.tryParse(controller.text.trim());
                if (newLimit != null && newLimit >= 0) {
                  await ref.read(budgetProvider.notifier).setBudget(newLimit);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('GUARDAR'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final profileAsync = ref.read(profileProvider);
    final user = ref.read(currentUserProvider);
    
    // Si no hay sesión o perfil, usaremos valores simulados para bypass
    final currentName = profileAsync.value?.fullName ?? _localBypassName;
    final currentEmail = profileAsync.value?.email ?? user?.email ?? 'invitado@corleone.com';
    
    final nameController = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GodfatherTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GodfatherTheme.primaryGold, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.manage_accounts, color: GodfatherTheme.primaryGold),
              const SizedBox(width: 10),
              Text(
                'PERFIL DEL CLAN',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edita los datos del consejero. Recuerda mantener tus finanzas bajo estricto honor.',
                style: TextStyle(color: GodfatherTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              
              // Campo Nombre Completo
              TextField(
                controller: nameController,
                style: const TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person_outline, color: GodfatherTheme.primaryGold),
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo Correo Electrónico (Solo Lectura)
              TextField(
                controller: TextEditingController(text: currentEmail),
                enabled: false,
                style: const TextStyle(color: GodfatherTheme.textMuted),
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico (Fijo)',
                  prefixIcon: const Icon(Icons.email_outlined, color: GodfatherTheme.textMuted),
                  fillColor: const Color(0xFF131316),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: GodfatherTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;
                
                try {
                  if (user != null) {
                    // Si está autenticado con Supabase, guardar en BD
                    await ref.read(profileProvider.notifier).updateProfile(newName);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perfil de Supabase sincronizado con éxito, Don Corleone.'),
                          backgroundColor: GodfatherTheme.successGreen,
                        ),
                      );
                    }
                  } else {
                    // Modo Bypass: Simulación en caliente para desarrollo
                    setState(() {
                      _localBypassName = newName;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perfil de desarrollador actualizado con éxito.'),
                          backgroundColor: GodfatherTheme.primaryGold,
                        ),
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar perfil: $e'),
                        backgroundColor: GodfatherTheme.alertRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('GUARDAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final budgetAsync = ref.watch(budgetProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: transactionsAsync.maybeWhen(
        data: (transactions) {
          final profileVal = ref.watch(profileProvider).value;
          final nameToShow = (profileVal?.fullName != null && profileVal!.fullName.trim().isNotEmpty)
              ? profileVal.fullName.toUpperCase()
              : _localBypassName.toUpperCase();
          return _buildDrawer(
            context,
            budgetAsync.value?.limitAmount ?? 200.0,
            transactions,
            nameToShow,
          );
        },
        orElse: () => null,
      ),
      backgroundColor: GodfatherTheme.backgroundBlack,
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(GodfatherTheme.primaryGold)),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error al cargar datos: $err',
              style: const TextStyle(color: GodfatherTheme.alertRed),
            ),
          ),
          data: (transactions) {
            final budgetLimit = budgetAsync.value?.limitAmount ?? 200.0;
            final now = DateTime.now();

            // Filtrar transacciones del mes
            final currentMonthTransactions = transactions.where((tx) {
              return tx.createdAt.month == now.month && tx.createdAt.year == now.year;
            }).toList();

            // Cálculos
            final personalExpenses = currentMonthTransactions
                .where((tx) => tx.targetModule == TargetModule.personal && tx.transactionType == TransactionType.gasto)
                .fold(0.0, (sum, tx) => sum + tx.amount);

            final houseIncomes = currentMonthTransactions
                .where((tx) => tx.targetModule == TargetModule.casa && tx.transactionType == TransactionType.abono)
                .fold(0.0, (sum, tx) => sum + tx.amount);

            final houseExpenses = currentMonthTransactions
                .where((tx) => tx.targetModule == TargetModule.casa && tx.transactionType == TransactionType.gasto)
                .fold(0.0, (sum, tx) => sum + tx.amount);

            final houseBalance = houseIncomes - houseExpenses;

            return Column(
              children: [
                // 1. HEADER (MOCKUP IDÉNTICO)
                _buildHeader(budgetLimit, personalExpenses),

                // 2. CONTENIDO PRINCIPAL (SWAP DE TABS)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildTabContent(
                          tabIndex: _currentTabIndex,
                          transactions: transactions,
                          personalExpenses: personalExpenses,
                          budgetLimit: budgetLimit,
                          houseIncomes: houseIncomes,
                          houseExpenses: houseExpenses,
                          houseBalance: houseBalance,
                        ),
                      );
                    },
                  ),
                ),

                // 3. BARRA DE NAVEGACIÓN INFERIOR PREMIUM NOIR
                _buildBottomNavigationBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  // HEADER DE DISEÑO IDÉNTICO AL MOCKUP
  Widget _buildHeader(double budgetLimit, double spent) {
    String tabTitle = 'DASHBOARD';
    if (_currentTabIndex == 1) tabTitle = 'GASTOS PERSONALES';
    if (_currentTabIndex == 2) tabTitle = 'GASTOS DE CASA';
    if (_currentTabIndex == 3) tabTitle = 'REPORTES';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: GodfatherTheme.backgroundBlack,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E24), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Fecha y Hora centralizada (VIE. 29 MAYO 12:27 PM)
          Text(
            _currentTimeString,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GodfatherTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hamburguesa de menú dorada
              IconButton(
                icon: const Icon(Icons.menu, color: GodfatherTheme.primaryGold, size: 24),
                onPressed: () {
                  // Abre el Drawer lateral premium
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              // Título central
              Text(
                tabTitle,
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: GodfatherTheme.primaryGold,
                  letterSpacing: 2.0,
                ),
              ),
              // Engrane de ajustes dorado
              IconButton(
                icon: const Icon(Icons.settings, color: GodfatherTheme.primaryGold, size: 24),
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
          // Subtítulo nítido
          Text(
            'Caja Chica: ${spent.toStringAsFixed(0)}/${budgetLimit.toStringAsFixed(0)} Soles',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GodfatherTheme.primaryGold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // SWITCH DE VISTAS SEGÚN EL TAB SELECCIONADO
  Widget _buildTabContent({
    required int tabIndex,
    required List<Transaction> transactions,
    required double personalExpenses,
    required double budgetLimit,
    required double houseIncomes,
    required double houseExpenses,
    required double houseBalance,
  }) {
    switch (tabIndex) {
      case 0:
        return _buildDashboardView(personalExpenses, budgetLimit);
      case 1:
        return _buildPersonalExpensesView(personalExpenses, budgetLimit, transactions);
      case 2:
        return _buildHouseExpensesView(houseIncomes, houseExpenses, houseBalance, transactions);
      case 3:
        return const ReportsScreen();
      default:
        return _buildDashboardView(personalExpenses, budgetLimit);
    }
  }

  // TAB 0: EL DASHBOARD CON EL AVATAR Y EL FLUJO DE INTERACCIÓN MOCKUP
  Widget _buildDashboardView(double personalExpenses, double budgetLimit) {
    return Column(
      children: [
        const SizedBox(height: 36),
        // RETRATO DEL AVATAR CON ANILLO DE ORO METÁLICO Y PULIDO
        Center(
          child: Column(
            children: [
              // Contenedor del retrato con etiqueta "ASISTENTE"
              Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  // Anillo de oro metálico pulido y lujoso (30% más grande, 224x224)
                  Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: GodfatherTheme.primaryGold.withOpacity(0.35),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF5D77F), // Oro brillante
                          Color(0xFFD4AF37), // Oro metálico
                          Color(0xFF996515), // Bronce/Oro viejo
                          Color(0xFFF3E5AB), // Oro claro
                          Color(0xFFB8860B), // Oro oscuro
                          Color(0xFFD4AF37), // Oro metálico
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(5.0), // Grosor del anillo exterior
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: GodfatherTheme.backgroundBlack, // Borde negro carbón de separación
                      ),
                      padding: const EdgeInsets.all(3.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF996515),
                              Color(0xFFD4AF37),
                              Color(0xFFF5D77F),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(2.0), // Anillo de brillo interno
                        child: ClipOval(
                          child: Container(
                            color: Colors.black, // Fondo negro sólido obligatorio para evitar cuadrículas transparentes
                            child: Transform.scale(
                              scale: 1.38, // Escala 1.38x para recortar y ocultar la franja de cuadrícula transparente exterior
                              child: Image.asset(
                                'assets/images/godfather_asistente.jpg', // Carga primero el JPG para evitar cuadrícula transparente del PNG
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/godfather_asistente.png', // Fallback al PNG
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 110,
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
                  // Etiqueta superior dorada "ASISTENTE"
                  Positioned(
                    top: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                      decoration: BoxDecoration(
                        color: GodfatherTheme.primaryGold,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'ASISTENTE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Subtítulo no duplicado elegante y nítido en oro brillante
              Text(
                'CONSEJERO DE LA FAMILIA',
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GodfatherTheme.primaryGold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),

        // INTERACCIÓN DE BOTONES (AGREGAR GASTO VS GASTE/ABONE)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: !_showSelection
              ? _buildSingleAddButton()
              : _buildDualCardSelection(),
        ),

        const Spacer(flex: 2),
      ],
    );
  }

  // BOTÓN INICIAL "AGREGAR GASTO" (GIANT CIRCULAR BUTTON CON DOUBLE BORDER Y GRADIENTE METÁLICO)
  Widget _buildSingleAddButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showSelection = true;
          });
        },
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: GodfatherTheme.primaryGold.withOpacity(0.35),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF3E5AB),
                Color(0xFFD4AF37),
                Color(0xFF996515),
                Color(0xFFF5D77F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(4.5), // Anillo exterior
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: GodfatherTheme.backgroundBlack,
            ),
            padding: const EdgeInsets.all(3.0),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D0D10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AGREGAR',
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: GodfatherTheme.primaryGold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GASTO',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: GodfatherTheme.primaryGold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'U ABONO',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: GodfatherTheme.primaryGold,
                        letterSpacing: 1.5,
                      ),
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

  // VISTA DE SELECCIÓN CON DOS TARJETAS (GASTE / ABONE) Y BOTÓN VOLVER
  Widget _buildDualCardSelection() {
    return Column(
      key: const ValueKey('selection_view'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TARJETA DE GASTO ("GASTO")
            _buildSelectionCard(
              title: 'GASTO',
              assetPath: 'assets/images/godfather_knife.png', // Caricatura del Padrino con Cuchillo
              fallbackIcon: Icons.remove,
              borderColor: GodfatherTheme.alertRed,
              onTap: () => _openAddTransaction(TransactionType.gasto),
            ),
            const SizedBox(width: 24),
            // TARJETA DE ABONO ("ABONE")
            _buildSelectionCard(
              title: 'ABONE',
              assetPath: 'assets/images/godfather_abone.png', // Caricatura del Padrino con Mano Abierta (Sticker Transparente)
              fallbackIcon: Icons.add,
              borderColor: GodfatherTheme.successGreen,
              onTap: () => _openAddTransaction(TransactionType.abono),
            ),
          ],
        ),
        const SizedBox(height: 36),
        // BOTÓN VOLVER ENORME Y PERFECTAMENTE VISIBLE
        GestureDetector(
          onTap: () {
            setState(() {
              _showSelection = false;
            });
          },
          child: Container(
            width: 96, // 96x96px
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B0B0B),
              border: Border.all(
                color: GodfatherTheme.primaryGold, // Solid Gold Border
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: GodfatherTheme.primaryGold.withOpacity(0.18),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'VOLVER',
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: GodfatherTheme.primaryGold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // CONSTRUCTOR DE TARJETA DE SELECCIÓN DE ALTA FIDELIDAD SIN ERRORES DE RECORTE Y SIN SUBTÍTULOS SECUNDARIOS
  Widget _buildSelectionCard({
    required String title,
    required String assetPath,
    required IconData fallbackIcon,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165, // Enlarge card width
        height: 210, // Proporción áurea perfecta sin subtítulo
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF121215), // Solid background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GodfatherTheme.primaryGold.withOpacity(0.85),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ilustración del sticker superior sin ClipOval para evitar errores de recorte
            Container(
              width: 125, // Enlarge sticker box size for premium visual fidelity
              height: 125,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain, // Muestra el sticker completo y nítido
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: borderColor.withOpacity(0.15),
                      ),
                      child: Icon(fallbackIcon, size: 36, color: borderColor),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            // Título "GASTO" / "ABONE"
            Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: GodfatherTheme.primaryGold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: DETALLE DE GASTOS PERSONALES (CAJA CHICA)
  Widget _buildPersonalExpensesView(double spent, double limit, List<Transaction> transactions) {
    final personalTxs = transactions.where((tx) => tx.targetModule == TargetModule.personal).toList();
    final spentPercentage = limit > 0 ? (spent / limit) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de Presupuesto
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2C2C30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CAJA CHICA PERSONAL',
                        style: TextStyle(fontWeight: FontWeight.bold, color: GodfatherTheme.primaryGold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: GodfatherTheme.textMuted),
                        onPressed: () => _showConfigureBudgetDialog(limit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'S/. ${spent.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: spentPercentage >= 1.0 ? GodfatherTheme.alertRed : GodfatherTheme.textLight,
                        ),
                      ),
                      Text('Límite: S/. ${limit.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: spentPercentage.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: const Color(0xFF232328),
                      valueColor: AlwaysStoppedAnimation(
                        spentPercentage >= 1.0 ? GodfatherTheme.alertRed : GodfatherTheme.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'HISTORIAL PERSONAL',
            style: GoogleFonts.cinzel(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          if (personalTxs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36.0),
              child: Text(
                'Sin movimientos registrados en tu caja chica.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GodfatherTheme.textMuted, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: personalTxs.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF232328)),
              itemBuilder: (context, index) {
                final tx = personalTxs[index];
                final isExpense = tx.transactionType == TransactionType.gasto;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                  ),
                  title: Text(tx.concept, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(tx.category, style: const TextStyle(fontSize: 11, color: GodfatherTheme.textMuted)),
                  trailing: Text(
                    '${isExpense ? "-" : "+"} S/. ${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 2: DETALLE DE GASTOS DE LA CASA
  Widget _buildHouseExpensesView(double income, double expenses, double balance, List<Transaction> transactions) {
    final houseTxs = transactions.where((tx) => tx.targetModule == TargetModule.casa).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de balance
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2C2C30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'BALANCE INTELIGENTE DE CASA',
                    style: TextStyle(fontWeight: FontWeight.bold, color: GodfatherTheme.primaryGold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Abonos (Familia)', style: TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            'S/. ${income.toStringAsFixed(2)}',
                            style: const TextStyle(color: GodfatherTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Servicios Pagados', style: TextStyle(fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            'S/. ${expenses.toStringAsFixed(2)}',
                            style: const TextStyle(color: GodfatherTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFF2C2C30)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo Restante', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'S/. ${balance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: balance >= 0 ? GodfatherTheme.primaryGold : GodfatherTheme.alertRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'HISTORIAL COMPARTIDO DE CASA',
            style: GoogleFonts.cinzel(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          if (houseTxs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36.0),
              child: Text(
                'Sin movimientos registrados en los gastos compartidos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GodfatherTheme.textMuted, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: houseTxs.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF232328)),
              itemBuilder: (context, index) {
                final tx = houseTxs[index];
                final isExpense = tx.transactionType == TransactionType.gasto;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                  ),
                  title: Text(tx.concept, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(tx.category, style: const TextStyle(fontSize: 11, color: GodfatherTheme.textMuted)),
                  trailing: Text(
                    '${isExpense ? "-" : "+"} S/. ${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION BAR PERSONALIZADO IDÉNTICO AL DEL MOCKUP
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: GodfatherTheme.backgroundBlack,
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E24), width: 1.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
            // Ocultar la selección si cambiamos de tab
            _showSelection = false;
          });
          _fadeController.reset();
          _fadeController.forward();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: GodfatherTheme.backgroundBlack,
        selectedItemColor: GodfatherTheme.primaryGold,
        unselectedItemColor: GodfatherTheme.textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, color: GodfatherTheme.primaryGold),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: GodfatherTheme.primaryGold),
            label: 'Gastos Personales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: GodfatherTheme.primaryGold),
            label: 'Gastos de Casa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart, color: GodfatherTheme.primaryGold),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }

  // NAVIGATION DRAWER ULTRA-PREMIUM Noir/Gold
  Widget _buildDrawer(BuildContext context, double budgetLimit, List<Transaction> transactions, String profileName) {
    final now = DateTime.now();
    final personalExpenses = transactions.where((tx) {
      return tx.targetModule == TargetModule.personal &&
             tx.transactionType == TransactionType.gasto &&
             tx.createdAt.month == now.month &&
             tx.createdAt.year == now.year;
    }).fold(0.0, (sum, tx) => sum + tx.amount);

    return Drawer(
      child: Container(
        color: GodfatherTheme.backgroundBlack, // Puro #0B0B0B
        child: Column(
          children: [
            // Drawer Header de Lujo
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 24, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D10),
                border: Border(
                  bottom: BorderSide(color: GodfatherTheme.primaryGold, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  // Mini Avatar del Padrino
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: GodfatherTheme.primaryGold, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: GodfatherTheme.primaryGold.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/godfather_asistente.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/godfather_asistente.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, color: GodfatherTheme.primaryGold, size: 30);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileName,
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: GodfatherTheme.primaryGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consejero de Finanzas',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: GodfatherTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Caja Chica: S/. ${personalExpenses.toStringAsFixed(0)} / ${budgetLimit.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: GodfatherTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Drawer Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: 'DASHBOARD',
                    isSelected: _currentTabIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentTabIndex = 0;
                        _showSelection = false;
                      });
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'CAJA CHICA',
                    subtitle: 'Gastos Personales',
                    isSelected: _currentTabIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentTabIndex = 1;
                        _showSelection = false;
                      });
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'GASTOS DE CASA',
                    subtitle: 'Servicios de la Familia',
                    isSelected: _currentTabIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentTabIndex = 2;
                        _showSelection = false;
                      });
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.pie_chart,
                    title: 'REPORTES',
                    subtitle: 'Análisis Mensual',
                    isSelected: _currentTabIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentTabIndex = 3;
                        _showSelection = false;
                      });
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(color: Color(0xFF1E1E24)),
                  ),
                  _buildDrawerItem(
                    icon: Icons.edit,
                    title: 'LIMITAR CAJA CHICA',
                    subtitle: 'Ajuste de tope familiar',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showConfigureBudgetDialog(budgetLimit);
                    },
                  ),
                ],
              ),
            ),
            
            // Bottom Sign Out
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1E1E24), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GodfatherTheme.primaryGold,
                    foregroundColor: GodfatherTheme.backgroundBlack,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(
                    'CERRAR SESIÓN',
                    style: GoogleFonts.cinzel(fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final client = ref.read(supabaseClientProvider);
                    await client.auth.signOut();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? GodfatherTheme.primaryGold.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: GodfatherTheme.primaryGold.withOpacity(0.3), width: 1) : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.textMuted,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.textLight,
            letterSpacing: 1,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: GodfatherTheme.textMuted,
                ),
              )
            : null,
        trailing: isSelected
            ? const Icon(Icons.chevron_right, color: GodfatherTheme.primaryGold, size: 16)
            : null,
      ),
    );
  }
}
