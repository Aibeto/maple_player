import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/app_state.dart';
import 'services/player_service.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await PlayerService().init();

  final appState = AppState();
  await appState.init();

  runApp(
    LiquidGlassWidgets.wrap(
      child: ChangeNotifierProvider.value(
        value: appState,
        child: const MaplePlayerApp(),
      ),
    ),
  );
}

class MaplePlayerApp extends StatelessWidget {
  const MaplePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassTheme(
      data: AppTheme.glassTheme(),
      child: MaterialApp(
        title: 'Maple Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: AppTheme.fontFamily,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.transparent,
        ),
        darkTheme: ThemeData(
          fontFamily: AppTheme.fontFamily,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.transparent,
        ),
        themeMode: ThemeMode.dark,
        home: const HomePage(),
      ),
    );
  }
}
