import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/transaction.dart';
import '../services/vocal_parser.dart';

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
  final _categoryController = TextEditingController();

  late TransactionType _type;
  TargetModule _target = TargetModule.personal;
  bool _isLoading = false;

  // Speech to Text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
    _target = _type == TransactionType.abono ? TargetModule.casa : TargetModule.personal;
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _conceptController.dispose();
    _categoryController.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error de dictado: ${val.errorString}'),
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
          localeId: 'es_PE', // Forzar español latinoamericano
        );
      } else {
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

  // Procesa el texto dictado
  void _processVoiceInput(String text) {
    if (text.isEmpty) return;
    
    final result = VocalParser.parse(text);
    
    setState(() {
      _amountController.text = result.amount > 0 ? result.amount.toStringAsFixed(2) : '';
      _conceptController.text = result.concept;
      _categoryController.text = result.category;
      _type = result.type;
      _target = result.target;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Analizado: S/. ${result.amount.toStringAsFixed(2)} en "${result.concept}" (${result.category})'),
        backgroundColor: GodfatherTheme.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      final concept = _conceptController.text.trim();
      // Si la categoría está vacía, usar una por defecto según el módulo
      final category = _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : (_target == TargetModule.casa ? 'Servicios' : 'Caja Chica');

      await ref.read(transactionProvider.notifier).addTransaction(
            amount: amount,
            concept: concept,
            category: category,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGasto = _type == TransactionType.gasto;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior de arrastre / Título
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isGasto ? 'REGISTRAR GASTO' : 'REGISTRAR ABONO',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: GodfatherTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  // Botón de Dictado por Voz (Micrófono)
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? GodfatherTheme.alertRed.withOpacity(0.2)
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
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Dictado: "$_voiceText"',
                    style: const TextStyle(
                      color: GodfatherTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Selector Gasto / Abono
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('GASTO (SALIDA)'),
                      selected: isGasto,
                      selectedColor: GodfatherTheme.alertRed.withOpacity(0.25),
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(
                        color: isGasto ? GodfatherTheme.alertRed : GodfatherTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isGasto ? GodfatherTheme.alertRed : const Color(0xFF2C2C30),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = TransactionType.gasto;
                            _target = TargetModule.personal;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('ABONO (INGRESO)'),
                      selected: !isGasto,
                      selectedColor: GodfatherTheme.successGreen.withOpacity(0.25),
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(
                        color: !isGasto ? GodfatherTheme.successGreen : GodfatherTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: !isGasto ? GodfatherTheme.successGreen : const Color(0xFF2C2C30),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = TransactionType.abono;
                            _target = TargetModule.casa;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selector Módulo (Personal / Casa)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('PERSONAL (CAJA CHICA)'),
                      selected: _target == TargetModule.personal,
                      selectedColor: GodfatherTheme.primaryGold.withOpacity(0.2),
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(
                        color: _target == TargetModule.personal ? GodfatherTheme.primaryGold : GodfatherTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _target == TargetModule.personal ? GodfatherTheme.primaryGold : const Color(0xFF2C2C30),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _target = TargetModule.personal);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('CASA (COMPARTIDO)'),
                      selected: _target == TargetModule.casa,
                      selectedColor: GodfatherTheme.primaryGold.withOpacity(0.2),
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(
                        color: _target == TargetModule.casa ? GodfatherTheme.primaryGold : GodfatherTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _target == TargetModule.casa ? GodfatherTheme.primaryGold : const Color(0xFF2C2C30),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _target = TargetModule.casa);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Input de Monto
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Monto (S/.)',
                  prefixIcon: Icon(Icons.calculate_outlined, color: GodfatherTheme.primaryGold),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el monto';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input de Concepto
              TextFormField(
                controller: _conceptController,
                style: const TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Concepto (Ej. Luz, Cine, Almuerzo)',
                  prefixIcon: Icon(Icons.description_outlined, color: GodfatherTheme.primaryGold),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el concepto de la transacción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Input de Categoría (Auto-completado o Manual)
              TextFormField(
                controller: _categoryController,
                style: const TextStyle(color: GodfatherTheme.textLight),
                decoration: const InputDecoration(
                  labelText: 'Categoría (Ej. Servicios, Alimentación)',
                  prefixIcon: Icon(Icons.category_outlined, color: GodfatherTheme.primaryGold),
                  helperText: 'Se auto-designa por voz. Opcional en manual.',
                ),
              ),
              const SizedBox(height: 32),

              // Botón de confirmación
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(GodfatherTheme.backgroundBlack),
                        ),
                      )
                    : const Text('CONFIRMAR REGISTRO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
