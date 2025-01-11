import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';

class UpdatePopupScreen extends HookWidget {
  const UpdatePopupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final index = useState(0);
    final pageController = usePageController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              border: Border.all(
                color: kDimGrey.withValues(alpha: 0.3),
                width: 1,
              ),
              color: Theme.of(context).primaryColorLight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PageView.builder(
                      controller: pageController,
                      onPageChanged: (value) {
                        index.value = value;
                      },
                      physics: ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final image = images[index];
                        return CachedNetworkImage(
                          imageUrl: image,
                        );
                      },
                      itemCount: images.length,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(
                        kDefaultPadding,
                      ),
                      color: kOrange,
                      backgroundColor: kTransparent,
                      value: (index.value + 1) / images.length,
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          kDefaultPadding / 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RotatedBox(
                              quarterTurns: 1,
                              child: CustomIconButton(
                                onClicked: () {
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                icon: FeatureIcons.arrowDown,
                                size: 15,
                                vd: -2,
                                backgroundColor:
                                    kDimGrey2.withValues(alpha: 0.9),
                              ),
                            ),
                            RotatedBox(
                              quarterTurns: 3,
                              child: CustomIconButton(
                                onClicked: () {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                icon: FeatureIcons.arrowDown,
                                size: 15,
                                vd: -2,
                                backgroundColor:
                                    kDimGrey2.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            visualDensity: VisualDensity(
              vertical: -4,
            ),
          ),
          child: Text(
            'close',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: kDimGrey,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }
}

final images = [
  'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/feature-1.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/feature-2.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/feature-3.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/feature-4.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/feature-5.png',
];
