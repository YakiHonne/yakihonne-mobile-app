// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class ProfilePicture extends StatelessWidget {
  ProfilePicture({
    super.key,
    required this.size,
    required this.image,
    required this.padding,
    required this.strokeWidth,
    this.isLocal,
    this.file,
  });

  final double size;
  final String image;
  final double padding;
  final double strokeWidth;
  final bool? isLocal;
  final File? file;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: strokeWidth, color: kPurple),
        color: kTransparent,
      ),
      child: isLocal != null
          ? ClipOval(
              child: Image.file(
                file!,
                fit: BoxFit.cover,
              ),
            )
          : image.isEmpty
              ? profileHolder(context)
              : CachedNetworkImage(
                  imageUrl: image,
                  cacheManager: cacheManager,
                  fit: BoxFit.cover,
                  memCacheHeight: size.toInt(),
                  memCacheWidth: size.toInt(),
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(300),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => profileHolder(context),
                ),
    );
  }

  Container profileHolder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          FeatureIcons.image,
          width: size / 4,
          height: size / 4,
          fit: BoxFit.scaleDown,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class ProfilePicture2 extends StatelessWidget {
  const ProfilePicture2({
    Key? key,
    required this.size,
    required this.image,
    required this.placeHolder,
    required this.padding,
    required this.strokeWidth,
    required this.strokeColor,
    required this.onClicked,
    this.backgroundColor,
    this.reduceSize,
  }) : super(key: key);

  final double size;
  final String image;
  final String placeHolder;
  final double padding;
  final double strokeWidth;
  final Color strokeColor;
  final Color? backgroundColor;
  final bool? reduceSize;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: size,
        width: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: strokeWidth, color: strokeColor),
          color: backgroundColor ?? Theme.of(context).primaryColorLight,
        ),
        child: image.isEmpty
            ? errorContainer(context)
            : CachedNetworkImage(
                height: size,
                width: size,
                imageUrl: image,
                cacheManager: cacheManager,
                filterQuality: FilterQuality.medium,
                fit: BoxFit.cover,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(300),
                    image: DecorationImage(
                      image: imageProvider,
                      filterQuality: FilterQuality.high,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    shape: BoxShape.circle,
                  ),
                ),
                errorWidget: (context, url, error) => errorContainer(context),
              ),
      ),
    );
  }

  Container errorContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(
            placeHolder,
          ),
        ),
      ),
    );
  }
}

class ProfilePicture3 extends StatelessWidget {
  const ProfilePicture3({
    Key? key,
    required this.size,
    required this.image,
    required this.placeHolder,
    required this.padding,
    required this.strokeWidth,
    required this.strokeColor,
    required this.onClicked,
    this.backgroundColor,
    this.reduceSize,
  }) : super(key: key);

  final double size;
  final String image;
  final String placeHolder;
  final double padding;
  final double strokeWidth;
  final Color strokeColor;
  final Color? backgroundColor;
  final bool? reduceSize;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: size,
        width: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(width: strokeWidth, color: strokeColor),
          color: backgroundColor ?? Theme.of(context).primaryColorLight,
        ),
        child: image.isEmpty
            ? errorContainer(context)
            : CachedNetworkImage(
                height: size,
                width: size,
                imageUrl: image,
                cacheManager: cacheManager,
                filterQuality: FilterQuality.medium,
                fit: BoxFit.cover,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    image: DecorationImage(
                      image: imageProvider,
                      filterQuality: FilterQuality.high,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    shape: BoxShape.circle,
                  ),
                ),
                errorWidget: (context, url, error) => errorContainer(context),
              ),
      ),
    );
  }

  Container errorContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        image: DecorationImage(
          image: AssetImage(
            placeHolder,
          ),
        ),
      ),
    );
  }
}
