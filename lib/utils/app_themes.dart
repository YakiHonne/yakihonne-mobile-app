import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class AppThemes {
  static final appLightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Montserrat',
    useMaterial3: true,
    scaffoldBackgroundColor: kWhite,
    primaryColor: kPurple,
    primaryColorLight: kLightBgGrey,
    primaryColorDark: kBlack,
    shadowColor: kLightGrey,
    hintColor: kDimGrey,
    highlightColor: kLightGrey,
    unselectedWidgetColor: kDimGrey,
    appBarTheme: AppBarTheme(
      backgroundColor: kWhite,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: kTransparent,
      shadowColor: kWhite,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kPurple,
      foregroundColor: kWhite,
    ),
    scrollbarTheme: ScrollbarThemeData(
      trackColor: WidgetStateProperty.all(kLightGrey),
      thumbColor: WidgetStateProperty.all(kPurple),
      thickness: WidgetStateProperty.all(3),
      radius: Radius.circular(kDefaultPadding),
      interactive: true,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        alignment: Alignment.center,
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
        ),
        shape: const StadiumBorder(),
        backgroundColor: kPurple,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 14,
        fontFamily: 'Montserrat',
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kLightBgGrey,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 1.5,
      ),
      labelStyle: const TextStyle(
        color: kDimGrey,
      ),
      errorStyle: TextStyle(color: kRed),
      isDense: true,
      hintStyle: TextStyle(
        color: kDimGrey,
        fontFamily: 'Montserrat',
        fontSize: 14,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kTransparent,
          width: 0.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kRed,
          width: 0.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kTransparent,
          width: 0.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kRed,
          width: 0.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kDimGrey,
          width: 0.5,
        ),
      ),
    ),
  );

  static final appDarkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Montserrat',
    highlightColor: kDimGrey2,
    useMaterial3: true,
    scaffoldBackgroundColor: kDarkGrey,
    primaryColor: kPurple,
    primaryColorDark: kWhite,
    primaryColorLight: kDimBgGrey,
    shadowColor: kBlack.withValues(alpha: 0.2),
    unselectedWidgetColor: kDimGrey2,
    hintColor: kLightGrey,
    appBarTheme: AppBarTheme(
      backgroundColor: kDarkGrey,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: kTransparent,
      shadowColor: kBlack,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kPurple,
      foregroundColor: kWhite,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        alignment: Alignment.center,
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
        ),
        shape: const StadiumBorder(),
        backgroundColor: kPurple,
        foregroundColor: kWhite,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      trackColor: WidgetStateProperty.all(kLightGrey),
      thumbColor: WidgetStateProperty.all(kPurple),
      thickness: WidgetStateProperty.all(3),
      radius: Radius.circular(kDefaultPadding),
      interactive: true,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 12,
        fontFamily: 'Montserrat',
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDimBgGrey,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 1.5,
      ),
      labelStyle: const TextStyle(
        color: kDimGrey,
      ),
      isDense: true,
      hintStyle: TextStyle(
        color: kDimGrey,
        fontFamily: 'Montserrat',
        fontSize: 14,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kTransparent,
          width: 0.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kRed,
          width: 0.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kTransparent,
          width: 0.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kRed,
          width: 0.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding - 5),
        borderSide: const BorderSide(
          color: kDimGrey,
          width: 0.5,
        ),
      ),
    ),
  );
}
