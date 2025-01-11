// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final AppTheme theme;
  final double textScaleFactor;

  const ThemeState({
    required this.theme,
    required this.textScaleFactor,
  });

  @override
  List<Object> get props => [theme, textScaleFactor];

  ThemeState copyWith({
    AppTheme? theme,
    double? textScaleFactor,
  }) {
    return ThemeState(
      theme: theme ?? this.theme,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }
}
