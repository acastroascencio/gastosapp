import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/transaction.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  TargetModule _selectedModule = TargetModule.personal;
  DateTime _selectedDate = DateTime.now();

  // Cambiar el mes de filtrado
  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'INFORME FINANCIERO',
          style: GoogleFonts.cinzel(
            color: GodfatherTheme.primaryGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: GodfatherTheme.primaryGold,
              size: 28,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: transactionsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(GodfatherTheme.primaryGold)),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error al cargar informes: $err',
              style: TextStyle(color: GodfatherTheme.alertRed),
            ),
          ),
          data: (transactions) {
            // 1. Filtrar transacciones del mes y año seleccionados
            final filteredTransactions = transactions.where((tx) {
              return tx.createdAt.month == _selectedDate.month &&
                  tx.createdAt.year == _selectedDate.year;
            }).toList();

            // 2. Separar según el módulo seleccionado (Personal o Casa)
            final moduleTransactions = filteredTransactions
                .where((tx) => tx.targetModule == _selectedModule)
                .toList();

            // 3. Cálculos de estadísticas rápidas
            final totalIncome = moduleTransactions
                .where((tx) => tx.transactionType == TransactionType.abono)
                .fold(0.0, (sum, tx) => sum + tx.amount);

            final totalExpenses = moduleTransactions
                .where((tx) => tx.transactionType == TransactionType.gasto)
                .fold(0.0, (sum, tx) => sum + tx.amount);

            final balance = _selectedModule == TargetModule.casa
                ? (totalIncome - totalExpenses)
                : -totalExpenses; // El balance personal es netamente gasto en la caja chica

            // 4. Agrupar gastos por categoría para el gráfico
            final expensesByCategory = <String, double>{};
            for (final tx in moduleTransactions) {
              if (tx.transactionType == TransactionType.gasto) {
                expensesByCategory[tx.category] =
                    (expensesByCategory[tx.category] ?? 0.0) + tx.amount;
              }
            }

            // 5. Preparar secciones del gráfico circular
            final List<PieChartSectionData> chartSections = [];
            final colors = [
              GodfatherTheme.primaryGold,
              GodfatherTheme.secondaryGold,
              const Color(0xFFD32F2F), // Rojo brillante
              const Color(0xFFE65100), // Naranja oscuro
              const Color(0xFF00796B), // Verde azulado
              const Color(0xFF303F9F), // Indigo
              const Color(0xFF5D4037), // Marrón
            ];

            int colorIndex = 0;
            expensesByCategory.forEach((category, amount) {
              final percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
              
              chartSections.add(
                PieChartSectionData(
                  color: colors[colorIndex % colors.length],
                  value: amount,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
              colorIndex++;
            });

            final isWide = MediaQuery.of(context).size.width > 900;

            // Widget de la izquierda (Gráfico, Leyenda y Resumen Numérico)
            Widget leftColumnContent = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gráfico de anillos con FL_CHART
                if (totalExpenses > 0)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: chartSections,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 140,
                    alignment: Alignment.center,
                    child: Text(
                      'Sin egresos registrados en este periodo.',
                      style: TextStyle(color: GodfatherTheme.textLight.withValues(alpha: 0.7), fontStyle: FontStyle.italic, fontSize: 18),
                    ),
                  ),

                // Leyenda de categorías del gráfico
                if (totalExpenses > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(expensesByCategory.length, (index) {
                        final entry = expensesByCategory.entries.elementAt(index);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.key}: S/. ${entry.value.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 16, color: GodfatherTheme.textLight),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),

                // Resumen numérico premium
                Card(
                  elevation: 2,
                  color: GodfatherTheme.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: GodfatherTheme.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_selectedModule == TargetModule.casa) ...[
                          Column(
                            children: [
                              Text('Ingresos', style: TextStyle(fontSize: 16, color: GodfatherTheme.textLight.withValues(alpha: 0.7))),
                              const SizedBox(height: 6),
                              Text(
                                'S/. ${totalIncome.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: GodfatherTheme.successGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 36, color: GodfatherTheme.borderColor),
                        ],
                        Column(
                          children: [
                            Text('Gastos', style: TextStyle(fontSize: 16, color: GodfatherTheme.textLight.withValues(alpha: 0.7))),
                            const SizedBox(height: 6),
                            Text(
                              'S/. ${totalExpenses.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: GodfatherTheme.alertRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 36, color: GodfatherTheme.borderColor),
                        Column(
                          children: [
                            Text(_selectedModule == TargetModule.casa ? 'Balance' : 'Total General',
                                style: TextStyle(fontSize: 16, color: GodfatherTheme.textLight.withValues(alpha: 0.7))),
                            const SizedBox(height: 6),
                            Text(
                              'S/. ${balance.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: balance >= 0 && _selectedModule == TargetModule.casa
                                      ? GodfatherTheme.primaryGold
                                      : GodfatherTheme.alertRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

            // Widget de la derecha (Lista de Movimientos)
            Widget rightColumnContent = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'REGISTROS DEL PERIODO',
                  style: GoogleFonts.cinzel(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: GodfatherTheme.primaryGold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                if (moduleTransactions.isEmpty)
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      'Ningún movimiento en este mes, Don.',
                      style: TextStyle(color: GodfatherTheme.textLight.withValues(alpha: 0.7), fontStyle: FontStyle.italic, fontSize: 18),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: isWide ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
                    itemCount: moduleTransactions.length,
                    separatorBuilder: (context, index) => Divider(color: GodfatherTheme.borderColor),
                    itemBuilder: (context, index) {
                      final tx = moduleTransactions[index];
                      final isExpense = tx.transactionType == TransactionType.gasto;
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                        leading: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: (isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExpense ? Icons.arrow_downward_outlined : Icons.arrow_upward_outlined,
                            color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          tx.concept,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: GodfatherTheme.textLight,
                            fontSize: 20,
                          ),
                        ),
                        subtitle: Text(
                          '${tx.category} • ${DateFormat('dd MMM').format(tx.createdAt)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: GodfatherTheme.textLight.withValues(alpha: 0.7)),
                        ),
                        trailing: Text(
                          '${isExpense ? "-" : "+"} S/. ${tx.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                            fontSize: 22,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );

            return Column(
              children: [
                // Selector de mes y año
                Container(
                  color: GodfatherTheme.surfaceDark,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: GodfatherTheme.primaryGold),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'es_PE').format(_selectedDate).toUpperCase(),
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold,
                          color: GodfatherTheme.primaryGold,
                          letterSpacing: 1,
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: GodfatherTheme.primaryGold),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),

                // Selector de módulo (Personal / Casa)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          labelPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          label: const Text('GASTOS PERSONALES'),
                          selected: _selectedModule == TargetModule.personal,
                          selectedColor: GodfatherTheme.primaryGold.withValues(alpha: 0.2),
                          backgroundColor: Colors.transparent,
                          labelStyle: TextStyle(
                            color: _selectedModule == TargetModule.personal
                                ? GodfatherTheme.primaryGold
                                : GodfatherTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          side: BorderSide(
                            color: _selectedModule == TargetModule.personal
                                ? GodfatherTheme.primaryGold
                                : GodfatherTheme.borderColor,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedModule = TargetModule.personal);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          labelPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          label: const Text('GASTOS DE LA CASA'),
                          selected: _selectedModule == TargetModule.casa,
                          selectedColor: GodfatherTheme.primaryGold.withValues(alpha: 0.2),
                          backgroundColor: Colors.transparent,
                          labelStyle: TextStyle(
                            color: _selectedModule == TargetModule.casa
                                ? GodfatherTheme.primaryGold
                                : GodfatherTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          side: BorderSide(
                            color: _selectedModule == TargetModule.casa
                                ? GodfatherTheme.primaryGold
                                : GodfatherTheme.borderColor,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedModule = TargetModule.casa);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: leftColumnContent,
                              ),
                            ),
                            VerticalDivider(color: GodfatherTheme.borderColor, width: 1),
                            Expanded(
                              flex: 6,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: rightColumnContent,
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              leftColumnContent,
                              const SizedBox(height: 24),
                              rightColumnContent,
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
