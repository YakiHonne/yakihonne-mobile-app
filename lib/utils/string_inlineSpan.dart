import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:convert/convert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/gallery_view/gallery_image_viewer.dart';
import 'package:yakihonne/views/gallery_view/gallery_view.dart';
import 'package:yakihonne/views/gallery_view/multi_image_provider.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';
import 'package:yakihonne/views/widgets/note_container.dart';

export 'package:linkify/linkify.dart'
    show
        LinkifyElement,
        LinkifyOptions,
        LinkableElement,
        TextElement,
        Linkifier,
        UrlElement,
        UrlLinkifier,
        EmailElement,
        EmailLinkifier;

/// Callback clicked link
typedef LinkCallback = void Function(LinkableElement link);

/// Turns URLs into links
class Linkify extends StatelessWidget {
  /// Text to be linkified
  final String text;

  /// Linkifiers to be used for linkify
  final List<Linkifier> linkifiers;

  /// Callback for tapping a link
  final LinkCallback? onOpen;

  final Function()? onClicked;

  /// linkify's options.
  final LinkifyOptions options;

  // TextSpan

  /// Style for non-link text
  final TextStyle? style;

  /// Style of link text
  final TextStyle? linkStyle;

  // Text.rich

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Text direction of the text
  final TextDirection? textDirection;

  /// The maximum number of lines for the text to span, wrapping if necessary
  final int? maxLines;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// The number of font pixels for each logical pixel
  final double textScaleFactor;

  /// Whether the text should break at soft line breaks.
  final bool softWrap;

  /// The strut style used for the vertical layout
  final StrutStyle? strutStyle;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale
  final Locale? locale;

  /// Defines how to measure the width of the rendered text.
  final TextWidthBasis textWidthBasis;

  /// Defines how the paragraph will apply TextStyle.height to the ascent of the first line and descent of the last line.
  final TextHeightBehavior? textHeightBehavior;

  final bool? isScreenshot;

  final bool? disableNoteParsing;

  final bool? inverseNoteColor;

  final bool useMouseRegion;

  const Linkify({
    Key? key,
    required this.text,
    this.linkifiers = defaultLinkifiers,
    this.onOpen,
    this.options = const LinkifyOptions(),
    // TextSpan
    this.style,
    this.linkStyle,
    // RichText
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.softWrap = true,
    this.strutStyle,
    this.locale,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.useMouseRegion = true,
    this.isScreenshot,
    this.disableNoteParsing,
    this.inverseNoteColor,
    this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String cleanedContent = text.trim().replaceAll(RegExp(r'\n+'), '\n');
    final elements = linkify(
      cleanedContent,
      options: options,
      linkifiers: linkifiers,
    ).where((element) => element.text.isNotEmpty).toList();

    return FutureBuilder(
      future: getUrlTypes(elements: elements),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: onClicked,
          child: Text.rich(
            buildTextSpan(
              elements,
              snapshot.hasData ? snapshot.data! : {},
              context,
              isScreenshot: isScreenshot,
              style: style ?? Theme.of(context).textTheme.bodyMedium,
              onOpen: onOpen,
              disableNoteParsing: disableNoteParsing,
              inverseNoteColor: inverseNoteColor,
              useMouseRegion: useMouseRegion,
              linkStyle: linkStyle,
            ),
            textAlign: textAlign,
            textDirection: textDirection,
            maxLines: maxLines,
            overflow: overflow,
            softWrap: softWrap,
            strutStyle: strutStyle,
            locale: locale,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
          ),
        );
      },
    );
  }
}

/// Turns URLs into links
class SelectableLinkify extends StatelessWidget {
  /// Text to be linkified
  final String text;

  /// The number of font pixels for each logical pixel
  final double textScaleFactor;

  /// Linkifiers to be used for linkify
  final List<Linkifier> linkifiers;

  /// Callback for tapping a link
  final LinkCallback? onOpen;

  /// linkify's options.
  final LinkifyOptions options;

  // TextSpan

  /// Style for non-link text
  final TextStyle? style;

  /// Style of link text
  final TextStyle? linkStyle;

  // Text.rich

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// Text direction of the text
  final TextDirection? textDirection;

  /// The minimum number of lines to occupy when the content spans fewer lines.
  final int? minLines;

  /// The maximum number of lines for the text to span, wrapping if necessary
  final int? maxLines;

  /// The strut style used for the vertical layout
  final StrutStyle? strutStyle;

  /// Defines how to measure the width of the rendered text.
  final TextWidthBasis? textWidthBasis;

  // SelectableText.rich

  /// Defines the focus for this widget.
  final FocusNode? focusNode;

  /// Whether to show cursor
  final bool showCursor;

  /// Whether this text field should focus itself if nothing else is already focused.
  final bool autofocus;

  /// Builds the text selection toolbar when requested by the user
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// How thick the cursor will be
  final double cursorWidth;

  /// How rounded the corners of the cursor should be
  final Radius? cursorRadius;

  /// The color to use when painting the cursor
  final Color? cursorColor;

  /// Determines the way that drag start behavior is handled
  final DragStartBehavior dragStartBehavior;

  /// If true, then long-pressing this TextField will select text and show the cut/copy/paste menu,
  /// and tapping will move the text caret
  final bool enableInteractiveSelection;

  /// Called when the user taps on this selectable text (not link)
  final GestureTapCallback? onTap;

  final ScrollPhysics? scrollPhysics;

  /// Defines how the paragraph will apply TextStyle.height to the ascent of the first line and descent of the last line.
  final TextHeightBehavior? textHeightBehavior;

  /// How tall the cursor will be.
  final double? cursorHeight;

  /// Optional delegate for building the text selection handles and toolbar.
  final TextSelectionControls? selectionControls;

  /// Called when the user changes the selection of text (including the cursor location).
  final SelectionChangedCallback? onSelectionChanged;

  final bool useMouseRegion;

  const SelectableLinkify({
    Key? key,
    required this.text,
    this.linkifiers = defaultLinkifiers,
    this.onOpen,
    this.options = const LinkifyOptions(),
    // TextSpan
    this.style,
    this.linkStyle,
    // RichText
    this.textAlign,
    this.textDirection,
    this.minLines,
    this.maxLines,
    // SelectableText
    this.focusNode,
    this.textScaleFactor = 1.0,
    this.strutStyle,
    this.showCursor = false,
    this.autofocus = false,
    this.contextMenuBuilder,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.scrollPhysics,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.cursorHeight,
    this.selectionControls,
    this.onSelectionChanged,
    this.useMouseRegion = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final elements = linkify(
      text.trim(),
      options: options,
      linkifiers: linkifiers,
    ).where((element) => element.text.isNotEmpty).toList();

    return FutureBuilder(
        future: getUrlTypes(elements: elements),
        builder: (context, snapshot) {
          return SelectableText.rich(
            buildTextSpan(
              elements,
              snapshot.hasData ? {} : snapshot.data!,
              style: style ?? Theme.of(context).textTheme.bodyMedium,
              context,
              onOpen: onOpen,
              linkStyle: (style ?? Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  )
                  .merge(linkStyle),
              useMouseRegion: useMouseRegion,
            ),
            textAlign: textAlign,
            textDirection: textDirection,
            minLines: minLines,
            maxLines: maxLines,
            focusNode: focusNode,
            strutStyle: strutStyle,
            showCursor: showCursor,
            textScaler: TextScaler.linear(textScaleFactor),
            autofocus: autofocus,
            contextMenuBuilder: contextMenuBuilder,
            cursorWidth: cursorWidth,
            cursorRadius: cursorRadius,
            cursorColor: cursorColor,
            dragStartBehavior: dragStartBehavior,
            enableInteractiveSelection: enableInteractiveSelection,
            onTap: onTap,
            scrollPhysics: scrollPhysics,
            textWidthBasis: textWidthBasis,
            textHeightBehavior: textHeightBehavior,
            cursorHeight: cursorHeight,
            selectionControls: selectionControls,
            onSelectionChanged: onSelectionChanged,
          );
        });
  }
}

class LinkableSpan extends WidgetSpan {
  LinkableSpan({
    required MouseCursor mouseCursor,
    required InlineSpan inlineSpan,
  }) : super(
          child: MouseRegion(
            cursor: mouseCursor,
            child: Text.rich(
              inlineSpan,
            ),
          ),
        );
}

/// Raw TextSpan builder for more control on the RichText
TextSpan buildTextSpan(
  List<LinkifyElement> elements,
  Map<int, UrlType> types,
  BuildContext context, {
  TextStyle? style,
  TextStyle? linkStyle,
  LinkCallback? onOpen,
  bool? isScreenshot,
  bool? disableNoteParsing,
  bool? inverseNoteColor,
  bool useMouseRegion = false,
}) =>
    TextSpan(
      children: buildTextSpanChildren(
        elements,
        types,
        context,
        style: style,
        linkStyle: linkStyle,
        onOpen: onOpen,
        isScreenshot: isScreenshot,
        disableNoteParsing: disableNoteParsing,
        inverseNoteColor: inverseNoteColor,
        useMouseRegion: useMouseRegion,
      ),
    );

List<InlineSpan>? buildTextSpanChildren(
  List<LinkifyElement> elements,
  Map<int, UrlType> types,
  BuildContext context, {
  TextStyle? style,
  TextStyle? linkStyle,
  LinkCallback? onOpen,
  bool? isScreenshot,
  bool? disableNoteParsing,
  bool? inverseNoteColor,
  bool useMouseRegion = false,
}) {
  if (elements.isEmpty) {
    return [
      TextSpan(
        text: 'No content',
        style: style!.copyWith(
          color: kDimGrey,
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  } else if (types.isNotEmpty) {
    final filteredElements = List<LinkifyElement>.from(elements);
    Map<int, UrlType> newTypes = Map<int, UrlType>.from(types);

    for (int i = 0; i < filteredElements.length; i++) {
      final element = filteredElements[i];

      if (element is! LinkableElement) {
        final replace = removeAndReplaceElement(
          element: element,
          types: newTypes,
          currentIndex: i,
        );

        if (replace) {
          filteredElements.removeAt(i);

          for (final item in newTypes.entries.toList()) {
            if (item.key > i) {
              newTypes[item.key - 1] = item.value;
              newTypes.remove(item.key);
            }
          }
        }
      }
    }

    final images = newTypes.entries
        .where((element) => element.value == UrlType.image)
        .toList();

    var result = {for (var v in images) v.key: v.value};

    final consecutiveImages = groupConsecutive(result);

    final spans = <InlineSpan>[];

    for (int i = 0; i < filteredElements.length; i++) {
      final element = filteredElements[i];

      if (element is LinkableElement) {
        final canBeFound = consecutiveImages
            .where((element) => element.keys.contains(i))
            .toList()
            .isNotEmpty;

        if (canBeFound) {
          final list = consecutiveImages
              .where((element) => element.keys.first == i)
              .toList();

          if (list.isNotEmpty) {
            final selectedElements = <LinkableElement>[];

            for (var item in list.first.keys) {
              final fi = filteredElements.elementAt(item);

              if (fi is LinkableElement) {
                selectedElements.add(fi);
              }
            }

            final List<CachedNetworkImageProvider> _imageProviders = [];

            for (int i = 0; i < selectedElements.length; i++) {
              final chosenElement = selectedElements[i];

              final link = chosenElement is artCurSchemeElement ||
                      chosenElement is UserSchemeElement
                  ? chosenElement.text
                  : chosenElement.url;

              _imageProviders.add(
                CachedNetworkImageProvider(link),
              );
            }

            spans.add(
              WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 2,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    child: _imageProviders.length > 1
                        ? GalleryImageView(
                            listImage: _imageProviders,
                            seperatorColor: Theme.of(context).primaryColorLight,
                            width: MediaQuery.of(context).size.width,
                            boxFit: BoxFit.cover,
                            onDownload: shareImage,
                            height: 180,
                          )
                        : GestureDetector(
                            onTap: () {
                              MultiImageProvider multiImageProvider =
                                  MultiImageProvider(
                                _imageProviders,
                                initialIndex: 0,
                              );
                              showImageViewerPager(
                                context,
                                multiImageProvider,
                                onDownload: shareImage,
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.3),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: _imageProviders.first.url,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }
        } else {
          if (element is NoteElement) {
            final note = DetailedNoteModel.fromJson(element.url);

            spans.add(
              WidgetSpan(
                child: disableNoteParsing != null
                    ? LinkPreviewer(
                        url: Nip19.encodeNote(note.id),
                        urlType: newTypes[filteredElements.indexOf(element)] ??
                            UrlType.text,
                        textStyle: linkStyle,
                        isScreenshot: isScreenshot,
                        onOpen: onOpen != null ? () => onOpen(element) : null,
                        inverseNoteColor: inverseNoteColor,
                      )
                    : NoteContainer(
                        note: note,
                        inverseNoteColor: inverseNoteColor,
                        vMargin: kDefaultPadding / 4,
                      ),
              ),
            );
          } else if (element is TagElement) {
            spans.add(
              TextSpan(
                text: element.text,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => onOpen?.call(element),
                style: style!.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          } else if (element is SmartWidgetElement) {
            final sw = SmartWidgetModel.fromJson(element.url);
            final swc = sw.container;

            spans.add(
              WidgetSpan(
                child: swc != null && disableNoteParsing == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4,
                        ),
                        child: SmartWidget(
                          smartWidgetContainer: swc,
                          backgroundColor: inverseNoteColor != null
                              ? Theme.of(context).scaffoldBackgroundColor
                              : null,
                        ),
                      )
                    : LinkPreviewer(
                        url: sw.title,
                        urlType: UrlType.text,
                        textStyle: linkStyle,
                        isScreenshot: isScreenshot,
                        onOpen: onOpen != null ? () => onOpen(element) : null,
                        inverseNoteColor: inverseNoteColor,
                      ),
              ),
            );
          } else {
            spans.add(
              WidgetSpan(
                child: Builder(
                  builder: (context) {
                    final url = element is artCurSchemeElement ||
                            element is UserSchemeElement
                        ? element.text
                        : element.url;

                    if (url.contains('yakihonne.com/')) {
                      Map<String, dynamic> decode = {};
                      final last = url.split('/').last;

                      if (last.startsWith('naddr')) {
                        decode = Nip19.decodeShareableEntity(last);
                      } else if (last.startsWith('smart-widget-checker')) {
                        final naddr =
                            last.split('?').last.replaceAll('naddr=', '');
                        decode = Nip19.decodeShareableEntity(naddr);
                      }

                      if (decode['kind'] == EventKind.SMART_WIDGET) {
                        final hexCode = hex.decode(decode['special']);
                        final eventIdentifier = String.fromCharCodes(hexCode);

                        final event =
                            singleEventCubit.getEvent(eventIdentifier, true);
                        SmartWidgetModel? sw;
                        if (event != null &&
                            (sw = SmartWidgetModel.fromEvent(event))
                                    .container !=
                                null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 4,
                            ),
                            child: SmartWidget(
                              smartWidgetContainer: sw.container!,
                              backgroundColor: inverseNoteColor != null
                                  ? Theme.of(context).scaffoldBackgroundColor
                                  : null,
                            ),
                          );
                        } else {
                          return LinkPreviewer(
                            url: url,
                            urlType:
                                newTypes[filteredElements.indexOf(element)] ??
                                    UrlType.text,
                            textStyle: linkStyle,
                            isScreenshot: isScreenshot,
                            onOpen:
                                onOpen != null ? () => onOpen(element) : null,
                            inverseNoteColor: inverseNoteColor,
                          );
                        }
                      } else {
                        return LinkPreviewer(
                          url: url,
                          urlType:
                              newTypes[filteredElements.indexOf(element)] ??
                                  UrlType.text,
                          textStyle: linkStyle,
                          isScreenshot: isScreenshot,
                          onOpen: onOpen != null ? () => onOpen(element) : null,
                          inverseNoteColor: inverseNoteColor,
                        );
                      }
                    } else {
                      return LinkPreviewer(
                        url: url,
                        urlType: newTypes[filteredElements.indexOf(element)] ??
                            UrlType.text,
                        textStyle: linkStyle,
                        isScreenshot: isScreenshot,
                        onOpen: onOpen != null ? () => onOpen(element) : null,
                        inverseNoteColor: inverseNoteColor,
                      );
                    }
                  },
                ),
              ),
            );
          }
        }
      } else {
        spans.add(
          TextSpan(
            text: element.text,
            style: style,
          ),
        );
      }
    }

    return spans;
  } else {
    return [
      for (var element in elements)
        if (element is LinkableElement)
          if (element is NoteElement)
            WidgetSpan(
              child: NoteContainer(
                note: DetailedNoteModel.fromJson(element.url),
                vMargin: kDefaultPadding / 4,
              ),
            )
          else if (element is SmartWidgetElement)
            WidgetSpan(
              child: SmartWidgetModel.fromJson(element.url).container != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      child: SmartWidget(
                        smartWidgetContainer:
                            SmartWidgetModel.fromJson(element.url).container!,
                        backgroundColor: inverseNoteColor != null
                            ? Theme.of(context).scaffoldBackgroundColor
                            : null,
                      ),
                    )
                  : LinkPreviewer(
                      url: element.text,
                      urlType: UrlType.text,
                      textStyle: linkStyle,
                      isScreenshot: isScreenshot,
                      onOpen: onOpen != null ? () => onOpen(element) : null,
                    ),
            )
          else if (element is TagElement)
            TextSpan(
              text: element.text,
              recognizer: TapGestureRecognizer()
                ..onTap = () => onOpen?.call(element),
              style: style!.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            WidgetSpan(
              child: LinkPreviewer(
                url: element is artCurSchemeElement ||
                        element is UserSchemeElement
                    ? element.text
                    : element.url,
                urlType: UrlType.text,
                textStyle: linkStyle,
                isScreenshot: isScreenshot,
                onOpen: onOpen != null ? () => onOpen(element) : null,
                inverseNoteColor: inverseNoteColor,
              ),
            )
        else
          TextSpan(
            text: element.text,
            style: style,
          ),
    ];
  }
}

bool removeAndReplaceElement({
  required LinkifyElement element,
  required Map<int, UrlType> types,
  required int currentIndex,
}) {
  final trimmed = element.text.trim();

  if ((trimmed.isEmpty || trimmed == "\n" || trimmed == "\n\n")) {
    return types[currentIndex - 1] == UrlType.image &&
        types[currentIndex + 1] == UrlType.image;
  } else {
    return false;
  }
}

List<Map<int, UrlType>> groupConsecutive(Map<int, UrlType> data) {
  List<Map<int, UrlType>> result = [];

  List<MapEntry<int, UrlType>> sortedEntries = data.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  List<MapEntry<int, UrlType>> currentGroup = [];
  int? previousId;

  for (var entry in sortedEntries) {
    if (previousId == null || entry.key - previousId == 1) {
      currentGroup.add(entry);
    } else {
      result.add({for (var v in currentGroup) v.key: v.value});
      currentGroup = [entry];
    }
    previousId = entry.key;
  }

  if (currentGroup.isNotEmpty) {
    result.add({for (var v in currentGroup) v.key: v.value});
  }

  return result;
}

Future<Map<int, UrlType>> getUrlTypes({
  required List<LinkifyElement> elements,
}) async {
  final urls = <int, String>{};
  for (int i = 0; i < elements.length; i++) {
    final element = elements[i];

    if (element is LinkableElement) {
      urls[i] = element is artCurSchemeElement || element is UserSchemeElement
          ? element.text
          : element.url;
    }
  }

  final res = await Future.wait(
    urls.entries.map((e) => getUrlType(url: e.value)).toList(),
  );

  final types = <int, UrlType>{};
  int i = 0;
  for (final key in urls.keys) {
    types[key] = res[i];
    i++;
  }

  return types;
}

Future<UrlType> getUrlType({
  required String url,
}) async {
  if (isImageExtension(url.split('.').last)) {
    return UrlType.image;
  } else if (isVideoExtension(url.split('.').last) ||
      (videoUrlValidator.validateYouTubeVideoURL(url: url) &&
          !url.contains('channel')) ||
      videoUrlValidator.validateVimeoVideoURL(url: url)) {
    return UrlType.video;
  } else if (isAudioExtension(url.split('.').last)) {
    return UrlType.audio;
  } else {
    final urlTypeResult = await HttpFunctionsRepository.getUrlType(url);
    return urlTypeResult;
  }
}

void shareImage(String link) async {
  final _cancel = BotToast.showLoading();

  try {
    final response = await Dio().get(
      link,
      options: Options(responseType: ResponseType.bytes),
    );

    String? mimeType;
    final last = link.split('.').last;

    if (isImageExtension(last)) {
      mimeType = last == 'jpg' ? 'image/jpeg' : 'image/${last}';
    } else {
      mimeType = response.headers['content-type']?.first;
    }

    final image = XFile.fromData(
      response.data,
      mimeType: mimeType,
      name: "YakiHonne's image",
    );

    _cancel.call();

    await Share.shareXFiles(
      [image],
      subject: "Share YakiHonne's content with the others",
    );
  } catch (_) {
    lg.i(_);
    _cancel.call();
  }
}

final _TagRegex = RegExp(
  r'\B#\w\w+',
  caseSensitive: false,
  dotAll: true,
);

class TagLinkifier extends Linkifier {
  /// Default constructor.
  const TagLinkifier();

  /// Parses text to find all links inside it.
  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement && element.text.isNotEmpty) {
        element.text.splitMapJoin(
          _TagRegex,
          onMatch: (match) {
            list.add(TagElement(match.group(0)!));
            return '';
          },
          onNonMatch: (match) {
            list.add(
              TextElement(match),
            );
            return '';
          },
        );
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

final _NostrSchemeRegex = RegExp(
  r'@?(nostr:)?@?(npub1|nevent1|naddr1|note1|nprofile1|nrelay1|\#)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
  caseSensitive: false,
  dotAll: true,
);

class NostrSchemeLinkifier extends Linkifier {
  /// Default constructor.
  const NostrSchemeLinkifier();

  /// Parses text to find all links inside it.
  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement && element.text.isNotEmpty) {
        element.text.splitMapJoin(
          _NostrSchemeRegex,
          onMatch: (match) {
            if (match.group(2)?.isNotEmpty == true &&
                match.group(3)?.isNotEmpty == true) {
              if (match.group(2) == 'npub1' &&
                  (match.group(2)!.length + match.group(3)!.length) == 63) {
                final pubKey =
                    Nip19.decodePubkey('${match.group(2)! + match.group(3)!}');
                final user = authorsCubit.state.authors[pubKey];

                if (user == null) {
                  authorsCubit.getAuthors([pubKey]);
                }

                list.add(
                  UserSchemeElement(
                    pubKey,
                    user != null
                        ? '@${getAuthorName(user)}'
                        : '@${match.group(2)! + match.group(3)!}',
                  ),
                );
              } else if (match.group(2) == 'nprofile1') {
                final entity = Nip19.decodeShareableEntity(
                  match.group(2)! + match.group(3)!,
                );

                final user = authorsCubit.state.authors[entity['special']];

                if (user == null) {
                  authorsCubit.getAuthors([entity['special']]);
                }

                list.add(
                  UserSchemeElement(
                    entity['special'],
                    user != null
                        ? '@${getAuthorName(user)}'
                        : '@${match.group(2)! + match.group(3)!}',
                  ),
                );
              } else if (match.group(2) == 'note1') {
                final entity = Nip19.decodeNote(
                  match.group(2)! + match.group(3)!,
                );

                final event = singleEventCubit.getEvent(entity, false);
                DetailedNoteModel? note;

                if (event != null) {
                  note = DetailedNoteModel.fromEvent(event);
                }

                list.add(
                  note != null
                      ? NoteElement(
                          note.toJson(),
                          Nip19.encodeNote(note.id),
                        )
                      : artCurSchemeElement(
                          '',
                          'note',
                          Nip19.encodeNote(entity),
                        ),
                );
              } else if (match.group(2) == 'naddr1') {
                final entity = Nip19.decodeShareableEntity(
                  match.group(2)! + match.group(3)!,
                );

                final eventKind = entity['kind'];

                if (eventKind == EventKind.LONG_FORM ||
                    eventKind == EventKind.VIDEO_HORIZONTAL ||
                    eventKind == EventKind.VIDEO_VERTICAL ||
                    eventKind == EventKind.SMART_WIDGET ||
                    eventKind == EventKind.CURATION_ARTICLES) {
                  final hexCode = hex.decode(entity['special']);
                  final eventIdentifier = String.fromCharCodes(hexCode);

                  final event =
                      singleEventCubit.getEvent(eventIdentifier, true);

                  if (eventKind == EventKind.LONG_FORM) {
                    Article? article;

                    if (event != null) {
                      article = Article.fromEvent(event);
                    }

                    list.add(
                      artCurSchemeElement(
                        event != null ? article!.toJson() : '',
                        'article',
                        event != null
                            ? '${article!.title}'
                            : '${match.group(2)! + match.group(3)!}',
                      ),
                    );
                  } else if (eventKind == EventKind.VIDEO_HORIZONTAL ||
                      eventKind == EventKind.VIDEO_VERTICAL) {
                    VideoModel? video;
                    if (event != null) {
                      video = VideoModel.fromEvent(event);
                    }

                    list.add(
                      artCurSchemeElement(
                        event != null ? video!.toJson() : '',
                        'video',
                        event != null
                            ? '${video!.title}'
                            : '${match.group(2)! + match.group(3)!}',
                      ),
                    );
                  } else if (eventKind == EventKind.SMART_WIDGET) {
                    SmartWidgetModel? sm;

                    if (event != null) {
                      sm = SmartWidgetModel.fromEvent(event);
                    }

                    list.add(
                      sm != null
                          ? SmartWidgetElement(
                              sm.toJson(),
                              '${match.group(2)! + match.group(3)!}',
                            )
                          : artCurSchemeElement(
                              '',
                              'note',
                              '${match.group(2)! + match.group(3)!}',
                            ),
                    );
                  } else {
                    Curation? articleCuration;

                    if (event != null) {
                      articleCuration = Curation.fromEvent(event, '');
                    }

                    list.add(
                      artCurSchemeElement(
                        event != null ? articleCuration!.toJson() : '',
                        'curation',
                        event != null
                            ? '${articleCuration!.title}'
                            : '${match.group(2)! + match.group(3)!}',
                      ),
                    );
                  }
                } else {
                  list.add(
                    TextElement(
                      match.group(2)! + match.group(3)!,
                    ),
                  );
                }
              } else if (match.group(2) == 'nevent1') {
                final entity = Nip19.decodeShareableEntity(
                  match.group(2)! + match.group(3)!,
                );

                final event =
                    singleEventCubit.getEvent(entity['special'], false);

                if (event != null) {
                  if (event.kind == EventKind.TEXT_NOTE) {
                    final note = DetailedNoteModel.fromEvent(event);

                    list.add(
                      NoteElement(
                        note.toJson(),
                        Nip19.encodeNote(note.id),
                      ),
                    );
                  } else if (event.kind == EventKind.LONG_FORM) {
                    final article = Article.fromEvent(event);

                    list.add(
                      artCurSchemeElement(
                        article.toJson(),
                        'article',
                        '${article.title}',
                      ),
                    );
                  } else if (event.kind == EventKind.CURATION_ARTICLES) {
                    final articleCuration = Curation.fromEvent(event, '');

                    list.add(
                      artCurSchemeElement(
                        articleCuration.toJson(),
                        'curation',
                        '${articleCuration.title}',
                      ),
                    );
                  } else {
                    list.add(
                      TextElement(
                        match.group(2)! + match.group(3)!,
                      ),
                    );
                  }
                } else {
                  list.add(
                    artCurSchemeElement(
                      '',
                      'event',
                      '${match.group(2)! + match.group(3)!}',
                    ),
                  );
                }
              } else {
                list.add(
                  TextElement(match.group(0) ?? ''),
                );
              }
            }

            return '';
          },
          onNonMatch: (match) {
            list.add(
              TextElement(match),
            );
            return '';
          },
        );
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

@immutable
class UserSchemeElement extends LinkableElement {
  /// Creates [UserSchemeElement].
  UserSchemeElement(String url, [String? text]) : super(text, url);

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => equals(other);

  @override
  // ignore: type_annotate_public_apis
  bool equals(other) => other is UrlElement && super.equals(other);

  @override
  String toString() => "user: '$url'";
}

@immutable
class artCurSchemeElement extends LinkableElement {
  artCurSchemeElement(String url, this.kind, [String? text]) : super(text, url);

  final String kind;

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => equals(other);

  @override
  // ignore: type_annotate_public_apis
  bool equals(other) => other is UrlElement && super.equals(other);

  @override
  String toString() => "$kind: '$url' ($text)";
}

@immutable
class NoteElement extends LinkableElement {
  NoteElement(String url, [String? text]) : super(text, url);

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => equals(other);

  @override
  // ignore: type_annotate_public_apis
  bool equals(other) => other is UrlElement && super.equals(other);

  @override
  String toString() => "note: '$url' ($text)";
}

@immutable
class SmartWidgetElement extends LinkableElement {
  SmartWidgetElement(String url, [String? text]) : super(text, url);

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => equals(other);

  @override
  // ignore: type_annotate_public_apis
  bool equals(other) => other is UrlElement && super.equals(other);

  @override
  String toString() => "smartWidget: '$url' ($text)";
}

@immutable
class TagElement extends LinkableElement {
  TagElement(String tag, [String? text]) : super(text, tag);

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => equals(other);

  @override
  // ignore: type_annotate_public_apis
  bool equals(other) => other is UrlElement && super.equals(other);

  @override
  String toString() => "tag: '$url'";
}
