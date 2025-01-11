// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'detailed_note_cubit.dart';

class DetailedNoteState extends Equatable {
  final DetailedNoteModel note;
  final List<DetailedNoteModel> replies;
  final List<DetailedNoteModel> previousNotes;
  final List<String> mutes;
  final Map<String, VoteModel> votes;
  final Map<String, double> zaps;

  DetailedNoteState({
    required this.note,
    required this.replies,
    required this.previousNotes,
    required this.mutes,
    required this.votes,
    required this.zaps,
  });

  @override
  List<Object> get props => [
        note,
        replies,
        previousNotes,
        mutes,
        votes,
        zaps,
      ];

  DetailedNoteState copyWith({
    DetailedNoteModel? note,
    List<DetailedNoteModel>? replies,
    List<DetailedNoteModel>? previousNotes,
    List<String>? mutes,
    Map<String, VoteModel>? votes,
    Map<String, double>? zaps,
  }) {
    return DetailedNoteState(
      note: note ?? this.note,
      replies: replies ?? this.replies,
      previousNotes: previousNotes ?? this.previousNotes,
      mutes: mutes ?? this.mutes,
      votes: votes ?? this.votes,
      zaps: zaps ?? this.zaps,
    );
  }
}
