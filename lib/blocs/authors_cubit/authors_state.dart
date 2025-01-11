// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authors_cubit.dart';

class AuthorsState extends Equatable {
  final Map<String, UserModel> authors;
  final Map<String, bool> nip05Validations;

  AuthorsState({
    required this.authors,
    required this.nip05Validations,
  });

  @override
  List<Object> get props => [
        authors,
        nip05Validations,
      ];

  AuthorsState copyWith({
    Map<String, UserModel>? authors,
    Map<String, bool>? nip05Validations,
  }) {
    return AuthorsState(
      authors: authors ?? this.authors,
      nip05Validations: nip05Validations ?? this.nip05Validations,
    );
  }
}
