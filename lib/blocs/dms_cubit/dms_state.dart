// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'dms_cubit.dart';

class DmsState extends Equatable {
  final Map<String, DMSessionDetail> dmSessionDetails;
  final bool isUsingNip44;
  final int index;
  final bool rebuild;
  final List<String> mutes;
  final bool isSendingMessage;

  DmsState({
    required this.dmSessionDetails,
    required this.isUsingNip44,
    required this.index,
    required this.rebuild,
    required this.mutes,
    required this.isSendingMessage,
  });

  @override
  List<Object> get props => [
        dmSessionDetails,
        index,
        isUsingNip44,
        rebuild,
        mutes,
        isSendingMessage,
      ];

  DmsState copyWith({
    Map<String, DMSessionDetail>? dmSessionDetails,
    bool? isUsingNip44,
    int? index,
    bool? rebuild,
    List<String>? mutes,
    bool? isSendingMessage,
  }) {
    return DmsState(
      dmSessionDetails: dmSessionDetails ?? this.dmSessionDetails,
      isUsingNip44: isUsingNip44 ?? this.isUsingNip44,
      index: index ?? this.index,
      rebuild: rebuild ?? this.rebuild,
      mutes: mutes ?? this.mutes,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }
}
