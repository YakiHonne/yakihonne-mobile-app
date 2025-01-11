// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/utils.dart';

class CameraOptions extends StatelessWidget {
  const CameraOptions({
    Key? key,
    required this.pubkey,
    required this.onFailed,
    required this.onSuccess,
    this.replyId,
  }) : super(key: key);

  final String pubkey;
  final String? replyId;
  final Function() onFailed;
  final Function() onSuccess;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
      child: Container(
        width: 100.w,
        margin: const EdgeInsets.all(kDefaultPadding),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding * 2),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    "Pick your media",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  Text(
                    'You can upload and send media right after your selection or taking them.',
                    style: TextStyle(
                      color: kDimGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: PickChoice(
                            pubkey: pubkey,
                            replyId: replyId,
                            onSuccess: onSuccess,
                            onFailed: onFailed,
                            icon: FeatureIcons.imageAttachment,
                            title: 'Image',
                            mediaType: MediaType.cameraImage,
                          ),
                        ),
                        VerticalDivider(
                          indent: kDefaultPadding / 2,
                          endIndent: kDefaultPadding / 2,
                        ),
                        Expanded(
                          child: PickChoice(
                            pubkey: pubkey,
                            replyId: replyId,
                            onSuccess: onSuccess,
                            onFailed: onFailed,
                            icon: FeatureIcons.video,
                            title: 'Video',
                            mediaType: MediaType.cameraVideo,
                          ),
                        ),
                        VerticalDivider(
                          indent: kDefaultPadding / 2,
                          endIndent: kDefaultPadding / 2,
                        ),
                        Expanded(
                          child: PickChoice(
                            pubkey: pubkey,
                            replyId: replyId,
                            onSuccess: onSuccess,
                            onFailed: onFailed,
                            icon: FeatureIcons.image,
                            title: 'Gallery',
                            mediaType: MediaType.gallery,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickChoice extends StatelessWidget {
  const PickChoice({
    Key? key,
    required this.pubkey,
    required this.mediaType,
    required this.title,
    required this.icon,
    required this.replyId,
    required this.onSuccess,
    required this.onFailed,
    this.onClicked,
  }) : super(key: key);

  final String pubkey;
  final MediaType mediaType;
  final String title;
  final String icon;
  final String? replyId;
  final Function() onSuccess;
  final Function() onFailed;
  final Function()? onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked ??
          () async {
            final media = await nostrRepository.selectLocalMedia(mediaType);

            if (media != null) {
              context.read<DmsCubit>().uploadMediaAndSend(
                    file: media,
                    pubkey: pubkey,
                    replyId: replyId,
                    onSuccess: onSuccess,
                    onFailed: onFailed,
                  );
            }
          },
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
            width: 30,
            height: 30,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          )
        ],
      ),
    );
  }
}
