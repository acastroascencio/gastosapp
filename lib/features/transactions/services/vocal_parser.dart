import '../../../models/transaction.dart';

class ParsedResult {
  final double amount;
  final String concept;
  final String category;
  final TransactionType type;
  final TargetModule target;

  ParsedResult({
    required this.amount,
    required this.concept,
    required this.category,
    required this.type,
    required this.target,
  });

  @override
  String toString() {
    return 'ParsedResult(amount: $amount, concept: $concept, category: $category, type: $type, target: $target)';
  }
}

class VocalParser {
  // Lista de palabras clave para categorizar en Servicios/Gastos de Casa
  static const List<String> _casaKeywords = [
    'luz', 'agua', 'internet', 'alquiler', 'servicio', 'servicios', 'cable', 
    'telefono', 'teléfono', 'gas', 'mantenimiento', 'arbitrios', 'electricidad'
  ];

  // Lista de palabras clave para clasificar como Abono/Ingreso
  static const List<String> _abonoKeywords = [
    'abono', 'abone', 'ingreso', 'sueldo', 'pago', 'recibi', 'recibí', 
    'deposito', 'depósito', 'ganancia', 'transferencia'
  ];

  /// Analiza una frase en lenguaje natural para extraer monto, concepto y categorizarla.
  static ParsedResult parse(String text) {
    final cleanText = text.toLowerCase().trim();
    
    // 1. Extraer el monto (número entero o decimal)
    // Busca números como 25, 25.50, 1000, 1,200.50
    final RegExp amountRegex = RegExp(r'(\d+([.,]\d+)?)');
    final match = amountRegex.firstMatch(cleanText);
    
    double amount = 0.0;
    String matchedNumberStr = '';
    
    if (match != null) {
      matchedNumberStr = match.group(0) ?? '';
      // Normalizar comas a puntos para parsear a double
      final normalizedStr = matchedNumberStr.replaceAll(',', '.');
      amount = double.tryParse(normalizedStr) ?? 0.0;
    }

    // 2. Extraer el concepto limpiando el número y conectores comunes en los extremos
    String concept = cleanText;
    if (matchedNumberStr.isNotEmpty) {
      // Reemplazar el número por un marcador de espacio
      concept = concept.replaceFirst(matchedNumberStr, ' ');
    }

    // Conjunto de palabras que se consideran ruido al inicio o al final
    final Set<String> edgeNoise = {
      'soles', 'dolares', 'dólares', 'pesos', 'de', 'en', 'por', 'para', 'un', 'una',
      'el', 'la', 'los', 'las', 'del', 'al', 'gasto', 'gasté', 'gaste', 'abono', 
      'abone', 'ingreso', 'comprado', 'compra', 'compré', 'compre', 'recibí', 'recibi',
      'pagué', 'pague'
    };

    List<String> words = concept.split(RegExp(r'\s+'));
    // Limpiar elementos vacíos
    words = words.map((w) => w.trim()).where((w) => w.isNotEmpty).toList();

    // Eliminar palabras de ruido del INICIO recursivamente
    while (words.isNotEmpty && edgeNoise.contains(words.first)) {
      words.removeAt(0);
    }

    // Eliminar palabras de ruido del FINAL recursivamente
    while (words.isNotEmpty && edgeNoise.contains(words.last)) {
      words.removeLast();
    }

    concept = words.join(' ').trim();
    if (concept.isEmpty) {
      concept = 'Concepto sin definir';
    } else {
      // Capitalizar la primera letra del concepto
      concept = concept[0].toUpperCase() + concept.substring(1);
    }

    // Obtener lista de palabras limpias para búsqueda de palabras clave exactas
    final cleanWords = cleanText
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // 3. Determinar el Tipo de Transacción (Abono o Gasto)
    TransactionType type = TransactionType.gasto;
    for (final keyword in _abonoKeywords) {
      if (cleanWords.contains(keyword)) {
        type = TransactionType.abono;
        break;
      }
    }

    // 4. Determinar el Módulo de Destino (Personal o Casa) y Categoría
    TargetModule target = TargetModule.personal;
    String category = 'Otros';

    // Si es abono, en general va a "Casa" (Abonos recibidos del Padre responsable)
    // O si contiene palabras clave de Casa, se destina a Casa
    bool isCasa = false;
    for (final keyword in _casaKeywords) {
      if (cleanWords.contains(keyword)) {
        isCasa = true;
        category = 'Servicios del Hogar';
        break;
      }
    }

    if (isCasa) {
      target = TargetModule.casa;
    } else if (type == TransactionType.abono) {
      target = TargetModule.casa; // Por defecto el abono suma a la caja de la casa
      category = 'Ingresos del Hogar';
    } else {
      target = TargetModule.personal;
      
      // Determinar la categoría según la palabra clave que aparezca PRIMERO en la frase (más descriptiva)
      final List<String> alimentacionKw = ['comida', 'cena', 'almuerzo', 'desayuno', 'restaurante', 'alimentos'];
      final List<String> entretenimientoKw = ['cine', 'salida', 'bar', 'fiesta', 'cerveza', 'diversion', 'diversión'];
      final List<String> ropaKw = ['ropa', 'zapatos', 'camisa', 'vestido', 'pantalón', 'pantalon', 'polo'];
      final List<String> transporteKw = ['taxi', 'uber', 'pasaje', 'bus', 'gasolina', 'combustible', 'pasajes'];

      int firstAlim = _findFirstWordIndex(cleanWords, alimentacionKw);
      int firstEntr = _findFirstWordIndex(cleanWords, entretenimientoKw);
      int firstRopa = _findFirstWordIndex(cleanWords, ropaKw);
      int firstTrans = _findFirstWordIndex(cleanWords, transporteKw);

      int minIndex = 999999;
      String winningCategory = 'Caja Chica';

      if (firstAlim >= 0 && firstAlim < minIndex) {
        minIndex = firstAlim;
        winningCategory = 'Alimentación';
      }
      if (firstEntr >= 0 && firstEntr < minIndex) {
        minIndex = firstEntr;
        winningCategory = 'Entretenimiento';
      }
      if (firstRopa >= 0 && firstRopa < minIndex) {
        minIndex = firstRopa;
        winningCategory = 'Ropa y Calzado';
      }
      if (firstTrans >= 0 && firstTrans < minIndex) {
        minIndex = firstTrans;
        winningCategory = 'Transporte';
      }

      category = winningCategory;
    }

    return ParsedResult(
      amount: amount,
      concept: concept,
      category: category,
      type: type,
      target: target,
    );
  }

  // Encuentra el primer índice donde aparece cualquiera de las palabras clave
  static int _findFirstWordIndex(List<String> words, List<String> keywords) {
    int firstIndex = -1;
    for (final kw in keywords) {
      int idx = words.indexOf(kw);
      if (idx >= 0) {
        if (firstIndex == -1 || idx < firstIndex) {
          firstIndex = idx;
        }
      }
    }
    return firstIndex;
  }
}
