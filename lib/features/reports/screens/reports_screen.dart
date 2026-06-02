import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/transaction.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  const ReportsScreen({super.key, required this.selectedDate});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  TargetModule _selectedModule = TargetModule.personal;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final familiesAsync = ref.watch(familyProvider);
    final selectedFamily = ref.watch(selectedFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);


    // Current user id simulation or real
    final currentUserId = currentUser?.id ?? 'guest-user-id';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'INFORME FINANCIERO',
            style: GoogleFonts.cinzel(
              color: GodfatherTheme.primaryGold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 22,
            ),
          ),
        ),

            // 2. Selector de Módulo (Personal / Casa-Familia)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      showCheckmark: false,
                      labelPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      label: const Align(
                        alignment: Alignment.center,
                        child: Text('PERSONALES'),
                      ),
                      selected: _selectedModule == TargetModule.personal,
                      selectedColor: GodfatherTheme.primaryGold.withValues(alpha: 0.2),
                      backgroundColor: GodfatherTheme.surfaceDarkAlt,
                      labelStyle: TextStyle(
                        color: _selectedModule == TargetModule.personal
                            ? GodfatherTheme.primaryGold
                            : GodfatherTheme.textLight.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      side: BorderSide(
                        color: _selectedModule == TargetModule.personal
                            ? GodfatherTheme.primaryGold
                            : GodfatherTheme.borderColor,
                        width: _selectedModule == TargetModule.personal ? 2.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) setState(() => _selectedModule = TargetModule.personal);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      showCheckmark: false,
                      labelPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      label: const Align(
                        alignment: Alignment.center,
                        child: Text('DE LA CASA'),
                      ),
                      selected: _selectedModule == TargetModule.casa,
                      selectedColor: GodfatherTheme.primaryGold.withValues(alpha: 0.2),
                      backgroundColor: GodfatherTheme.surfaceDarkAlt,
                      labelStyle: TextStyle(
                        color: _selectedModule == TargetModule.casa
                            ? GodfatherTheme.primaryGold
                            : GodfatherTheme.textLight.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      side: BorderSide(
                        color: _selectedModule == TargetModule.casa
                            ? GodfatherTheme.primaryGold
                            : GodfatherTheme.borderColor,
                        width: _selectedModule == TargetModule.casa ? 2.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) setState(() => _selectedModule = TargetModule.casa);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Selector de Familia (si se selecciona el módulo de Casa)
            if (_selectedModule == TargetModule.casa)
              familiesAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GodfatherTheme.alertRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: GodfatherTheme.alertRed),
                        ),
                        child: Text(
                          'No perteneces a ninguna familia. Crea o únete a una desde Ajustes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: GodfatherTheme.alertRed, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  return Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final family = list[idx];
                        final isSelected = selectedFamily?.id == family.id;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(family.name.toUpperCase()),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (selected) {
                              if (selected) {
                                ref.read(selectedFamilyProvider.notifier).state = family;
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(height: 52),
                error: (err, stack) => const SizedBox(height: 52),
              ),

            Expanded(
              child: transactionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(GodfatherTheme.primaryGold)),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Error al cargar informes: $err',
                    style: TextStyle(color: GodfatherTheme.alertRed, fontSize: 18),
                  ),
                ),
                data: (transactions) {
                  // 1. Filtrar transacciones del mes y año seleccionados
                  final monthFiltered = transactions.where((tx) {
                    return tx.createdAt.month == widget.selectedDate.month &&
                        tx.createdAt.year == widget.selectedDate.year;
                  }).toList();

                  // 2. Filtrar según módulo con lógica estricta de seguridad
                  final List<Transaction> moduleTransactions;
                  if (_selectedModule == TargetModule.personal) {
                    // Totalmente privado
                    moduleTransactions = monthFiltered.where((tx) =>
                        tx.targetModule == TargetModule.personal &&
                        tx.userId == currentUserId).toList();
                  } else {
                    // Por familia seleccionada y no borrada lógicamente
                    if (selectedFamily == null) {
                      moduleTransactions = [];
                    } else {
                      moduleTransactions = monthFiltered.where((tx) =>
                          tx.targetModule == TargetModule.casa &&
                          tx.familyId == selectedFamily.id &&
                          !tx.deleted).toList();
                    }
                  }

                  final Widget bodyWidget;

                  if (moduleTransactions.isEmpty) {
                    bodyWidget = Center(
                      key: ValueKey<String>('empty_${widget.selectedDate.month}-$_selectedModule'),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(RemixIcons.folder_open_fill, size: 80, color: GodfatherTheme.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                'Ningún movimiento registrado en este mes, Don.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: GodfatherTheme.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    // 3. Cálculos de estadísticas rápidas
                    final totalIncome = moduleTransactions
                        .where((tx) => tx.transactionType == TransactionType.abono)
                        .fold(0.0, (sum, tx) => sum + tx.amount);

                    final totalExpenses = moduleTransactions
                        .where((tx) => tx.transactionType == TransactionType.gasto)
                        .fold(0.0, (sum, tx) => sum + tx.amount);

                    final balance = _selectedModule == TargetModule.casa
                        ? (totalIncome - totalExpenses)
                        : -totalExpenses;

                    // 4. Agrupar gastos por categoría para el gráfico
                    final expensesByCategory = <String, double>{};
                    for (final tx in moduleTransactions) {
                      if (tx.transactionType == TransactionType.gasto) {
                        expensesByCategory[tx.category] =
                            (expensesByCategory[tx.category] ?? 0.0) + tx.amount;
                      }
                    }

                    // 5. Resumen de registros por usuario (para reporte familiar)
                    final userContributions = <String, double>{};
                    if (_selectedModule == TargetModule.casa) {
                      for (final tx in moduleTransactions) {
                        if (tx.transactionType == TransactionType.gasto) {
                          final userName = tx.createdByName ?? 'Miembro';
                          userContributions[userName] = (userContributions[userName] ?? 0.0) + tx.amount;
                        }
                      }
                    }

                    // 6. Preparar secciones del gráfico circular
                    final List<PieChartSectionData> chartSections = [];
                    final colors = [
                      GodfatherTheme.primaryGold,
                      GodfatherTheme.secondaryGold,
                      const Color(0xFFC1121F), // Rojo Padrino
                      const Color(0xFF15803D), // Verde Padrino
                      const Color(0xFF00796B),
                      const Color(0xFF303F9F),
                      const Color(0xFF5D4037),
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

                    Widget leftColumnContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gráfico de anillos
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
                              style: TextStyle(
                                color: GodfatherTheme.textLight.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                                fontSize: 18,
                              ),
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
                        const SizedBox(height: 16),

                        // Resumen por Miembro (Familia)
                        if (_selectedModule == TargetModule.casa && userContributions.isNotEmpty) ...[
                          Card(
                            color: GodfatherTheme.surfaceDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: GodfatherTheme.borderColor),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'REGISTRADO POR CADA MIEMBRO',
                                    style: GoogleFonts.cinzel(
                                      color: GodfatherTheme.primaryGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...userContributions.entries.map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: GodfatherTheme.textLight,
                                          ),
                                        ),
                                        Text(
                                          'S/. ${entry.value.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: GodfatherTheme.primaryGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );

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
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: moduleTransactions.length,
                          separatorBuilder: (context, index) => Divider(color: GodfatherTheme.borderColor),
                          itemBuilder: (context, index) {
                            final tx = moduleTransactions[index];
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
                                          '${tx.category} • ${DateFormat('dd MMM').format(tx.createdAt)}${_selectedModule == TargetModule.casa ? " • Por: ${tx.createdByName ?? 'Miembro'}" : ""}',
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
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );

                    bodyWidget = isWide
                        ? Row(
                            key: ValueKey<String>('wide_${widget.selectedDate.month}-$_selectedModule-${moduleTransactions.length}'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            key: ValueKey<String>('narrow_${widget.selectedDate.month}-$_selectedModule-${moduleTransactions.length}'),
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
                          );
                  }

                  return AnimatedSwitcher(
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
                    child: bodyWidget,
                  );
                },
              ),
            ),
          ],
        );
      }
    }
