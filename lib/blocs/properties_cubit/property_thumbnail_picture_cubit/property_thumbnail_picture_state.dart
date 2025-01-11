// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'property_thumbnail_picture_cubit.dart';

class PropertyThumbnailPictureState extends Equatable {
  final bool isLocalImage;
  final bool isImageSelected;
  final File? localImage;
  final String imageLink;

  PropertyThumbnailPictureState({
    required this.isLocalImage,
    required this.isImageSelected,
    this.localImage,
    required this.imageLink,
  });

  @override
  List<Object> get props => [
        isLocalImage,
        imageLink,
        isImageSelected,
      ];

  PropertyThumbnailPictureState copyWith({
    bool? isLocalImage,
    bool? isImageSelected,
    File? localImage,
    String? imageLink,
  }) {
    return PropertyThumbnailPictureState(
      isLocalImage: isLocalImage ?? this.isLocalImage,
      isImageSelected: isImageSelected ?? this.isImageSelected,
      localImage: localImage ?? this.localImage,
      imageLink: imageLink ?? this.imageLink,
    );
  }
}
