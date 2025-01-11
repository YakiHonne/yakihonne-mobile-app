// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';

class ArticleThumbnail extends StatelessWidget {
  const ArticleThumbnail({
    Key? key,
    required this.image,
    required this.placeholder,
    required this.width,
    required this.height,
    this.radius,
    this.isRound,
  }) : super(key: key);

  final String image;
  final String placeholder;
  final double width;
  final double height;
  final double? radius;
  final bool? isRound;

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) {
      return Container(
        width: width,
        height: height == 0 ? null : height,
        child: NoMediaPlaceHolder(
          isRound: isRound,
          image: placeholder,
          isError: true,
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: image,
        width: width,
        height: height == 0 ? null : height,
        cacheManager: cacheManager,
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                radius ?? kDefaultPadding,
              ),
              border: radius != null
                  ? null
                  : Border.all(
                      color: Theme.of(context).primaryColorLight,
                    ),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
        placeholder: (context, url) => NoMediaPlaceHolder(
          isRound: isRound,
          image: '',
          isError: false,
          value: radius,
        ),
        errorWidget: (context, url, error) => NoMediaPlaceHolder(
          isRound: isRound,
          image: placeholder,
          isError: true,
          value: radius,
        ),
      );
    }
  }
}

class ArticleThumbnail2 extends StatelessWidget {
  const ArticleThumbnail2({
    Key? key,
    required this.image,
    required this.placeholder,
    required this.width,
    required this.height,
  }) : super(key: key);

  final String image;
  final String placeholder;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) {
      return Container(
        width: width,
        height: height,
        child: NoMediaPlaceHolder(
          isTopRounded: true,
          image: placeholder,
          isError: true,
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: image,
        width: width,
        height: height,
        cacheManager: cacheManager,
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              ),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
        placeholder: (context, url) => NoMediaPlaceHolder(
          isTopRounded: true,
          image: '',
          isError: false,
        ),
        errorWidget: (context, url, error) => NoMediaPlaceHolder(
          isTopRounded: true,
          image: placeholder,
          isError: true,
        ),
      );
    }
  }
}
