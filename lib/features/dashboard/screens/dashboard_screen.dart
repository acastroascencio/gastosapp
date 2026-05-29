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

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final budgetAsync = ref.watch(budgetProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
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
    String tabTitle = 'Dashboard';
    if (_currentTabIndex == 1) tabTitle = 'Gastos Personales';
    if (_currentTabIndex == 2) tabTitle = 'Gastos de Casa';
    if (_currentTabIndex == 3) tabTitle = 'Informes';

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
                  // Mostrar diálogo o salir de cuenta
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Operaciones familiares supervisadas por Don Corleone.'),
                      backgroundColor: GodfatherTheme.surfaceDark,
                    ),
                  );
                },
              ),
              // Título central "Dashboard" / "Reportes"
              Text(
                tabTitle,
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GodfatherTheme.primaryGold,
                  letterSpacing: 1.5,
                ),
              ),
              // Engrane de ajustes dorado
              IconButton(
                icon: const Icon(Icons.settings, color: GodfatherTheme.primaryGold, size: 24),
                onPressed: () async {
                  // Opción de cerrar sesión
                  final client = ref.read(supabaseClientProvider);
                  await client.auth.signOut();
                },
              ),
            ],
          ),
          // Subtítulo: Caja Chica: 0/200 Soles
          Text(
            'Caja Chica: ${spent.toStringAsFixed(0)}/${budgetLimit.toStringAsFixed(0)} Soles',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: GodfatherTheme.primaryGold.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // SWITCH DE VISTAS SEGÚN EL TAB SELECCIONADO
  Widget _buildTabContent({
    required int tabIndex,
    required List<model.Transaction> transactions,
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
    final spentPercentage = budgetLimit > 0 ? (personalExpenses / budgetLimit) : 0.0;
    
    // Configurar imagen del avatar según el estado de presupuesto
    String godfatherAsset = 'assets/images/godfather_knife.png'; // Por defecto, el sticker cargado
    if (spentPercentage > 1.0) {
      godfatherAsset = 'assets/images/godfather_angry.png';
    } else if (spentPercentage > 0.75) {
      godfatherAsset = 'assets/images/godfather_worried.png';
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        // RETRATO DEL AVATAR CON THICK GOLD BORDER
        Center(
          child: Column(
            children: [
              // Círculo del Retrato con borde dorado grueso y etiqueta pre-renderizada
              SizedBox(
                width: 280,
                height: 180,
                child: Image.asset(
                  'assets/images/godfather_asistente.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      size: 96,
                      color: GodfatherTheme.primaryGold,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Texto "AVATAR"
              Text(
                'AVATAR',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: GodfatherTheme.primaryGold,
                  letterSpacing: 1.5,
                ),
              ),
              // Subtítulo Caja Chica
              Text(
                'Caja Chica: ${personalExpenses.toStringAsFixed(0)}/${budgetLimit.toStringAsFixed(0)} Soles',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: GodfatherTheme.textLight.withOpacity(0.8),
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

  // BOTÓN INICIAL "AGREGAR GASTO" (GIANT CIRCULAR BUTTON CON DOUBLE BORDER)
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
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F0F12),
            border: Border.all(
              color: GodfatherTheme.primaryGold,
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: GodfatherTheme.primaryGold.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AGREGAR',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: GodfatherTheme.primaryGold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'GASTO',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: GodfatherTheme.primaryGold,
                    letterSpacing: 1,
                  ),
                ),
              ],
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
            // TARJETA DE GASTO ("GASTE")
            _buildSelectionCard(
              title: 'GASTE',
              subtitle: 'Modo Gasto con Cuchillo',
              assetPath: 'assets/images/godfather_knife.png',
              fallbackIcon: Icons.remove,
              borderColor: GodfatherTheme.alertRed,
              onTap: () => _openAddTransaction(TransactionType.gasto),
            ),
            const SizedBox(width: 20),
            // TARJETA DE ABONO ("ABONE")
            _buildSelectionCard(
              title: 'ABONE',
              subtitle: 'Modo Abono con Mano Abierta',
              assetPath: 'assets/images/godfather_neutral.png',
              fallbackIcon: Icons.add,
              borderColor: GodfatherTheme.successGreen,
              onTap: () => _openAddTransaction(TransactionType.abono),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // BOTÓN VOLVER
        GestureDetector(
          onTap: () {
            setState(() {
              _showSelection = false;
            });
          },
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F0F12),
              border: Border.all(
                color: GodfatherTheme.textMuted.withOpacity(0.6),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(
                'VOLVER',
                style: GoogleFonts.cinzel(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: GodfatherTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // CONSTRUCTOR DE TARJETA DE SELECCIÓN
  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required String assetPath,
    required IconData fallbackIcon,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 172,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF131317),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: GodfatherTheme.primaryGold.withOpacity(0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ilustración del sticker superior
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(fallbackIcon, size: 28, color: borderColor);
                  },
                ),
              ),
            ),
            const Spacer(),
            // Título "GASTE" / "ABONE"
            Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: GodfatherTheme.primaryGold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            // Subtítulo descriptivo
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: DETALLE DE GASTOS PERSONALES (CAJA CHICA)
  Widget _buildPersonalExpensesView(double spent, double limit, List<model.Transaction> transactions) {
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
  Widget _buildHouseExpensesView(double income, double expenses, double balance, List<model.Transaction> transactions) {
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
}
