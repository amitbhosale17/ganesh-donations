import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/auth_service.dart';
import 'core/language_service.dart';
import 'features/login/login_page.dart';
import 'features/language/language_selection_page.dart';
import 'features/collector/collector_home.dart';
import 'features/admin/admin_home.dart';
import 'features/superadmin/superadmin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize auth service
  await AuthService.init();
  final user = AuthService.getCurrentUser();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: MyApp(initialRole: user?['role']),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  
  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return MaterialApp(
          title: 'गणेश दान व्यवस्थापन',
          debugShowCheckedModeBanner: false,
          locale: languageService.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('mr'),
          ],
          theme: ThemeData(
            primarySwatch: Colors.orange,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 2,
            ),
          ),
          home: _getInitialPage(languageService),
        );
      },
    );
  }
  
  Widget _getInitialPage(LanguageService languageService) {
    // Show language selection if not selected yet
    if (!languageService.isLanguageSelected) {
      return const LanguageSelectionPage();
    }
    
    // Show appropriate home based on role
    if (initialRole == null) {
      return const LoginPage();
    }
    
    if (initialRole == 'SUPERADMIN') {
      return const SuperAdminHome();
    } else if (initialRole == 'ADMIN') {
      return const AdminHome();
    } else {
      return const CollectorHome();
    }
  }
}
