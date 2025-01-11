// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'property_profile_picture_cubit.dart';

class PropertyProfilePictureState extends Equatable {
  final PicturesType picturesType;
  final int selectedProfileImage;
  final File? localImage;
  final String imageLink;

  PropertyProfilePictureState({
    required this.picturesType,
    required this.selectedProfileImage,
    this.localImage,
    required this.imageLink,
  });

  @override
  List<Object> get props => [
        picturesType,
        selectedProfileImage,
        imageLink,
      ];

  PropertyProfilePictureState copyWith({
    PicturesType? picturesType,
    int? selectedProfileImage,
    File? localImage,
    String? imageLink,
  }) {
    return PropertyProfilePictureState(
      picturesType: picturesType ?? this.picturesType,
      selectedProfileImage: selectedProfileImage ?? this.selectedProfileImage,
      localImage: localImage ?? this.localImage,
      imageLink: imageLink ?? this.imageLink,
    );
  }
}
