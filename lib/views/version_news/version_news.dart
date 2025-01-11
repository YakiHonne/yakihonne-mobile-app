// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';

class VersionNews extends StatefulWidget {
  const VersionNews({
    Key? key,
    required this.onClosed,
  }) : super(key: key);
  final Function() onClosed;
  @override
  State<VersionNews> createState() => _VersionNewsState();
}

class _VersionNewsState extends State<VersionNews> {
  @override
  void dispose() {
    widget.onClosed.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        toolbarHeight: kToolbarHeight,
        title: Text(
          'Updates news',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(fontWeight: FontWeight.w700),
        ),
        leading: Center(
          child: CustomIconButton(
            onClicked: () {
              Navigator.pop(context);
            },
            icon: FeatureIcons.closeRaw,
            size: 20,
            iconColor: kWhite,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
      body: ScrollShadow(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            ...content
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: kDefaultPadding / 2,
                    ),
                    child: GestureDetector(
                      onTap: () => openWebPage(url: '${baseUrl}${e['url']}'),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: e['thumbnail'].toString(),
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      kDefaultPadding,
                                    ),
                                    border: Border.all(
                                      color: (e['new'] as bool)
                                          ? kOrangeContrasted
                                          : kTransparent,
                                      width: 1.5,
                                    ),
                                    image: DecorationImage(
                                      image: imageProvider,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 1,
                            left: 1,
                            child: Container(
                              padding: EdgeInsets.only(
                                right: kDefaultPadding / 1.5,
                                left: (e['new'] as bool)
                                    ? 65
                                    : kDefaultPadding / 1.5,
                                bottom: kDefaultPadding / 4,
                                top: kDefaultPadding / 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF555555),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(kDefaultPadding),
                                  bottomRight: Radius.circular(kDefaultPadding),
                                ),
                              ),
                              child: Text(
                                e['tag'].toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                          ),
                          if (e['new'] as bool)
                            Positioned(
                              top: 1,
                              left: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kDefaultPadding / 1.5,
                                  vertical: kDefaultPadding / 4,
                                ),
                                decoration: BoxDecoration(
                                    color: kOrangeContrasted,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(kDefaultPadding),
                                      bottomRight:
                                          Radius.circular(kDefaultPadding),
                                    )),
                                child: Text(
                                  'New',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                color: Theme.of(context).primaryColorLight,
              ),
              padding: const EdgeInsets.all(
                kDefaultPadding / 2,
              ),
              child: Column(
                children: [
                  Text(
                    'Updates',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    appVersion,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: kOrange,
                        ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  ...updatePoints.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: DotContainer(
                              color: kDimGrey,
                              isNotMarging: true,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 2,
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${e.key}: ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  TextSpan(
                                    text: e.value,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    '>> The end 🤩 <<',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: kOrange,
                        ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, String> updatePoints = {
  'Multi account': "The app allows you to add as much accounts as you want.",
  'Smart widget': "Smart widget optimization.",
  'Bugs fixes': "Broad app bugs fixes.",
};

const content = [
  {
    'url': 'yakihonne-smart-widgets',
    'thumbnail':
        "https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/update-smart-widget.png",
    "tag": "Smart widgets",
    "new": false,
  },
  {
    "url": "points-system",
    "thumbnail":
        "https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/update-points-system.png",
    "tag": "Points system",
    "new": false,
  },
  {
    "url": "yakihonne-flash-news",
    "thumbnail":
        "https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/update-flash-news.png",
    "tag": "Flash news",
    "new": false,
  },
];
