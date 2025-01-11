import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';

class SelfVideoContainer extends StatelessWidget {
  const SelfVideoContainer({
    super.key,
    required this.video,
    required this.onEdit,
    required this.onClicked,
    required this.onDelete,
    required this.userStatus,
    required this.relays,
    required this.relaysColors,
  });

  final VideoModel video;
  final UserStatus userStatus;
  final List<String> relays;
  final Map<String, int> relaysColors;
  final Function() onEdit;
  final Function() onClicked;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).primaryColorLight,
        ),
        margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (video.thumbnail.isEmpty)
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: errorContainer(),
                  )
                else
                  CachedNetworkImage(
                    imageUrl:
                        video.thumbnail.isEmpty ? 'empty' : video.thumbnail,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            kDefaultPadding,
                          ),
                          topRight: Radius.circular(
                            kDefaultPadding,
                          ),
                        ),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => errorContainer(),
                  ),
                if (userStatus == UserStatus.UsingPrivKey)
                  Positioned(
                    right: kDefaultPadding / 2,
                    top: kDefaultPadding / 2,
                    left: kDefaultPadding / 2,
                    child: Row(
                      children: [
                        Spacer(),
                        CircleAvatar(
                          backgroundColor: kWhite.withValues(alpha: 0.9),
                          child: IconButton(
                            onPressed: onEdit,
                            icon: SvgPicture.asset(
                              FeatureIcons.article,
                              width: 25,
                              height: 25,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                        CircleAvatar(
                          backgroundColor: kWhite.withValues(alpha: 0.9),
                          child: IconButton(
                            onPressed: onDelete,
                            icon: SvgPicture.asset(
                              FeatureIcons.trash,
                              width: 25,
                              height: 25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DateRow(
                    createdAt: video.createdAt,
                    publishedAt: video.publishedAt,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  Text(
                    '${video.title.trim().capitalize()}',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Divider(
              height: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 1.5),
              child: Row(
                children: [
                  Text(
                    'Posted on',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      height: 15,
                      child: ListView.separated(
                        separatorBuilder: (context, index) {
                          return SizedBox(
                            width: kDefaultPadding / 4,
                          );
                        },
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final relay = relays[index];

                          return Tooltip(
                            message: relay,
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                            triggerMode: TooltipTriggerMode.tap,
                            child: Center(
                              child: DotContainer(
                                color: Color(
                                  relaysColors[relay] ??
                                      Theme.of(context).primaryColorLight.value,
                                ),
                                size: 15,
                                isNotMarging: true,
                              ),
                            ),
                          );
                        },
                        itemCount: relays.length,
                      ),
                    ),
                  ),
                  Tooltip(
                    message:
                        'This is a ${video.isHorizontal ? 'horizontal' : 'vertical'} video',
                    triggerMode: TooltipTriggerMode.tap,
                    textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).primaryColorLight,
                        ),
                    child: Icon(
                      video.isHorizontal
                          ? CupertinoIcons.device_phone_landscape
                          : CupertinoIcons.device_phone_portrait,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container errorContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: const Radius.circular(kDefaultPadding),
          topLeft: const Radius.circular(kDefaultPadding),
        ),
        image: DecorationImage(
          image: AssetImage(Images.invalidMedia),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
