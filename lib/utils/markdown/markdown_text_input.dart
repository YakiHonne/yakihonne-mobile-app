// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakihonne/utils/markdown/format_markdown.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/smart_widget_selection.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_image_selector.dart';
import 'package:yakihonne/views/write_article_view/widgets/gpt_chat.dart';

/// Widget with markdown buttons
class MarkdownTextInput extends StatefulWidget {
  /// Callback called when text changed
  final Function onTextChanged;

  /// Initial value you want to display
  final String initialValue;

  /// Validator for the TextFormField
  final String? Function(String? value)? validators;

  /// Title changed
  final Function(String) onTitleChanged;

  /// Title controller
  final TextEditingController titleController;

  /// String displayed at hintText in TextFormField
  final String? label;

  /// Change the text direction of the input (RTL / LTR)
  final TextDirection textDirection;

  /// The maximum of lines that can be display in the input
  final int? maxLines;

  /// List of action the component can handle
  final List<MarkdownType> actions;

  /// Optional controller to manage the input
  final TextEditingController? controller;

  /// Overrides input text style
  final TextStyle? textStyle;

  /// If you prefer to use the dialog to insert links, you can choose to use the markdown syntax directly by setting [insertLinksByDialog] to false. In this case, the selected text will be used as label and link.
  /// Default value is true.
  final bool insertLinksByDialog;

  /// Constructor for [MarkdownTextInput]
  MarkdownTextInput(
    this.onTextChanged,
    this.onTitleChanged,
    this.titleController,
    this.initialValue, {
    this.label = '',
    this.validators,
    this.textDirection = TextDirection.ltr,
    this.maxLines = 10,
    this.actions = const [
      MarkdownType.bold,
      MarkdownType.italic,
      MarkdownType.title,
      MarkdownType.link,
      MarkdownType.list
    ],
    this.textStyle,
    this.controller,
    this.insertLinksByDialog = true,
  });

  @override
  _MarkdownTextInputState createState() =>
      _MarkdownTextInputState(controller ?? TextEditingController());
}

class _MarkdownTextInputState extends State<MarkdownTextInput> {
  final TextEditingController _controller;
  TextSelection textSelection =
      const TextSelection(baseOffset: 0, extentOffset: 0);
  FocusNode focusNode = FocusNode();
  final _scrollController = ScrollController();

  _MarkdownTextInputState(this._controller);

  void onTap(
    MarkdownType type, {
    int titleSize = 1,
    String? link,
    String? selectedText,
  }) {
    final basePosition = textSelection.baseOffset;
    var noTextSelected =
        (textSelection.baseOffset - textSelection.extentOffset) == 0;

    var fromIndex = textSelection.baseOffset;
    var toIndex = textSelection.extentOffset;

    final result = FormatMarkdown.convertToMarkdown(
      type,
      _controller.text,
      fromIndex,
      toIndex,
      titleSize: titleSize,
      link: link,
      selectedText:
          selectedText ?? _controller.text.substring(fromIndex, toIndex),
    );

    _controller.value = _controller.value.copyWith(
        text: result.data,
        selection:
            TextSelection.collapsed(offset: basePosition + result.cursorIndex));

    if (noTextSelected) {
      _controller.selection = TextSelection.collapsed(
          offset: _controller.selection.end - result.replaceCursorIndex);
      focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    _controller.text = widget.initialValue;
    _controller.addListener(() {
      if (_controller.selection.baseOffset != -1)
        textSelection = _controller.selection;
      widget.onTextChanged(_controller.text);
    });

    super.initState();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Scrollbar(
        controller: _scrollController,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: const SizedBox(
                height: kDefaultPadding,
              ),
            ),
            SliverToBoxAdapter(
              child: TextFormField(
                minLines: 1,
                maxLines: 2,
                keyboardType: TextInputType.text,
                onFieldSubmitted: (event) => focusNode.requestFocus(),
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                controller: widget.titleController,
                decoration: InputDecoration(
                  hintText: 'Give me a catchy title',
                  hintStyle:
                      Theme.of(context).textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: kDimGrey,
                          ),
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  focusColor: Theme.of(context).primaryColorLight,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: widget.onTitleChanged,
              ),
            ),
            SliverAppBar(
              pinned: true,
              actions: [const SizedBox.shrink()],
              leading: null,
              automaticallyImplyLeading: false,
              title: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: widget.actions.map(
                          (type) {
                            switch (type) {
                              case MarkdownType.title:
                                return ExpandableNotifier(
                                  child: Expandable(
                                    key: Key('H#_button'),
                                    collapsed: ExpandableButton(
                                      child: const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Text(
                                            'H#',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ),
                                    expanded: Container(
                                      color: Colors.white10,
                                      child: Row(
                                        children: [
                                          for (int i = 1; i <= 6; i++)
                                            InkWell(
                                              key: Key('H${i}_button'),
                                              onTap: () => onTap(
                                                  MarkdownType.title,
                                                  titleSize: i),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Text(
                                                  'H$i',
                                                  style: TextStyle(
                                                      fontSize:
                                                          (18 - i).toDouble(),
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                              ),
                                            ),
                                          ExpandableButton(
                                            child: const Padding(
                                              padding: EdgeInsets.all(10),
                                              child: Icon(
                                                Icons.close,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              case MarkdownType.link:
                                return _basicInkwell(
                                  type,
                                  customOnTap: !widget.insertLinksByDialog
                                      ? null
                                      : () => setLink(type),
                                );
                              case MarkdownType.uploadedImage:
                                return _basicInkwell(
                                  type,
                                  customOnTap: !widget.insertLinksByDialog
                                      ? null
                                      : () => selectImage(type, context),
                                );
                              case MarkdownType.smartWidgets:
                                return _basicInkwell(
                                  type,
                                  customOnTap: !widget.insertLinksByDialog
                                      ? null
                                      : () => selectSmartWidget(type, context),
                                );
                              case MarkdownType.gpt:
                                return _basicInkwell(
                                  type,
                                  customOnTap: () =>
                                      addGptPrompt(type, context),
                                );
                              default:
                                return _basicInkwell(type);
                            }
                          },
                        ).toList(),
                      ),
                    ),
                    const VerticalDivider(
                      endIndent: 5,
                      indent: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: IconButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.nextFocus();
                          },
                          icon: Icon(
                            Icons.check,
                            color: kBlack,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _controller.text.isEmpty
                                ? kDimGrey
                                : Colors.green,
                            padding: const EdgeInsets.all(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: TextFormField(
                focusNode: focusNode,
                textInputAction: TextInputAction.newline,
                controller: _controller,
                contextMenuBuilder: (
                  BuildContext context,
                  EditableTextState editableTextState,
                ) {
                  return AdaptiveTextSelectionToolbar.editable(
                    anchors: editableTextState.contextMenuAnchors,
                    onLookUp: () {},
                    onSearchWeb: () {},
                    onShare: () {},
                    clipboardStatus: ClipboardStatus.pasteable,
                    onCopy: () => editableTextState
                        .copySelection(SelectionChangedCause.toolbar),
                    onCut: () => editableTextState
                        .cutSelection(SelectionChangedCause.toolbar),
                    onPaste: () async {
                      String pastableText = await getPastableString();

                      final cursorPos = _controller.selection.base.offset;

                      String suffixText = _controller.text.substring(cursorPos);

                      String specialChars = pastableText;
                      int length = specialChars.length;

                      String prefixText =
                          _controller.text.substring(0, cursorPos);

                      _controller.text = prefixText + specialChars + suffixText;
                      _controller.selection = TextSelection(
                        baseOffset: cursorPos + length,
                        extentOffset: cursorPos + length,
                      );

                      editableTextState.updateEditingValue(
                        editableTextState.currentTextEditingValue.copyWith(
                          text: prefixText + specialChars + suffixText,
                        ),
                      );

                      editableTextState.hideToolbar();
                    },
                    onSelectAll: () => editableTextState.selectAll(
                      SelectionChangedCause.toolbar,
                    ),
                    onLiveTextInput: () {},
                  );
                },
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                validator: widget.validators != null
                    ? (value) => widget.validators!(value)
                    : null,
                style:
                    widget.textStyle ?? Theme.of(context).textTheme.labelMedium,
                cursorColor: Theme.of(context).primaryColorDark,
                textDirection: widget.textDirection,
                decoration: InputDecoration(
                  hintText: widget.label,
                  hintStyle: const TextStyle(color: kDimGrey),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  fillColor: kTransparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> getPastableString() async {
    String pastableText = '';

    await Clipboard.getData('text/plain').then(
      (data) => pastableText = data?.text?.trim() ?? '',
    );

    if (pastableText.startsWith('http')) {
      if (pastableText.endsWith(Pastables.IMAGE_FORMAT_JPEG) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_JPG) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_GIF) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_PNG) ||
          pastableText.endsWith(Pastables.IMAGE_FORMAT_WEBP)) {
        pastableText = '![image]($pastableText)';
      } else if (pastableText.contains(Pastables.NOSTR_SCHEME_NPROFILE)) {
        String newPastableText = pastableText.substring(
            pastableText.indexOf(
              Pastables.NOSTR_SCHEME_NPROFILE,
            ),
            pastableText.length);

        pastableText = 'nostr:' + newPastableText;
      } else if (pastableText.contains(Pastables.NOSTR_SCHEME_NADDR)) {
        String newPastableText = pastableText.substring(
            pastableText.indexOf(
              Pastables.NOSTR_SCHEME_NADDR,
            ),
            pastableText.length);

        pastableText = 'nostr:' + newPastableText;
      }
    }

    return pastableText;
  }

  void setLink(MarkdownType type) async {
    var text = _controller.text
        .substring(textSelection.baseOffset, textSelection.extentOffset);

    var textController = TextEditingController()..text = text;
    var linkController = TextEditingController();
    var textFocus = FocusNode();
    var linkFocus = FocusNode();

    var color = Theme.of(context).colorScheme.secondary;

    var textLabel = 'Text';
    var linkLabel = 'Link';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                  child: Icon(Icons.close), onTap: () => Navigator.pop(context))
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'example',
                  label: Text(textLabel),
                  labelStyle: TextStyle(color: color),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color, width: 2)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color, width: 2)),
                ),
                autofocus: text.isEmpty,
                focusNode: textFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (value) {
                  textFocus.unfocus();
                  FocusScope.of(context).requestFocus(linkFocus);
                },
              ),
              SizedBox(height: 10),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  label: Text(linkLabel),
                  labelStyle: TextStyle(color: color),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                autofocus: text.isNotEmpty,
                focusNode: linkFocus,
              ),
              SizedBox(height: 10),
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          actions: [
            TextButton(
              onPressed: () {
                onTap(
                  type,
                  link: linkController.text,
                  selectedText: textController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void selectImage(MarkdownType type, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ImageSelector(
          onTap: (link) {
            onTap(
              type,
              link: link,
            );
          },
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  void selectSmartWidget(MarkdownType type, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SmartWidgetSelection(
          onWidgetAdded: (sw) {
            onTap.call(type, link: sw.getNaddr());
            Navigator.pop(context);
          },
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  void addGptPrompt(MarkdownType type, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ChatGpt(
          insertText: (text) {
            onTap(
              type,
              link: text,
            );
          },
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _basicInkwell(MarkdownType type, {Function? customOnTap}) {
    final isSvg = type == MarkdownType.uploadedImage ||
        type == MarkdownType.gpt ||
        type == MarkdownType.image ||
        type == MarkdownType.smartWidgets;

    return InkWell(
      key: Key(type.key),
      onTap: () => customOnTap != null ? customOnTap() : onTap(type),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: isSvg
            ? SvgPicture.asset(
                getSvgIcon(type),
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  type == MarkdownType.gpt
                      ? Colors.green.shade400
                      : Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              )
            : Icon(type.icon),
      ),
    );
  }

  String getSvgIcon(MarkdownType type) {
    if (type == MarkdownType.uploadedImage) {
      return FeatureIcons.imageUpload;
    } else if (type == MarkdownType.gpt) {
      return FeatureIcons.gpt;
    } else if (type == MarkdownType.image) {
      return FeatureIcons.imageLink;
    } else {
      return FeatureIcons.smartWidget;
    }
  }
}
