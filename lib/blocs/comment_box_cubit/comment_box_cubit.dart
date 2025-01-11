import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/enums.dart';

part 'comment_box_state.dart';

class CommentBoxCubit extends Cubit<CommentBoxState> {
  CommentBoxCubit()
      : super(CommentBoxState(
          status: CommentPrefixStatus.notSet,
        )) {
    setCommentPrefixStatus();
  }

  void setCommentPrefixStatus() async {
    final usePrefix = await localDatabaseRepository.getPrefix();
    final status = usePrefix == null
        ? CommentPrefixStatus.notSet
        : usePrefix
            ? CommentPrefixStatus.used
            : CommentPrefixStatus.notUsed;

    if (!isClosed)
      emit(
        state.copyWith(
          status: status,
        ),
      );
  }

  Future<void> updateCommentPrefixStatus(bool status) async {
    await localDatabaseRepository.setPrefix(status);

    if (!isClosed)
      emit(
        state.copyWith(
          status:
              status ? CommentPrefixStatus.used : CommentPrefixStatus.notUsed,
        ),
      );
  }
}
