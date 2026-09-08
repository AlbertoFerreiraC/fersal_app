import 'package:flutter/material.dart';

class FersalTheme {
  static const Color rojoFersal = Color(0xff8B1E1E);

  static const Color rosaViejo = Color(0xffC98F91);

  static const Color verdeMusgo = Color(0xff556B2F);

  static const Color negro = Color(0xff121212);

  static ThemeData light = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: rojoFersal,

      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: Colors.grey.shade100,
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: rosaViejo,

      brightness: Brightness.dark,
    ),

    scaffoldBackgroundColor: negro,
  );
}
