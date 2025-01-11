import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/views/gallery_view/easy_image_view.dart';

import 'easy_image_provider.dart';

/// Custom ScrollBehavior that allows dragging with all pointers
/// including the normally excluded mouse
class MouseEnabledScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

/// PageView for swiping through a list of images
class EasyImageViewPager extends StatefulWidget {
  final EasyImageProvider easyImageProvider;
  final PageController pageController;

  /// Callback for when the scale has changed, only invoked at the end of
  /// an interaction.
  final void Function(double)? onScaleChanged;

  /// Create new instance, using the [easyImageProvider] to populate the [PageView],
  /// and the [pageController] to control the initial image index to display.
  const EasyImageViewPager(
      {Key? key,
      required this.easyImageProvider,
      required this.pageController,
      this.onScaleChanged})
      : super(key: key);

  @override
  _EasyImageViewPagerState createState() => _EasyImageViewPagerState();
}

class _EasyImageViewPagerState extends State<EasyImageViewPager> {
  bool _pagingEnabled = true;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      physics: _pagingEnabled
          ? const PageScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      key: GlobalObjectKey(widget.easyImageProvider),
      itemCount: widget.easyImageProvider.imageCount,
      controller: widget.pageController,
      scrollBehavior: MouseEnabledScrollBehavior(),
      itemBuilder: (context, index) {
        final image = widget.easyImageProvider.imageBuilder(context, index);
        return EasyImageView(
          key: Key('easy_image_view_$index'),
          imageProvider: image,
          onScaleChanged: (scale) {
            if (widget.onScaleChanged != null) {
              widget.onScaleChanged!(scale);
            }

            setState(() {
              _pagingEnabled = scale <= 1.0;
            });
          },
        );
      },
    );
  }
}
