import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider()..initialize(),
        ),
      ],
      child: const GremoryApp(),
    ),
  );
}

class GremoryApp extends StatelessWidget {
  const GremoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gremory AI',
      theme: AppTheme.lightTheme,
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
