// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'comment_box_cubit.dart';

class CommentBoxState extends Equatable {
  final CommentPrefixStatus status;

  CommentBoxState({
    required this.status,
  });

  @override
  List<Object> get props => [status];

  CommentBoxState copyWith({
    CommentPrefixStatus? status,
  }) {
    return CommentBoxState(
      status: status ?? this.status,
    );
  }
}
