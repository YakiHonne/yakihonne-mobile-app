import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// import 'package:flutter_media_downloader/flutter_media_downloader.dart';

import 'easy_image_provider.dart';
import 'easy_image_view_pager.dart';

/// An internal widget that is used to hold a state to activate/deactivate the ability to
/// swipe-to-dismiss. This needs to be tied to the zoom scale of the current image, since
/// the user needs to be able to pan around on a zoomed-in image without triggering the
/// swipe-to-dismiss gesture.
class EasyImageViewerDismissibleDialog extends StatefulWidget {
  final EasyImageProvider imageProvider;
  final bool immersive;
  final void Function(int)? onPageChanged;
  final void Function(int)? onViewerDismissed;
  final Function(String) onDownload;
  final bool useSafeArea;
  final bool swipeDismissible;
  final Color backgroundColor;
  final String closeButtonTooltip;
  final Color closeButtonColor;

  /// Refer to [showImageViewerPager] for the arguments
  const EasyImageViewerDismissibleDialog(this.imageProvider,
      {Key? key,
      this.immersive = true,
      this.onPageChanged,
      this.onViewerDismissed,
      this.useSafeArea = false,
      this.swipeDismissible = false,
      required this.onDownload,
      required this.backgroundColor,
      required this.closeButtonTooltip,
      required this.closeButtonColor})
      : super(key: key);

  @override
  State<EasyImageViewerDismissibleDialog> createState() =>
      _EasyImageViewerDismissibleDialogState();
}

class _EasyImageViewerDismissibleDialogState
    extends State<EasyImageViewerDismissibleDialog> {
  /// This is used to either activate or deactivate the ability to swipe-to-dismissed, based on
  /// whether the current image is zoomed in (scale > 0) or not.
  DismissDirection _dismissDirection = DismissDirection.down;
  void Function()? _internalPageChangeListener;
  late final PageController _pageController;

  /// This is needed because of https://github.com/thesmythgroup/gallery_image_viewer/issues/27
  /// When no global key was used, the state was re-created on the initial zoom, which
  /// caused the new state to have _pagingEnabled set to true, which in turn broke
  /// paning on the zoomed-in image.
  final _popScopeKey = GlobalKey();
  final buttonStyle = IconButton.styleFrom(
    backgroundColor: Colors.black.withValues(alpha: 0.5),
  );

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: widget.imageProvider.initialIndex);
    if (widget.onPageChanged != null) {
      _internalPageChangeListener = () {
        widget.onPageChanged!(_pageController.page?.round() ?? 0);
      };
      _pageController.addListener(_internalPageChangeListener!);
    }
  }

  @override
  void dispose() {
    if (_internalPageChangeListener != null) {
      _pageController.removeListener(_internalPageChangeListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popScopeAwareDialog = PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          _handleDismissal();
        }
      },
      key: _popScopeKey,
      child: Dialog(
        backgroundColor: widget.backgroundColor,
        insetPadding: const EdgeInsets.all(0),
        // We set the shape here to ensure no rounded corners allow any of the
        // underlying view to show. We want the whole background to be covered.
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _handleDismissal();
              },
              child: EasyImageViewPager(
                  easyImageProvider: widget.imageProvider,
                  pageController: _pageController,
                  onScaleChanged: (scale) {
                    setState(() {
                      _dismissDirection = scale <= 1.0
                          ? DismissDirection.down
                          : DismissDirection.none;
                    });
                  }),
            ),
            Positioned(
              top: 0,
              right: 5,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      color: widget.closeButtonColor,
                      tooltip: widget.closeButtonTooltip,
                      style: buttonStyle,
                      onPressed: () async {
                        final image = widget.imageProvider.imageBuilder(
                            context, _pageController.page?.toInt() ?? 0);
                        widget.onDownload
                            .call((image as CachedNetworkImageProvider).url);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: widget.closeButtonColor,
                      tooltip: widget.closeButtonTooltip,
                      style: buttonStyle,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleDismissal();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (widget.imageProvider.imageCount > 1) ...[
              Positioned(
                left: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  style: buttonStyle,
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
              Positioned(
                right: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  style: buttonStyle,
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );

    if (widget.swipeDismissible) {
      return Dismissible(
          direction: _dismissDirection,
          resizeDuration: null,
          confirmDismiss: (dir) async {
            return true;
          },
          onDismissed: (_) {
            Navigator.of(context).pop();

            _handleDismissal();
          },
          key: const Key('dismissible_gallery_image_viewer_dialog'),
          child: popScopeAwareDialog);
    } else {
      return popScopeAwareDialog;
    }
  }

  // Internal function to be called whenever the dialog
  // is dismissed, whether through the Android back button,
  // through the "x" close button, or through swipe-to-dismiss.
  void _handleDismissal() {
    if (widget.onViewerDismissed != null) {
      widget.onViewerDismissed!(_pageController.page?.round() ?? 0);
    }

    if (widget.immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (_internalPageChangeListener != null) {
      _pageController.removeListener(_internalPageChangeListener!);
    }
  }
}
