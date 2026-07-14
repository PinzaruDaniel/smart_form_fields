import 'package:flutter/material.dart';
import 'package:smart_form_fields/smart_form_fields.dart';

import 'screens/example_home_screen.dart';

class SmartFormFieldsExampleApp extends StatelessWidget {
  const SmartFormFieldsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF315C4C);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Form Fields example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const SmartFormTheme(
        data: SmartFormThemeData(errorAnimation: SmartErrorAnimation.fade),
        child: ExampleHomeScreen(),
      ),
    );
  }
}
