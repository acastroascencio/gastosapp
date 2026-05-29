import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _openAddTransaction(TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTransactionSheet(defaultType: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final budgetAsync = ref.watch(budgetProvider);

    // Valores por defecto
    String fullName = 'Don';
    if (user != null) {
      profileAsync.whenData((profile) {
        if (profile != null && profile.fullName.isNotEmpty) {
          fullName = profile.fullName;
        } else {
          fullName = user.email?.split('@')[0] ?? 'Don';
          // Capitalizar
          fullName = fullName[0].toUpperCase() + fullName.substring(1);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'THE GODFATHER',
          style: GoogleFonts.cinzel(
            color: GodfatherTheme.primaryGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: GodfatherTheme.primaryGold),
            onPressed: () async {
              final client = ref.read(supabaseClientProvider);
              await client.auth.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Recargar datos
            ref.read(profileProvider.notifier);
            await ref.read(transactionProvider.notifier).loadTransactions();
            await ref.read(budgetProvider.notifier).loadBudgetForCurrentMonth();
          },
          color: GodfatherTheme.primaryGold,
          backgroundColor: GodfatherTheme.surfaceDark,
          child: transactionsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(GodfatherTheme.primaryGold)),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error al cargar transacciones: $err',
                style: const TextStyle(color: GodfatherTheme.alertRed),
              ),
            ),
            data: (transactions) {
              final budgetLimit = budgetAsync.value?.limitAmount ?? 200.0; // 200 soles por defecto
              
              // 1. Cálculos de Caja Chica (Gastos Personales)
              final now = DateTime.now();
              final currentMonthTransactions = transactions.where((tx) {
                return tx.createdAt.month == now.month && tx.createdAt.year == now.year;
              }).toList();

              final personalExpenses = currentMonthTransactions
                  .where((tx) => tx.targetModule == TargetModule.personal && tx.transactionType == TransactionType.gasto)
                  .fold(0.0, (sum, tx) => sum + tx.amount);

              final spentPercentage = budgetLimit > 0 ? (personalExpenses / budgetLimit) : 0.0;

              // 2. Cálculos de la Casa
              final houseIncomes = currentMonthTransactions
                  .where((tx) => tx.targetModule == TargetModule.casa && tx.transactionType == TransactionType.abono)
                  .fold(0.0, (sum, tx) => sum + tx.amount);

              final houseExpenses = currentMonthTransactions
                  .where((tx) => tx.targetModule == TargetModule.casa && tx.transactionType == TransactionType.gasto)
                  .fold(0.0, (sum, tx) => sum + tx.amount);

              final houseBalance = houseIncomes - houseExpenses;

              // 3. Determinar Humor del Padrino
              String godfatherAsset = 'assets/images/godfather_neutral.png';
              String moodText = 'El Padrino está tranquilo con tus cuentas.';
              Color moodColor = GodfatherTheme.successGreen;

              if (spentPercentage > 1.0) {
                godfatherAsset = 'assets/images/godfather_angry.png';
                moodText = '¡Has excedido el presupuesto de la caja chica! El Padrino está enojado.';
                moodColor = GodfatherTheme.alertRed;
              } else if (spentPercentage > 0.75) {
                godfatherAsset = 'assets/images/godfather_worried.png';
                moodText = 'Te estás acercando al límite. Ten cuidado, Don.';
                moodColor = GodfatherTheme.primaryGold;
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mensaje de bienvenida
                          Text(
                            'Saludos, $fullName',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: GoogleFonts.cinzel().fontFamily,
                              fontSize: 22,
                              color: GodfatherTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Ilustración interactiva del Padrino (Mood reactivo)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
                                Container(
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: moodColor.withOpacity(0.12),
                                        blurRadius: 36,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    godfatherAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback visual si falla la carga del asset
                                      return Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16161A),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: moodColor, width: 2),
                                        ),
                                        child: Icon(
                                          Icons.account_balance_outlined,
                                          size: 72,
                                          color: moodColor,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Glovo de diálogo de humor del Padrino
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: GodfatherTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: moodColor.withOpacity(0.3), width: 1),
                                  ),
                                  child: Text(
                                    moodText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: moodColor,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // PANEL 1: Caja Chica (Gastos Personales)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xFF2C2C30), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'GASTOS PERSONALES (Caja Chica)',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          color: GodfatherTheme.primaryGold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: GodfatherTheme.textMuted),
                                        onPressed: () => _showConfigureBudgetDialog(budgetLimit),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        'S/. ${personalExpenses.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: spentPercentage >= 1.0
                                              ? GodfatherTheme.alertRed
                                              : GodfatherTheme.textLight,
                                        ),
                                      ),
                                      Text(
                                        'Límite: S/. ${budgetLimit.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Barra de progreso personalizada
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: spentPercentage.clamp(0.0, 1.0),
                                      minHeight: 12,
                                      backgroundColor: const Color(0xFF232328),
                                      valueColor: AlwaysStoppedAnimation(
                                        spentPercentage >= 1.0
                                            ? GodfatherTheme.alertRed
                                            : GodfatherTheme.primaryGold,
                                      ),
                                    ),
                                  ),
                                  if (spentPercentage >= 1.0)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Límite excedido. El negocio está sufriendo pérdidas.',
                                        style: TextStyle(color: GodfatherTheme.alertRed, fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // PANEL 2: Balance de la Casa
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xFF2C2C30), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'BALANCE DE LA CASA',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: GodfatherTheme.primaryGold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Abonos (Padre)', style: TextStyle(fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'S/. ${houseIncomes.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: GodfatherTheme.successGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 24,
                                        width: 1,
                                        color: const Color(0xFF2C2C30),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Gastos Fijos', style: TextStyle(fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'S/. ${houseExpenses.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: GodfatherTheme.alertRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 28, color: Color(0xFF2C2C30)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Saldo Restante',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'S/. ${houseBalance.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: houseBalance >= 0
                                              ? GodfatherTheme.primaryGold
                                              : GodfatherTheme.alertRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botón para ir a reportes
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ReportsScreen()),
                              );
                            },
                            icon: const Icon(Icons.pie_chart_outline_outlined, color: GodfatherTheme.backgroundBlack),
                            label: const Text('VER INFORMES Y REPORTES'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GodfatherTheme.primaryGold,
                              foregroundColor: GodfatherTheme.backgroundBlack,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // CONTROLES FLOTANTES SIN TEXTO (Cuchillo e Ingreso)
                  Container(
                    padding: const EdgeInsets.only(bottom: 24.0, left: 32.0, right: 32.0, top: 12.0),
                    decoration: const BoxDecoration(
                      color: GodfatherTheme.backgroundBlack,
                      border: Border(
                        top: BorderSide(color: Color(0xFF16161A), width: 1.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Botón Gasto (01.png - Cuchillo)
                        _buildFloatingActionButton(
                          assetPath: 'assets/images/01.png',
                          fallbackIcon: Icons.remove,
                          color: GodfatherTheme.alertRed,
                          onPressed: () => _openAddTransaction(TransactionType.gasto),
                        ),
                        // Botón Abono (02.png - Mano abierta)
                        _buildFloatingActionButton(
                          assetPath: 'assets/images/02.png',
                          fallbackIcon: Icons.add,
                          color: GodfatherTheme.successGreen,
                          onPressed: () => _openAddTransaction(TransactionType.abono),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Constructor de botones flotantes animados sin etiquetas de texto
  Widget _buildFloatingActionButton({
    required String assetPath,
    required IconData fallbackIcon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedScale(
            scale: isHovered ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GodfatherTheme.surfaceDark,
                  border: Border.all(
                    color: isHovered ? color : GodfatherTheme.primaryGold.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isHovered ? color : GodfatherTheme.primaryGold).withOpacity(0.25),
                      blurRadius: isHovered ? 16 : 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        fallbackIcon,
                        size: 32,
                        color: color,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
