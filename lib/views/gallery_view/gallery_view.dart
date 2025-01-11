import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/views/gallery_view/gallery_image_viewer.dart';
import 'package:yakihonne/views/gallery_view/multi_image_provider.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';

class GalleryImageView extends StatelessWidget {
  /// The image to display
  final List<CachedNetworkImageProvider> listImage;

  /// The gallery width
  final double width;

  /// The gallery height
  final double height;

  /// The image BoxDecoration
  final BoxDecoration? imageDecoration;

  /// The image BoxFit
  final BoxFit boxFit;

  /// The Gallery short image is maximum 4 images.
  final bool shortImage;

  /// Font size
  final double fontSize;

  /// Text color
  final Color textColor;

  final Color seperatorColor;

  final Function(String) onDownload;

  const GalleryImageView(
      {Key? key,
      required this.listImage,
      this.boxFit = BoxFit.cover,
      this.imageDecoration,
      this.width = 100,
      this.height = 100,
      this.shortImage = true,
      this.fontSize = 32,
      required this.onDownload,
      required this.seperatorColor,
      this.textColor = Colors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _uiImage4(context),
    );
  }

  Widget _uiImage4(BuildContext context) {
    int imgMore = listImage.length > 4 ? listImage.length - 4 : 0;

    return AspectRatio(
      aspectRatio: height / width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      MultiImageProvider multiImageProvider =
                          MultiImageProvider(listImage, initialIndex: 0);
                      showImageViewerPager(context, multiImageProvider,
                          onDownload: onDownload,
                          backgroundColor: Colors.black.withValues(alpha: 0.3));
                    },
                    child: Container(
                      decoration: imageDecoration,
                      width: double.infinity,
                      height: double.infinity,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: listImage[0].url,
                        placeholder: (context, url) =>
                            ImageLoadingPlaceHolder(),
                        errorWidget: (context, url, error) =>
                            NoImagePlaceHolder(),
                      ),
                    ),
                  ),
                ),
                if (listImage.length > 1) ...[
                  Container(
                    height: double.infinity,
                    width: 3,
                    color: seperatorColor,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        MultiImageProvider multiImageProvider =
                            MultiImageProvider(listImage, initialIndex: 1);
                        showImageViewerPager(context, multiImageProvider,
                            onDownload: onDownload,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.3));
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: imageDecoration,
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: listImage[1].url,
                          placeholder: (context, url) =>
                              ImageLoadingPlaceHolder(),
                          errorWidget: (context, url, error) =>
                              NoImagePlaceHolder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (listImage.length > 2) ...[
            Container(
              height: 3,
              width: double.infinity,
              color: seperatorColor,
            ),
            Expanded(
              child: Row(
                children: [
                  if (listImage.length > 2)
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          MultiImageProvider multiImageProvider =
                              MultiImageProvider(listImage, initialIndex: 2);
                          showImageViewerPager(context, multiImageProvider,
                              onDownload: onDownload,
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.3));
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: imageDecoration,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: listImage[2].url,
                            placeholder: (context, url) =>
                                ImageLoadingPlaceHolder(),
                            errorWidget: (context, url, error) =>
                                NoImagePlaceHolder(),
                          ),
                        ),
                      ),
                    ),
                  if (listImage.length > 3) ...[
                    Container(
                      height: double.infinity,
                      width: 3,
                      color: seperatorColor,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          MultiImageProvider multiImageProvider =
                              MultiImageProvider(listImage, initialIndex: 3);
                          showImageViewerPager(context, multiImageProvider,
                              onDownload: onDownload,
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.3));
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: imageDecoration,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  imageUrl: listImage[3].url,
                                  placeholder: (context, url) =>
                                      ImageLoadingPlaceHolder(),
                                  errorWidget: (context, url, error) =>
                                      NoImagePlaceHolder(),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  imgMore >= 1 ? "+$imgMore" : "",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: fontSize,
                                    shadows: textShadow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

const textShadow = <Shadow>[
  Shadow(offset: Offset(-2.0, 0.0), blurRadius: 4.0, color: Colors.black54),
  Shadow(offset: Offset(0.0, 2.0), blurRadius: 4.0, color: Colors.black54),
  Shadow(offset: Offset(2.0, 0.0), blurRadius: 4.0, color: Colors.black54),
  Shadow(offset: Offset(0.0, -2.0), blurRadius: 4.0, color: Colors.black54),
];
