import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required this.localDatabaseRepository,
  }) : super(
          ThemeState(
            textScaleFactor: localDatabaseRepository.getTextScaleFactor(),
            theme: AppTheme.purpleDark,
          ),
        ) {
    initTheme();
  }

  final LocalDatabaseRepository localDatabaseRepository;

  void initTheme() async {
    final theme = await localDatabaseRepository.isLightTheme();

    if (theme) {
      enableLightEasyLoading();
    } else {
      enableDarkEasyLoading();
    }

    if (!isClosed)
      emit(
        state.copyWith(
          theme: theme ? AppTheme.purpleWhite : AppTheme.purpleDark,
        ),
      );
  }

  void setTextScaleFactor(double tsf) {
    localDatabaseRepository.setTextScaleFactor(tsf);
    emit(
      state.copyWith(
        textScaleFactor: tsf,
      ),
    );
  }

  void toggleTheme() {
    localDatabaseRepository.setTheme(state.theme == AppTheme.purpleDark);

    if (!isClosed)
      emit(
        state.copyWith(
          theme: state.theme == AppTheme.purpleDark
              ? AppTheme.purpleWhite
              : AppTheme.purpleDark,
        ),
      );
  }

  void enableLightEasyLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..maskColor = Colors.grey.withValues(alpha: 0.3)
      ..loadingStyle = EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..animationStyle = EasyLoadingAnimationStyle.scale
      ..radius = kDefaultPadding - 5
      ..progressColor = kPurple
      ..dismissOnTap = false;
  }

  void enableDarkEasyLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..maskColor = Colors.black.withValues(alpha: 0.4)
      ..loadingStyle = EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..animationStyle = EasyLoadingAnimationStyle.scale
      ..radius = kDefaultPadding - 5
      ..progressColor = kPurple
      ..dismissOnTap = false;
  }
}
