// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authentication_cubit.dart';

class AuthenticationState extends Equatable {
  final AuthenticationViews signupView;
  final String authPubKey;
  final String authPrivKey;
  final int selectedProfileImage;
  final File? localImage;
  final String imageLink;
  final PicturesType picturesType;

  AuthenticationState({
    required this.signupView,
    required this.authPubKey,
    required this.authPrivKey,
    required this.selectedProfileImage,
    required this.imageLink,
    required this.picturesType,
    this.localImage,
  });

  @override
  List<Object> get props => [
        signupView,
        authPrivKey,
        authPubKey,
        selectedProfileImage,
        imageLink,
        picturesType,
      ];

  AuthenticationState copyWith({
    AuthenticationViews? signupView,
    String? authPubKey,
    String? authPrivKey,
    int? selectedProfileImage,
    File? localImage,
    String? imageLink,
    PicturesType? picturesType,
  }) {
    return AuthenticationState(
      signupView: signupView ?? this.signupView,
      authPubKey: authPubKey ?? this.authPubKey,
      authPrivKey: authPrivKey ?? this.authPrivKey,
      selectedProfileImage: selectedProfileImage ?? this.selectedProfileImage,
      localImage: localImage ?? this.localImage,
      imageLink: imageLink ?? this.imageLink,
      picturesType: picturesType ?? this.picturesType,
    );
  }
}
