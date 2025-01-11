/// A library to easily display images in a full-screen dialog.
/// It supports pinch & zoom, and paging through multiple images.
library gallery_image_viewer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakihonne/views/gallery_view/easy_image_provider.dart';
import 'package:yakihonne/views/gallery_view/easy_image_viewer_dismissible_dialog.dart';

// Defined here so we don't repeat ourselves
const _defaultBackgroundColor = Colors.black;
const _defaultCloseButtonColor = Colors.white;
const _defaultCloseButtonTooltip = 'Close';

/// Shows the images provided by the [imageProvider] in a full-screen PageView [Dialog].
/// Setting [immersive] to false will prevent the top and bottom bars from being hidden.
/// The optional [onPageChanged] callback function is called with the index of
/// the image when the user has swiped to another image.
/// The optional [onViewerDismissed] callback function is called with the index of
/// the image that is displayed when the dialog is closed.
/// The optional [useSafeArea] boolean defaults to false and is passed to [showDialog].
/// The optional [swipeDismissible] boolean defaults to false allows swipe-down-to-dismiss.
/// The [backgroundColor] defaults to black, but can be set to any other color.
/// The [closeButtonTooltip] text is displayed when the user long-presses on the
/// close button and is used for accessibility.
/// The [closeButtonColor] defaults to white, but can be set to any other color.
Future<Dialog?> showImageViewerPager(
    BuildContext context, EasyImageProvider imageProvider,
    {bool immersive = true,
    void Function(int)? onPageChanged,
    void Function(int)? onViewerDismissed,
    required void Function(String) onDownload,
    bool useSafeArea = false,
    bool swipeDismissible = false,
    Color backgroundColor = _defaultBackgroundColor,
    String closeButtonTooltip = _defaultCloseButtonTooltip,
    Color closeButtonColor = _defaultCloseButtonColor}) {
  if (immersive) {
    // Hide top and bottom bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  return showDialog<Dialog>(
      context: context,
      useSafeArea: useSafeArea,
      builder: (context) {
        return EasyImageViewerDismissibleDialog(imageProvider,
            immersive: immersive,
            onPageChanged: onPageChanged,
            onViewerDismissed: onViewerDismissed,
            useSafeArea: useSafeArea,
            swipeDismissible: swipeDismissible,
            backgroundColor: backgroundColor,
            closeButtonColor: closeButtonColor,
            onDownload: onDownload,
            closeButtonTooltip: closeButtonTooltip);
      });
}
