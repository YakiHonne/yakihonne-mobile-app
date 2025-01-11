import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';

part 'disclosure_state.dart';

class DisclosureCubit extends Cubit<DisclosureState> {
  DisclosureCubit({
    required this.localDatabaseRepository,
  }) : super(
          DisclosureState(
            isAnalyticsEnabled:
                localDatabaseRepository.getAnalyticsDataCollection(),
          ),
        ) {
    localDatabaseRepository.getDisclosureStatus();
  }

  final LocalDatabaseRepository localDatabaseRepository;

  void setAnalyticsStatus(bool status) {
    localDatabaseRepository.setAnalyticsDataCollection(status);

    if (!isClosed)
      emit(
        state.copyWith(
          isAnalyticsEnabled: status,
        ),
      );
  }
}
