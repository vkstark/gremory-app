import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'providers/chat_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        home: ChatScreen(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
