// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/transaction.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';
import '../../transactions/widgets/edit_transaction_sheet.dart';
import '../../reports/screens/reports_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/family_settings_sheet.dart';
import '../widgets/notification_sheet.dart';
import '../../transactions/screens/bcp_inbox_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTabIndex = 0; // 0: Dashboard, 1: Gastos Personales, 2: Gastos de Casa, 3: Reportes
  DateTime _selectedDate = DateTime.now(); // Controla el mes seleccionado en la app

  
  // Animaciones para las transiciones
  late AnimationController _fadeController;

  // Timer para la hora en tiempo real del header
  late Timer _timer;
  String _currentTimeString = '';
  String _localBypassName = 'DON CORLEONE';

  final List<String> _aboneImages = [
    'assets/images/FINAL/01.png',
    'assets/images/FINAL/02.png',
    'assets/images/FINAL/03.png',
  ];

  final List<String> _gastoImages = [
    'assets/images/FINAL/04.png',
    'assets/images/FINAL/05.png',
    'assets/images/FINAL/06.png',
  ];

  late String _currentGastoImagePath;
  late String _currentAboneImagePath;

  @override
  void initState() {
    super.initState();
    _currentGastoImagePath = _gastoImages[0];
    _currentAboneImagePath = _aboneImages[0];
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateDateTime());



    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );


    _fadeController.forward();
  }

  @override
  void dispose() {
    _timer.cancel();
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
    );
  }

  void _openEditTransaction(Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditTransactionSheet(transaction: tx),
    );
  }

  void _deleteTransaction(Transaction tx) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: GodfatherTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GodfatherTheme.primaryGold, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: GodfatherTheme.alertRed, size: 28),
            const SizedBox(width: 10),
            Text(
              'ELIMINAR MOVIMIENTO',
              style: GoogleFonts.cinzel(
                color: GodfatherTheme.alertRed,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este movimiento: "${tx.concept}"?',
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
                      await ref.read(transactionProvider.notifier).softDeleteTransaction(tx.id, tx.familyId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Movimiento eliminado con éxito.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: GodfatherTheme.successGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al eliminar: $e'),
                            backgroundColor: GodfatherTheme.alertRed,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'ELIMINAR',
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
              Text(
                'Establece el tope de gastos personales del mes. El Padrino vigilará este límite.',
                style: TextStyle(color: GodfatherTheme.textLight.withValues(alpha: 0.85), fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Monto Límite (S/.)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCELAR', style: TextStyle(color: GodfatherTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newLimit = double.tryParse(controller.text.trim());
                if (newLimit != null && newLimit >= 0) {
                  await ref.read(budgetProvider.notifier).setBudget(newLimit);
                  if (context.mounted) Navigator.pop(context);
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
            side: BorderSide(color: GodfatherTheme.primaryGold, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.manage_accounts, color: GodfatherTheme.primaryGold),
              const SizedBox(width: 10),
              Text(
                'PERFIL DE LA FAMILIA',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Aumentado
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edita los datos del consejero. Recuerda mantener tus finanzas bajo estricto honor.',
                style: TextStyle(color: GodfatherTheme.textLight.withValues(alpha: 0.85), fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // Campo Nombre Completo
              Text(
                'Nombre completo',
                style: TextStyle(
                  color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: TextStyle(color: GodfatherTheme.textLight, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Ej. Don Corleone',
                  prefixIcon: Icon(Icons.person_outline, color: GodfatherTheme.primaryGold),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo Correo Electrónico (Solo Lectura)
              Text(
                'Correo electrónico',
                style: TextStyle(
                  color: GodfatherTheme.isDarkMode ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: currentEmail),
                enabled: false,
                style: TextStyle(
                  color: GodfatherTheme.isDarkMode ? const Color(0xFFD0D0D0) : const Color(0xFF4A4A4A),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'invitado@corleone.com',
                  prefixIcon: Icon(Icons.mail_outline, color: GodfatherTheme.primaryGold),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  fillColor: GodfatherTheme.isDarkMode ? Colors.black38 : const Color(0xFFEFECE6),
                  filled: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Perfil de desarrollador actualizado con éxito.'),
                        backgroundColor: GodfatherTheme.primaryGold,
                      ),
                    );
                    }
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
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

  void _changeGastoImage() {
    final available = _gastoImages.where((img) => img != _currentGastoImagePath).toList();
    final random = DateTime.now().millisecond % available.length;
    setState(() {
      _currentGastoImagePath = available[random];
    });
  }

  void _changeAboneImage() {
    final available = _aboneImages.where((img) => img != _currentAboneImagePath).toList();
    final random = DateTime.now().millisecond % available.length;
    setState(() {
      _currentAboneImagePath = available[random];
    });
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        color: GodfatherTheme.backgroundBlack,
        child: SafeArea(
          child: transactionsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(GodfatherTheme.primaryGold)),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error al cargar datos: $err',
                style: TextStyle(color: GodfatherTheme.alertRed),
              ),
            ),
            data: (transactions) {
              final budgetLimit = budgetAsync.value?.limitAmount ?? 200.0;

              // Filtrar transacciones del mes seleccionado
              final currentMonthTransactions = transactions.where((tx) {
                return tx.createdAt.month == _selectedDate.month && tx.createdAt.year == _selectedDate.year;
              }).toList();

              // Cálculos del mes seleccionado (usando valores absolutos)
              final personalExpenses = currentMonthTransactions
                  .where((tx) => tx.targetModule == TargetModule.personal && tx.transactionType == TransactionType.gasto)
                  .fold(0.0, (sum, tx) => sum + tx.amount.abs());

              return Column(
                children: [
                  // 1. HEADER (MOCKUP IDÉNTICO)
                  _buildHeader(budgetLimit, personalExpenses),

                  // 2. CONTENIDO PRINCIPAL (SWAP DE TABS)
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final isOutgoing = animation.status == AnimationStatus.reverse ||
                                                 animation.status == AnimationStatus.dismissed;
                              return IgnorePointer(
                                ignoring: isOutgoing,
                                child: child,
                              );
                            },
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentTabIndex),
                        child: _buildTabContent(
                          tabIndex: _currentTabIndex,
                          transactions: transactions,
                          budgetLimit: budgetLimit,
                        ),
                      ),
                    ),
                  ),

                // 3. BARRA DE NAVEGACIÓN INFERIOR PREMIUM NOIR
                _buildBottomNavigationBar(),
              ],
            );
          },
        ),
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
      decoration: BoxDecoration(
        color: GodfatherTheme.backgroundBlack,
        border: Border(
          bottom: BorderSide(color: GodfatherTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Fecha y Hora centralizada (VIE. 29 MAYO 12:27 PM)
          Text(
            _currentTimeString,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GodfatherTheme.textLight.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hamburguesa de menú dorada
              IconButton(
                icon: Icon(RemixIcons.menu_fill, color: GodfatherTheme.primaryGold, size: 24),
                onPressed: () {
                  // Abre el Drawer lateral premium
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              // Título central
              Text(
                tabTitle,
                style: GoogleFonts.cinzel(
                  fontSize: 25, // Aumentado para mayor visibilidad
                  fontWeight: FontWeight.w800,
                  color: GodfatherTheme.primaryGold,
                  letterSpacing: 2.0,
                ),
              ),
              // Theme Toggle button next to Settings engrane
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? RemixIcons.sun_fill
                          : RemixIcons.moon_fill,
                      color: GodfatherTheme.primaryGold,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final notificationsAsync = ref.watch(notificationProvider);
                      final unreadCount = notificationsAsync.value?.where((n) => !n.read).length ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(RemixIcons.notification_4_fill, color: GodfatherTheme.primaryGold, size: 24),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const NotificationSheet(),
                              );
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(RemixIcons.settings_fill, color: GodfatherTheme.primaryGold, size: 24),
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
            ],
          ),
          // Subtítulo nítido
          Text(
            'Caja Chica: ${spent.toStringAsFixed(0)}/${budgetLimit.toStringAsFixed(0)} Soles',
            style: GoogleFonts.inter(
              fontSize: 15, // Aumentado
              fontWeight: FontWeight.w700,
              color: GodfatherTheme.primaryGold,
              letterSpacing: 0.5,
            ),
          ),
          if (_currentTabIndex != 0) ...[
            const SizedBox(height: 12),
            _buildMonthSelector(),
          ],
        ],
      ),
    );
  }

  // Bar de meses en cápsulas estilizadas
  Widget _buildMonthSelector() {
    final List<MapEntry<int, String>> months = const [
      MapEntry(1, 'Ene'),
      MapEntry(2, 'Feb'),
      MapEntry(3, 'Mar'),
      MapEntry(4, 'Abr'),
      MapEntry(5, 'May'),
      MapEntry(6, 'Jun'),
      MapEntry(7, 'Jul'),
      MapEntry(8, 'Ago'),
      MapEntry(9, 'Sep'),
      MapEntry(10, 'Oct'),
      MapEntry(11, 'Nov'),
      MapEntry(12, 'Dic'),
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, index) {
          final entry = months[index];
          final isSelected = _selectedDate.month == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(entry.value.toUpperCase()),
              selected: isSelected,
              selectedColor: GodfatherTheme.primaryGold.withValues(alpha: 0.25),
              backgroundColor: GodfatherTheme.surfaceDarkAlt,
              labelStyle: TextStyle(
                color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.textLight.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              side: BorderSide(
                color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (selected) {
                if (selected) {
                   setState(() {
                     _selectedDate = DateTime(_selectedDate.year, entry.key, 1);
                   });
                }
              },
            ),
          );
        },
      ),
    );
  }

  // SWITCH DE VISTAS SEGÚN EL TAB SELECCIONADO
  Widget _buildTabContent({
    required int tabIndex,
    required List<Transaction> transactions,
    required double budgetLimit,
  }) {
    switch (tabIndex) {
      case 0:
        final personalExpenses = transactions
            .where((tx) =>
                tx.targetModule == TargetModule.personal &&
                tx.transactionType == TransactionType.gasto &&
                tx.createdAt.month == _selectedDate.month &&
                tx.createdAt.year == _selectedDate.year)
            .fold(0.0, (sum, tx) => sum + tx.amount.abs());
        return _buildDashboardView(personalExpenses, budgetLimit);
      case 1:
        return _buildPersonalExpensesView(budgetLimit, transactions);
      case 2:
        return _buildHouseExpensesView(transactions);
      case 3:
        return const ReportsScreen();
      default:
        final personalExpenses = transactions
            .where((tx) =>
                tx.targetModule == TargetModule.personal &&
                tx.transactionType == TransactionType.gasto &&
                tx.createdAt.month == _selectedDate.month &&
                tx.createdAt.year == _selectedDate.year)
            .fold(0.0, (sum, tx) => sum + tx.amount.abs());
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
                          color: GodfatherTheme.primaryGold.withValues(alpha: 0.35),
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
                      decoration: BoxDecoration(
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
                                      return Icon(
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
                          fontSize: 14,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GodfatherTheme.primaryGold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),

        // INTERACCIÓN DE BOTONES (GASTO Y ABONE DIRECTAMENTE)
        _buildDualCardSelection(),

        const Spacer(flex: 2),
      ],
    );
  }


  // VISTA DE SELECCIÓN CON DOS TARJETAS (GASTE / ABONE) Y BOTÓN VOLVER
  Widget _buildDualCardSelection() {
    return Column(
      key: const ValueKey('selection_view'),
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TARJETA DE GASTO ("GASTO")
              _buildSelectionCard(
                title: 'GASTO',
                assetPath: _currentGastoImagePath,
                fallbackIcon: Icons.remove,
                borderColor: GodfatherTheme.alertRed,
                onTap: () {
                  _changeGastoImage();
                  _openAddTransaction(TransactionType.gasto);
                },
              ),
              const SizedBox(width: 16),
              // TARJETA DE ABONO ("ABONE")
              _buildSelectionCard(
                title: 'ABONE',
                assetPath: _currentAboneImagePath,
                fallbackIcon: Icons.add,
                borderColor: GodfatherTheme.successGreen,
                onTap: () {
                  _changeAboneImage();
                  _openAddTransaction(TransactionType.abono);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // BOTÓN VOLVER ENORME Y PERFECTAMENTE VISIBLE
        GestureDetector(
          onTap: () {
            // Randomiza las imágenes de los personajes para un toque interactivo
            _changeGastoImage();
            _changeAboneImage();
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
                  color: GodfatherTheme.primaryGold.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'VOLVER',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 235, // Enlarge card width to 235px (approx. 30% increase)
        height: 320, // Enlarge card height to 320px to fit larger sticker comfortably
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: const BoxDecoration(
          color: Colors.transparent, // Totalmente transparente sin bordes ni sombras adicionales
        ),
        child: Column(
          children: [
            Container(
              width: 230, // Enlarge sticker box size by over 50% (from 150 to 230) for giant visual impact
              height: 230,
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
                        color: borderColor.withValues(alpha: 0.15),
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
                fontSize: 21, // Aumentado
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
  Widget _buildPersonalExpensesView(double limit, List<Transaction> transactions) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? 'guest-user-id';

    // Filter personal transactions of the selected month (private)
    final personalTxs = transactions.where((tx) {
      return tx.targetModule == TargetModule.personal &&
             tx.userId == currentUserId &&
             tx.createdAt.month == _selectedDate.month &&
             tx.createdAt.year == _selectedDate.year;
    }).toList();

    // Calculations
    final personalExpenses = personalTxs
        .where((tx) => tx.transactionType == TransactionType.gasto)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    final personalIncomes = personalTxs
        .where((tx) => tx.transactionType == TransactionType.abono)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    // Balance/Disponible
    final disponible = (limit + personalIncomes - personalExpenses).clamp(0.0, double.infinity);
    final spentPercentage = limit > 0 ? (personalExpenses / limit) : 0.0;

    final isWide = MediaQuery.of(context).size.width > 900;

    final budgetCard = Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: GodfatherTheme.borderColor),
      ),
      color: GodfatherTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CAJA CHICA PERSONAL',
                  style: TextStyle(fontWeight: FontWeight.bold, color: GodfatherTheme.primaryGold, fontSize: 22),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 24, color: GodfatherTheme.primaryGold),
                  onPressed: () => _showConfigureBudgetDialog(limit),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Gastos del mes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gastos del mes:', style: TextStyle(fontSize: 18, color: GodfatherTheme.textLight)),
                Text(
                  'S/. ${personalExpenses.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: spentPercentage >= 1.0 ? GodfatherTheme.alertRed : GodfatherTheme.textLight,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Caja chica consumida
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Caja chica consumida:', style: TextStyle(fontSize: 18, color: GodfatherTheme.textLight)),
                Text(
                  'S/. ${personalExpenses.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: spentPercentage >= 1.0 ? GodfatherTheme.alertRed : GodfatherTheme.textLight,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Límite de caja chica
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Límite de caja chica:', style: TextStyle(fontSize: 18, color: GodfatherTheme.textLight)),
                Text(
                  'S/. ${limit.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: GodfatherTheme.textLight,
                    fontSize: 24,
                  ),
                ),
              ],
            ),

            Divider(height: 32, color: GodfatherTheme.borderColor),

            // Saldo disponible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo disponible:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: GodfatherTheme.textLight)),
                Text(
                  'S/. ${disponible.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: disponible > 0 ? GodfatherTheme.successGreen : GodfatherTheme.alertRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: spentPercentage.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: GodfatherTheme.surfaceDarkAlt,
                valueColor: AlwaysStoppedAnimation(
                  spentPercentage >= 1.0 ? GodfatherTheme.alertRed : GodfatherTheme.primaryGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final historyList = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HISTORIAL PERSONAL',
          style: GoogleFonts.cinzel(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 18),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final isOutgoing = animation.status == AnimationStatus.reverse ||
                                     animation.status == AnimationStatus.dismissed;
                  return IgnorePointer(
                    ignoring: isOutgoing,
                    child: child,
                  );
                },
                child: child,
              ),
            );
          },
          child: personalTxs.isEmpty
              ? Padding(
                  key: ValueKey<String>('empty_personal_hist_${_selectedDate.month}'),
                  padding: const EdgeInsets.symmetric(vertical: 36.0),
                  child: Text(
                    'Sin movimientos registrados en tu caja chica.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: GodfatherTheme.textMuted, fontStyle: FontStyle.italic, fontSize: 18),
                  ),
                )
              : ListView.separated(
                  key: ValueKey<String>('list_personal_hist_${_selectedDate.month}_${personalTxs.length}'),
                  shrinkWrap: true,
                  physics: isWide ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
                  itemCount: personalTxs.length,
                  separatorBuilder: (context, index) => Divider(color: GodfatherTheme.borderColor),
                  itemBuilder: (context, index) {
                    final tx = personalTxs[index];
                    final isExpense = tx.transactionType == TransactionType.gasto;
                    final visuals = GodfatherTheme.getCategoryVisuals(tx.category);
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      constraints: const BoxConstraints(minHeight: 72),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: visuals.bgColor,
                              border: Border.all(
                                color: visuals.color.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              visuals.icon,
                              color: visuals.color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tx.concept,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                    color: GodfatherTheme.textLight,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tx.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: GodfatherTheme.textLight.withValues(alpha: 0.8),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen).withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  '${isExpense ? "-" : "+"} S/. ${tx.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(RemixIcons.pencil_fill, size: 24),
                                color: GodfatherTheme.primaryGold,
                                onPressed: () => _openEditTransaction(tx),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(RemixIcons.delete_bin_fill, size: 24),
                                color: GodfatherTheme.alertRed,
                                onPressed: () => _deleteTransaction(tx),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: budgetCard,
            ),
          ),
          VerticalDivider(color: GodfatherTheme.borderColor, width: 1),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: historyList,
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          budgetCard,
          const SizedBox(height: 24),
          historyList,
        ],
      ),
    );
  }

  // TAB 2: DETALLE DE GASTOS DE LA CASA
  Widget _buildHouseExpensesView(List<Transaction> transactions) {
    final familiesAsync = ref.watch(familyProvider);
    final selectedFamily = ref.watch(selectedFamilyProvider);

    return familiesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error al cargar familias: $err',
            style: TextStyle(color: GodfatherTheme.alertRed, fontSize: 18),
          ),
        ),
      ),
      data: (families) {
        if (families.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(RemixIcons.home_heart_line, size: 80, color: GodfatherTheme.textMuted),
                const SizedBox(height: 16),
                Text(
                  'No perteneces a ninguna familia compartida.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: GodfatherTheme.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ve a "Administración Familiar" en el menú lateral para crear una nueva familia o unirte usando un código.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GodfatherTheme.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(220, 56),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const FamilySettingsSheet(),
                    );
                  },
                  icon: const Icon(RemixIcons.add_line),
                  label: const Text('ADMINISTRAR FAMILIA'),
                ),
              ],
            ),
          );
        }

        // Active family check
        final activeFamily = selectedFamily ?? families.first;

        // Filter house transactions of the selected month, active family and not soft deleted
        final houseTxs = transactions.where((tx) {
          return tx.targetModule == TargetModule.casa &&
                 tx.familyId == activeFamily.id &&
                 !tx.deleted &&
                 tx.createdAt.month == _selectedDate.month &&
                 tx.createdAt.year == _selectedDate.year;
        }).toList();

        // Calculations (using absolute values to sum correctly)
        final houseExpenses = houseTxs
            .where((tx) => tx.transactionType == TransactionType.gasto)
            .fold(0.0, (sum, tx) => sum + tx.amount.abs());

        final houseIncomes = houseTxs
            .where((tx) => tx.transactionType == TransactionType.abono)
            .fold(0.0, (sum, tx) => sum + tx.amount.abs());

        final houseBalance = houseIncomes - houseExpenses;

        // Count of services pagados
        final servicesCount = houseTxs
            .where((tx) => tx.transactionType == TransactionType.gasto)
            .length;

        final isWide = MediaQuery.of(context).size.width > 900;

        // Family choicechips selector bar
        final familySelector = Container(
          height: 58,
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: families.length,
            itemBuilder: (context, idx) {
              final fam = families[idx];
              final isSelected = activeFamily.id == fam.id;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Text(fam.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: GodfatherTheme.primaryGold.withValues(alpha: 0.25),
                  backgroundColor: GodfatherTheme.surfaceDarkAlt,
                  labelStyle: TextStyle(
                    color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.textLight.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  side: BorderSide(
                    color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.borderColor,
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(selectedFamilyProvider.notifier).state = fam;
                    }
                  },
                ),
              );
            },
          ),
        );

        final balanceCard = Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: GodfatherTheme.borderColor),
          ),
          color: GodfatherTheme.surfaceDark,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BALANCE INTELIGENTE: ${activeFamily.name.toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: GodfatherTheme.primaryGold, fontSize: 20),
                ),
                const SizedBox(height: 20),
                
                // Abonos del mes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Abonos del mes:', style: TextStyle(fontSize: 18, color: GodfatherTheme.textLight)),
                    Text(
                      'S/. ${houseIncomes.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: GodfatherTheme.successGreen,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Gastos del mes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gastos del mes:', style: TextStyle(fontSize: 18, color: GodfatherTheme.textLight)),
                    Text(
                      'S/. ${houseExpenses.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: GodfatherTheme.alertRed,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Servicios pagados count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Servicios pagados:', style: TextStyle(fontSize: 18, color: GodfatherTheme.textLight)),
                    Text(
                      '$servicesCount',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: GodfatherTheme.primaryGold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),

                Divider(height: 32, color: GodfatherTheme.borderColor),

                // Saldo restante
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saldo restante:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: GodfatherTheme.textLight)),
                    Text(
                      '${houseBalance < 0 ? "-" : ""}S/. ${houseBalance.abs().toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: houseBalance >= 0 ? GodfatherTheme.primaryGold : GodfatherTheme.alertRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        final historyList = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'HISTORIAL COMPARTIDO: ${activeFamily.name.toUpperCase()}',
              style: GoogleFonts.cinzel(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 18),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final isOutgoing = animation.status == AnimationStatus.reverse ||
                                         animation.status == AnimationStatus.dismissed;
                      return IgnorePointer(
                        ignoring: isOutgoing,
                        child: child,
                      );
                    },
                    child: child,
                  ),
                );
              },
              child: houseTxs.isEmpty
                  ? Padding(
                      key: ValueKey<String>('empty_house_hist_${_selectedDate.month}'),
                      padding: const EdgeInsets.symmetric(vertical: 36.0),
                      child: Text(
                        'Sin movimientos registrados en los gastos compartidos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: GodfatherTheme.textMuted, fontStyle: FontStyle.italic, fontSize: 18),
                      ),
                    )
                  : ListView.separated(
                      key: ValueKey<String>('list_house_hist_${_selectedDate.month}_${houseTxs.length}'),
                      shrinkWrap: true,
                      physics: isWide ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
                      itemCount: houseTxs.length,
                      separatorBuilder: (context, index) => Divider(color: GodfatherTheme.borderColor),
                      itemBuilder: (context, index) {
                        final tx = houseTxs[index];
                        final isExpense = tx.transactionType == TransactionType.gasto;
                        final visuals = GodfatherTheme.getCategoryVisuals(tx.category);
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          constraints: const BoxConstraints(minHeight: 72),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: visuals.bgColor,
                                  border: Border.all(
                                    color: visuals.color.withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  visuals.icon,
                                  color: visuals.color,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tx.concept,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 19,
                                        color: GodfatherTheme.textLight,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tx.category} • Por: ${tx.createdByName ?? "Miembro"}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: GodfatherTheme.textLight.withValues(alpha: 0.8),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen).withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      '${isExpense ? "-" : "+"} S/. ${tx.amount.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                        color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(RemixIcons.pencil_fill, size: 24),
                                    color: GodfatherTheme.primaryGold,
                                    onPressed: () => _openEditTransaction(tx),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(RemixIcons.delete_bin_fill, size: 24),
                                    color: GodfatherTheme.alertRed,
                                    onPressed: () => _deleteTransaction(tx),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );

        if (isWide) {
          return Column(
            children: [
              familySelector,
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: balanceCard,
                      ),
                    ),
                    VerticalDivider(color: GodfatherTheme.borderColor, width: 1),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: historyList,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              familySelector,
              const SizedBox(height: 12),
              balanceCard,
              const SizedBox(height: 24),
              historyList,
            ],
          ),
        );
      },
    );
  }

  // BOTTOM NAVIGATION BAR PERSONALIZADO IDÉNTICO AL DEL MOCKUP
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: GodfatherTheme.backgroundBlack,
        border: Border(
          top: BorderSide(color: GodfatherTheme.borderColor, width: 1.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
          _fadeController.reset();
          _fadeController.forward();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: GodfatherTheme.backgroundBlack,
        selectedItemColor: GodfatherTheme.primaryGold,
        unselectedItemColor: GodfatherTheme.textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
        iconSize: 28,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.dashboard_line),
            activeIcon: Icon(RemixIcons.dashboard_fill),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.user_3_line),
            activeIcon: Icon(RemixIcons.user_3_fill),
            label: 'Personales',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.home_4_line),
            activeIcon: Icon(RemixIcons.home_4_fill),
            label: 'De Casa',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.pie_chart_line),
            activeIcon: Icon(RemixIcons.pie_chart_fill),
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
        color: GodfatherTheme.backgroundBlack,
        child: Column(
          children: [
            // Drawer Header de Lujo
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 24, left: 20, right: 20),
              decoration: BoxDecoration(
                color: GodfatherTheme.surfaceDarkAlt,
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
                          color: GodfatherTheme.primaryGold.withValues(alpha: 0.2),
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
                              return Icon(Icons.person, color: GodfatherTheme.primaryGold, size: 30);
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: GodfatherTheme.textLight.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Caja Chica: S/. ${personalExpenses.toStringAsFixed(0)} / ${budgetLimit.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
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
                      });
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(color: GodfatherTheme.borderColor),
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
                  _buildDrawerItem(
                    icon: RemixIcons.home_heart_fill,
                    title: 'ADMINISTRACIÓN FAMILIAR',
                    subtitle: 'Cuentas y códigos',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const FamilySettingsSheet(),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: RemixIcons.mail_fill,
                    title: 'BUZÓN GMAIL / BCP',
                    subtitle: 'Revisión de BCP',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BcpInboxScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Bottom Sign Out
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: GodfatherTheme.borderColor, width: 1),
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
                    
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
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
        color: isSelected ? GodfatherTheme.primaryGold.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: GodfatherTheme.primaryGold.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.textLight.withValues(alpha: 0.6),
          size: 26,
        ),
        title: Text(
          title,
          style: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.textLight,
            letterSpacing: 1,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: GodfatherTheme.textLight.withValues(alpha: 0.5),
                ),
              )
            : null,
        trailing: isSelected
            ? Icon(Icons.chevron_right, color: GodfatherTheme.primaryGold, size: 20)
            : null,
      ),
    );
  }
}
