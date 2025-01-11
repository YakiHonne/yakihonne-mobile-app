// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';

class GalleryImage extends StatelessWidget {
  const GalleryImage({
    Key? key,
    required this.url,
  }) : super(key: key);

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final imageProvider = CachedNetworkImageProvider(
          url,
        );

        showImageViewer(
          context,
          imageProvider,
          doubleTapZoomable: true,
          swipeDismissible: true,
        );
      },
      child: CachedNetworkImage(
        imageUrl: url,
        placeholder: (context, url) => NoMediaPlaceHolder(
          isRound: null,
          image: '',
          isError: false,
        ),
        errorWidget: (context, url, error) => NoMediaPlaceHolder(
          isRound: null,
          image: '',
          isError: false,
        ),
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
