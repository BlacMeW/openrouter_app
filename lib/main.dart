import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'bloc/chat_bloc.dart';
import 'providers/theme_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/model_management_screen.dart';
import 'screens/settings_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        BlocProvider(create: (_) => ChatBloc()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AI Coder Chat',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const ChatScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/models': (context) => const ModelManagementScreen(),
            },
          );
        },
      ),
    );
  }
}
