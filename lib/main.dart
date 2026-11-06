import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/ble_provider.dart';
import 'providers/tcu_controller_provider.dart';
import 'theme/app_theme.dart';
import 'views/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置沉浸式系统状态栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
        ChangeNotifierProvider(create: (_) => TcuControllerProvider()),
      ],
      child: const YoujuApp(),
    ),
  );
}

class YoujuApp extends StatelessWidget {
  const YoujuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'youjuAPP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}
