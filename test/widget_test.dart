import 'package:flutter_test/flutter_test.dart';
import 'package:gastosapp/features/transactions/services/vocal_parser.dart';
import 'package:gastosapp/models/transaction.dart';

void main() {
  group('Pruebas Unitarias del VocalParser - Heurística e Inteligencia de Voz', () {
    
    test('Prueba 1: Debe extraer gasto en soles para casa (Servicios)', () {
      final frase = "gasto 45.50 soles en internet de claro";
      final resultado = VocalParser.parse(frase);

      expect(resultado.amount, 45.50);
      expect(resultado.concept, "Internet de claro");
      expect(resultado.type, TransactionType.gasto);
      expect(resultado.target, TargetModule.casa);
      expect(resultado.category, "Servicios del Hogar");
    });

    test('Prueba 2: Debe extraer abono de sueldo del padre', () {
      final frase = "recibí abono de 2500 por sueldo de la empresa";
      final resultado = VocalParser.parse(frase);

      expect(resultado.amount, 2500.0);
      expect(resultado.concept, "Sueldo de la empresa");
      expect(resultado.type, TransactionType.abono);
      expect(resultado.target, TargetModule.casa);
      expect(resultado.category, "Ingresos del Hogar");
    });

    test('Prueba 3: Debe clasificar gasto personal (Transporte)', () {
      final frase = "gasté 18.00 soles en un taxi para ir al cine";
      final resultado = VocalParser.parse(frase);

      expect(resultado.amount, 18.0);
      expect(resultado.concept, "Taxi para ir al cine");
      expect(resultado.type, TransactionType.gasto);
      expect(resultado.target, TargetModule.personal);
      expect(resultado.category, "Transporte");
    });

    test('Prueba 4: Debe clasificar gasto personal (Alimentación)', () {
      final frase = "35 soles en comida rápida almuerzo";
      final resultado = VocalParser.parse(frase);

      expect(resultado.amount, 35.0);
      expect(resultado.concept, "Comida rápida almuerzo");
      expect(resultado.type, TransactionType.gasto);
      expect(resultado.target, TargetModule.personal);
      expect(resultado.category, "Alimentación");
    });
  });
}
