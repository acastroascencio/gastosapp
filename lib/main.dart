import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/supabase_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase con las credenciales del proyecto de Mario Castro
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Inicializar formato de fechas local para español (soles, meses)
  await initializeDateFormatting('es_PE', null);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'The Godfather Finanzas',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: GodfatherTheme.lightTheme,
      darkTheme: GodfatherTheme.darkTheme,
      home: authState.when(
        data: (session) {
          if (session.session != null) {
            return const DashboardScreen();
          } else {
            return const LoginScreen();
          }
        },
        loading: () => Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(GodfatherTheme.primaryGold),
            ),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text(
              'Error en la conexión con Supabase: $error',
              style: TextStyle(color: GodfatherTheme.alertRed),
            ),
          ),
        ),
      ),
    );
  }
}
