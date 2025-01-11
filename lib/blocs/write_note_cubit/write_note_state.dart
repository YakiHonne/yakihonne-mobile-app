// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_note_cubit.dart';

class WriteNoteState extends Equatable {
  final List<String> images;
  final List<SmartWidgetModel> widgets;
  final DetailedNoteModel? quotedNote;
  final DetailedNoteModel? replyNote;
  final bool isQuotedNoteAvailable;

  WriteNoteState({
    required this.images,
    required this.widgets,
    this.quotedNote,
    this.replyNote,
    required this.isQuotedNoteAvailable,
  });

  @override
  List<Object> get props => [
        images,
        isQuotedNoteAvailable,
        widgets,
      ];

  WriteNoteState copyWith({
    List<String>? images,
    List<SmartWidgetModel>? widgets,
    DetailedNoteModel? quotedNote,
    DetailedNoteModel? replyNote,
    bool? isQuotedNoteAvailable,
  }) {
    return WriteNoteState(
      images: images ?? this.images,
      widgets: widgets ?? this.widgets,
      quotedNote: quotedNote ?? this.quotedNote,
      replyNote: replyNote ?? this.replyNote,
      isQuotedNoteAvailable:
          isQuotedNoteAvailable ?? this.isQuotedNoteAvailable,
    );
  }
}
