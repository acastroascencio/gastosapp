import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/transaction.dart';
import '../services/vocal_parser.dart';

class CategoryItem {
  final String label;
  final IconData icon;

  const CategoryItem(this.label, this.icon);
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType defaultType;

  const AddTransactionSheet({
    super.key,
    required this.defaultType,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _conceptController = TextEditingController();
  final _categoryController = TextEditingController(); // For manual category fallback
  final _noteController = TextEditingController(); // Optional note

  // Remember last choices statically within the session
  static TransactionType _lastType = TransactionType.gasto;
  static TargetModule _lastTarget = TargetModule.personal;

  late TransactionType _type;
  late TargetModule _target;
  String _selectedCategory = '';
  bool _isLoading = false;

  // Speech to Text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = '';

  // Grids of category icons for each of the 4 combinations
  static const List<CategoryItem> _gastoCasaCategories = [
    CategoryItem('Internet', Icons.wifi),
    CategoryItem('Luz', Icons.lightbulb_outline),
    CategoryItem('Agua', Icons.water_drop),
    CategoryItem('Seguridad', Icons.security),
    CategoryItem('Alquiler', Icons.home),
    CategoryItem('Mantenimiento', Icons.build),
    CategoryItem('Gas', Icons.local_fire_department),
    CategoryItem('Celular', Icons.phone_android),
    CategoryItem('Streaming', Icons.tv),
    CategoryItem('Limpieza', Icons.cleaning_services),
    CategoryItem('Compras Casa', Icons.shopping_cart),
    CategoryItem('Otros', Icons.more_horiz),
  ];

  static const List<CategoryItem> _gastoPersonalCategories = [
    CategoryItem('Comida', Icons.restaurant),
    CategoryItem('Transporte', Icons.directions_car),
    CategoryItem('Salud', Icons.medical_services),
    CategoryItem('Ocio', Icons.sports_esports),
    CategoryItem('Educación', Icons.school),
    CategoryItem('Ropa', Icons.checkroom),
    CategoryItem('Mascotas', Icons.pets),
    CategoryItem('Otros', Icons.more_horiz),
  ];

  static const List<CategoryItem> _abonoCasaCategories = [
    CategoryItem('Aporte mensual', Icons.calendar_month),
    CategoryItem('Reembolso', Icons.replay),
    CategoryItem('Fondo común', Icons.groups),
    CategoryItem('Pago comp.', Icons.share),
    CategoryItem('Otro', Icons.more_horiz),
  ];

  static const List<CategoryItem> _abonoPersonalCategories = [
    CategoryItem('Sueldo', Icons.work),
    CategoryItem('Extra', Icons.add_circle),
    CategoryItem('Reembolso', Icons.replay),
    CategoryItem('Venta', Icons.storefront),
    CategoryItem('Otro', Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();
    // Default initialization based on widget parameter or session memory
    _type = widget.defaultType;
    if (_type == _lastType) {
      _target = _lastTarget;
    } else {
      _target = _type == TransactionType.abono ? TargetModule.casa : TargetModule.personal;
    }
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _conceptController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Activa o desactiva la escucha por voz
  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error de dictado: ${val.errorMsg}'),
              backgroundColor: GodfatherTheme.alertRed,
            ),
          );
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _voiceText = val.recognizedWords;
              if (val.finalResult) {
                _processVoiceInput(_voiceText);
              }
            });
          },
          localeId: 'es_PE', // Forzar español peruano
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconocimiento de voz no disponible en este dispositivo.'),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Mapea la categoría/concepto dictados por voz a una de las categorías visuales con íconos
  String _mapVoiceCategoryToVisual(String voiceCategory, String concept, TransactionType type, TargetModule target) {
    final cleanCategory = voiceCategory.toLowerCase().trim();
    final cleanConcept = concept.toLowerCase().trim();

    if (type == TransactionType.gasto) {
      if (target == TargetModule.casa) {
        if (cleanCategory.contains('internet') || cleanConcept.contains('internet') || cleanConcept.contains('wifi') || cleanConcept.contains('cable')) {
          return 'Internet';
        }
        if (cleanCategory.contains('luz') || cleanConcept.contains('luz') || cleanConcept.contains('electricidad') || cleanConcept.contains('foco') || cleanConcept.contains('rayo')) {
          return 'Luz';
        }
        if (cleanCategory.contains('agua') || cleanConcept.contains('agua') || cleanConcept.contains('sedapal') || cleanConcept.contains('gota')) {
          return 'Agua';
        }
        if (cleanCategory.contains('seguridad') || cleanConcept.contains('seguridad') || cleanConcept.contains('vigilancia') || cleanConcept.contains('escudo')) {
          return 'Seguridad';
        }
        if (cleanCategory.contains('alquiler') || cleanConcept.contains('alquiler') || cleanConcept.contains('renta') || cleanConcept.contains('casa') || cleanConcept.contains('depa')) {
          return 'Alquiler';
        }
        if (cleanCategory.contains('mantenimiento') || cleanConcept.contains('mantenimiento') || cleanConcept.contains('reparar') || cleanConcept.contains('build')) {
          return 'Mantenimiento';
        }
        if (cleanCategory.contains('gas') || cleanConcept.contains('gas') || cleanConcept.contains('calidda') || cleanConcept.contains('llama')) {
          return 'Gas';
        }
        if (cleanCategory.contains('teléfono') || cleanCategory.contains('telefono') || cleanConcept.contains('teléfono') || cleanConcept.contains('telefono') || cleanConcept.contains('celular') || cleanConcept.contains('movil') || cleanConcept.contains('móvil')) {
          return 'Celular';
        }
        if (cleanCategory.contains('streaming') || cleanConcept.contains('streaming') || cleanConcept.contains('netflix') || cleanConcept.contains('spotify') || cleanConcept.contains('disney') || cleanConcept.contains('tv')) {
          return 'Streaming';
        }
        if (cleanCategory.contains('limpieza') || cleanConcept.contains('limpieza') || cleanConcept.contains('escoba') || cleanConcept.contains('aseo')) {
          return 'Limpieza';
        }
        if (cleanCategory.contains('compra') || cleanCategory.contains('compras') || cleanConcept.contains('compra') || cleanConcept.contains('compras') || cleanConcept.contains('super') || cleanConcept.contains('mercado') || cleanConcept.contains('hogar') || cleanConcept.contains('casa')) {
          return 'Compras Casa';
        }
        return 'Otros';
      } else {
        if (cleanCategory.contains('comida') || cleanCategory.contains('alimentacion') || cleanCategory.contains('alimentación') || cleanConcept.contains('comida') || cleanConcept.contains('cena') || cleanConcept.contains('almuerzo') || cleanConcept.contains('desayuno') || cleanConcept.contains('restaurante')) {
          return 'Comida';
        }
        if (cleanCategory.contains('transporte') || cleanConcept.contains('transporte') || cleanConcept.contains('taxi') || cleanConcept.contains('uber') || cleanConcept.contains('bus') || cleanConcept.contains('pasaje') || cleanConcept.contains('gasolina') || cleanConcept.contains('combustible')) {
          return 'Transporte';
        }
        if (cleanCategory.contains('salud') || cleanConcept.contains('salud') || cleanConcept.contains('médico') || cleanConcept.contains('medico') || cleanConcept.contains('farmacia') || cleanConcept.contains('pastilla') || cleanConcept.contains('hospital') || cleanConcept.contains('clinica') || cleanConcept.contains('clínica')) {
          return 'Salud';
        }
        if (cleanCategory.contains('ocio') || cleanCategory.contains('entretenimiento') || cleanConcept.contains('ocio') || cleanConcept.contains('cine') || cleanConcept.contains('salida') || cleanConcept.contains('bar') || cleanConcept.contains('fiesta') || cleanConcept.contains('cerveza') || cleanConcept.contains('juego') || cleanConcept.contains('diversion') || cleanConcept.contains('diversión')) {
          return 'Ocio';
        }
        if (cleanCategory.contains('educación') || cleanCategory.contains('educacion') || cleanConcept.contains('educación') || cleanConcept.contains('educacion') || cleanConcept.contains('colegio') || cleanConcept.contains('universidad') || cleanConcept.contains('libro') || cleanConcept.contains('curso')) {
          return 'Educación';
        }
        if (cleanCategory.contains('ropa') || cleanConcept.contains('ropa') || cleanConcept.contains('zapatos') || cleanConcept.contains('camisa') || cleanConcept.contains('polo') || cleanConcept.contains('casaca') || cleanConcept.contains('vestido')) {
          return 'Ropa';
        }
        if (cleanCategory.contains('mascota') || cleanCategory.contains('mascotas') || cleanConcept.contains('mascota') || cleanConcept.contains('mascotas') || cleanConcept.contains('perro') || cleanConcept.contains('gato') || cleanConcept.contains('pets') || cleanConcept.contains('veterinaria')) {
          return 'Mascotas';
        }
        return 'Otros';
      }
    } else {
      if (target == TargetModule.casa) {
        if (cleanCategory.contains('aporte') || cleanCategory.contains('mensual') || cleanConcept.contains('aporte') || cleanConcept.contains('mensual') || cleanConcept.contains('mensualidad') || cleanConcept.contains('cuota')) {
          return 'Aporte mensual';
        }
        if (cleanCategory.contains('reembolso') || cleanConcept.contains('reembolso') || cleanConcept.contains('devolucion') || cleanConcept.contains('devolución')) {
          return 'Reembolso';
        }
        if (cleanCategory.contains('común') || cleanCategory.contains('comun') || cleanCategory.contains('fondo') || cleanConcept.contains('común') || cleanConcept.contains('comun') || cleanConcept.contains('fondo') || cleanConcept.contains('grupos') || cleanConcept.contains('casa')) {
          return 'Fondo común';
        }
        if (cleanCategory.contains('compartido') || cleanConcept.contains('compartido') || cleanConcept.contains('yape') || cleanConcept.contains('plin') || cleanConcept.contains('share') || cleanConcept.contains('pago')) {
          return 'Pago comp.';
        }
        return 'Otro';
      } else {
        if (cleanCategory.contains('sueldo') || cleanCategory.contains('salario') || cleanConcept.contains('sueldo') || cleanConcept.contains('salario') || cleanConcept.contains('trabajo') || cleanConcept.contains('nomina') || cleanConcept.contains('nómina')) {
          return 'Sueldo';
        }
        if (cleanCategory.contains('extra') || cleanCategory.contains('bono') || cleanConcept.contains('extra') || cleanConcept.contains('bono') || cleanConcept.contains('regalo') || cleanConcept.contains('premio')) {
          return 'Extra';
        }
        if (cleanCategory.contains('reembolso') || cleanConcept.contains('reembolso') || cleanConcept.contains('devolucion') || cleanConcept.contains('devolución')) {
          return 'Reembolso';
        }
        if (cleanCategory.contains('venta') || cleanConcept.contains('venta') || cleanConcept.contains('vendi') || cleanConcept.contains('vendí') || cleanConcept.contains('negocio') || cleanConcept.contains('tienda')) {
          return 'Venta';
        }
        return 'Otro';
      }
    }
  }

  // Procesa el texto dictado
  void _processVoiceInput(String text) {
    if (text.isEmpty) return;

    final result = VocalParser.parse(text);

    setState(() {
      _amountController.text = result.amount > 0 ? result.amount.toStringAsFixed(2) : '';
      _conceptController.text = result.concept;
      _type = result.type;
      _target = result.target;

      // Update static selectors memory
      _lastType = _type;
      _lastTarget = _target;

      // Match vocal parsed category with visual grids
      final matchedCategory = _mapVoiceCategoryToVisual(result.category, result.concept, _type, _target);
      _selectedCategory = matchedCategory;

      if (matchedCategory == 'Otros' || matchedCategory == 'Otro') {
        // If voice parsed a completely custom category, keep it in the manual input
        if (result.category != 'Otros' && result.category != 'Otros del Hogar' && result.category != 'Caja Chica') {
          _categoryController.text = result.category;
        } else {
          _categoryController.clear();
        }
      } else {
        _categoryController.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analizado: S/. ${result.amount.toStringAsFixed(2)} en "${result.concept}" ($_selectedCategory)'),
        backgroundColor: GodfatherTheme.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Verify Concept
    if (_conceptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa el concepto de la transacción.'),
          backgroundColor: GodfatherTheme.alertRed,
        ),
      );
      return;
    }

    // Determine final category (selected from visual grid or manual input)
    final isCustomCategory = _selectedCategory == 'Otros' || _selectedCategory == 'Otro' || _selectedCategory.isEmpty;
    final finalCategory = isCustomCategory 
        ? _categoryController.text.trim() 
        : _selectedCategory;

    if (finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una categoría o ingresa una manualmente.'),
          backgroundColor: GodfatherTheme.alertRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      
      // If note is filled, append it to the concept as concept (note)
      String concept = _conceptController.text.trim();
      if (_noteController.text.trim().isNotEmpty) {
        concept = "$concept (${_noteController.text.trim()})";
      }

      await ref.read(transactionProvider.notifier).addTransaction(
            amount: amount,
            concept: concept,
            category: finalCategory,
            type: _type,
            target: _target,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción registrada en el libro mayor.'),
            backgroundColor: GodfatherTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: GodfatherTheme.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Custom Segmented Control builder
  Widget _buildSegmentedControl<T>({
    required String label,
    required T selectedValue,
    required List<MapEntry<T, String>> options,
    required Color activeColor,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: GodfatherTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF131316),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2C2C30)),
          ),
          child: Row(
            children: options.map((entry) {
              final isSelected = selectedValue == entry.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(entry.key),
                  child: AnimatedContainer(
                     duration: const Duration(milliseconds: 250),
                     curve: Curves.easeInOut,
                     padding: const EdgeInsets.symmetric(vertical: 10),
                     decoration: BoxDecoration(
                       color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(
                         color: isSelected ? activeColor : Colors.transparent,
                         width: 1.2,
                       ),
                     ),
                     child: Center(
                       child: Text(
                         entry.value,
                         style: GoogleFonts.inter(
                           fontSize: 12,
                           fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                           color: isSelected ? activeColor : GodfatherTheme.textMuted,
                           letterSpacing: 0.5,
                         ),
                       ),
                     ),
                   ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Custom Grid Category Selector builder
  Widget _buildCategorySelector({
    required List<CategoryItem> items,
    required String selectedCategory,
    required Color themeColor,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORÍA',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: GodfatherTheme.primaryGold,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = selectedCategory == item.label;
            return GestureDetector(
              onTap: () => onSelected(item.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? themeColor.withValues(alpha: 0.08) : const Color(0xFF131316),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? GodfatherTheme.primaryGold : const Color(0xFF2C2C30),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: GodfatherTheme.primaryGold.withValues(alpha: 0.15),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          )
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? GodfatherTheme.primaryGold : GodfatherTheme.textMuted,
                        size: 26,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? GodfatherTheme.textLight : GodfatherTheme.textMuted,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Real-time Summary Badge builder
  Widget _buildRealTimeSummary() {
    String summaryText = '';
    if (_type == TransactionType.gasto) {
      summaryText = _target == TargetModule.personal ? 'Gasto personal' : 'Gasto de casa';
    } else {
      summaryText = _target == TargetModule.personal ? 'Ingreso personal' : 'Abono para casa';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GodfatherTheme.primaryGold.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _type == TransactionType.gasto ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                text: 'Estás registrando: ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: GodfatherTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: summaryText.toUpperCase(),
                    style: GoogleFonts.cinzel(
                      fontSize: 12,
                      color: GodfatherTheme.primaryGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGasto = _type == TransactionType.gasto;
    final themeColor = isGasto ? GodfatherTheme.alertRed : GodfatherTheme.successGreen;

    // Select the category list based on type & target module
    List<CategoryItem> activeCategoryList;
    if (isGasto) {
      activeCategoryList = _target == TargetModule.casa ? _gastoCasaCategories : _gastoPersonalCategories;
    } else {
      activeCategoryList = _target == TargetModule.casa ? _abonoCasaCategories : _abonoPersonalCategories;
    }

    // Contextual button texts and styles
    String buttonText = '';
    Color buttonColor = themeColor;
    if (isGasto) {
      buttonColor = GodfatherTheme.alertRed;
      buttonText = _target == TargetModule.personal 
          ? 'CONFIRMAR GASTO PERSONAL' 
          : 'CONFIRMAR GASTO DE CASA';
    } else {
      buttonColor = GodfatherTheme.successGreen;
      buttonText = _target == TargetModule.personal 
          ? 'CONFIRMAR INGRESO PERSONAL' 
          : 'CONFIRMAR ABONO A CASA';
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Handle bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Microphone Dictation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isGasto ? 'REGISTRAR GASTO' : 'REGISTRAR ABONO',
                    style: GoogleFonts.cinzel(
                      color: GodfatherTheme.primaryGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? GodfatherTheme.alertRed.withValues(alpha: 0.2)
                            : const Color(0xFF1E1E24),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening ? GodfatherTheme.alertRed : GodfatherTheme.primaryGold,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? GodfatherTheme.alertRed : GodfatherTheme.primaryGold,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Speech Feedback Status
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Escuchando... "ej: 45 soles internet"',
                    style: TextStyle(
                      color: GodfatherTheme.alertRed,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                )
              else if (_voiceText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    'Dictado: "$_voiceText"',
                    style: const TextStyle(
                      color: GodfatherTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // SECTION 1: Tipo de Movimiento (Gasto / Abono)
              _buildSegmentedControl<TransactionType>(
                label: 'Tipo de movimiento',
                selectedValue: _type,
                options: const [
                  MapEntry(TransactionType.gasto, 'Gasto'),
                  MapEntry(TransactionType.abono, 'Abono'),
                ],
                activeColor: themeColor,
                onSelected: (val) {
                  setState(() {
                    _type = val;
                    _lastType = val;
                    // Auto-adjust default scopes to make it less confusing
                    _target = val == TransactionType.abono ? TargetModule.casa : TargetModule.personal;
                    _lastTarget = _target;
                    _selectedCategory = '';
                    _categoryController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // SECTION 2: Destino / Cuenta
              _buildSegmentedControl<TargetModule>(
                label: 'Destino / Cuenta',
                selectedValue: _target,
                options: isGasto
                    ? const [
                        MapEntry(TargetModule.personal, 'Personal'),
                        MapEntry(TargetModule.casa, 'Casa'),
                      ]
                    : const [
                        MapEntry(TargetModule.personal, 'A mi cuenta personal'),
                        MapEntry(TargetModule.casa, 'A gastos de casa'),
                      ],
                activeColor: themeColor,
                onSelected: (val) {
                  setState(() {
                    _target = val;
                    _lastTarget = val;
                    _selectedCategory = '';
                    _categoryController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),

              // SECTION 3: Real-time Summary Badge (2 seconds UX feedback)
              _buildRealTimeSummary(),
              const SizedBox(height: 24),

              // SECTION 4: Amount Input (Centered & Huge)
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: isGasto ? GodfatherTheme.alertRed : GodfatherTheme.successGreen,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: GodfatherTheme.textMuted.withValues(alpha: 0.25),
                    fontSize: 38,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 4.0),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        'S/.',
                        style: GoogleFonts.cinzel(
                          fontSize: 26,
                          color: GodfatherTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  fillColor: const Color(0xFF131316),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2C2C30), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: GodfatherTheme.primaryGold, width: 1.8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa el monto.';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto válido mayor a 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Concept input
              TextFormField(
                controller: _conceptController,
                style: const TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Concepto (Ej. Luz, Almuerzo, Sueldo)',
                  prefixIcon: Icon(Icons.description_outlined, color: GodfatherTheme.primaryGold),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el concepto.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Grid-Selector for Categories
              _buildCategorySelector(
                items: activeCategoryList,
                selectedCategory: _selectedCategory,
                themeColor: themeColor,
                onSelected: (val) {
                  setState(() {
                    _selectedCategory = val;
                    if (val != 'Otros' && val != 'Otro') {
                      _categoryController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Expandable manual Category input if 'Otros' is active
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: (_selectedCategory == 'Otros' || _selectedCategory == 'Otro')
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _categoryController,
                          style: const TextStyle(color: GodfatherTheme.textLight),
                          decoration: InputDecoration(
                            labelText: isGasto ? 'Categoría personalizada' : 'Origen del abono',
                            prefixIcon: const Icon(Icons.category_outlined, color: GodfatherTheme.primaryGold),
                            helperText: 'Especifica la categoría manual o concepto.',
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Optional Note field
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Nota o comentario (Opcional)',
                  prefixIcon: Icon(Icons.rate_review_outlined, color: GodfatherTheme.primaryGold),
                ),
              ),
              const SizedBox(height: 28),

              // Main CTA Action Button (Dynamic style & color based on operation)
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: buttonColor.withValues(alpha: 0.4),
                  elevation: 8,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        buttonText,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
