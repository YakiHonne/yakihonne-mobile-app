import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:html/parser.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:string_validator/string_validator.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/utils/markdown/code_wrapper_widget.dart';
import 'package:yakihonne/utils/markdown/html_support.dart';
import 'package:yakihonne/utils/markdown/iframe.dart';
import 'package:yakihonne/utils/markdown/math_text_node.dart';
import 'package:yakihonne/utils/markdown/nostr_scheme.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';

class MarkDownWidget extends StatelessWidget {
  const MarkDownWidget({
    super.key,
    required this.content,
    required this.onLinkClicked,
  });

  final String content;
  final Function(String) onLinkClicked;

  @override
  Widget build(BuildContext context) {
    final codeWrapper =
        (child, text) => CodeWrapperWidget(child: child, text: text);

    return MarkdownWidget(
      data: content,
      shrinkWrap: true,
      selectable: true,
      markdownGenerator: MarkdownGenerator(
        generators: [
          latexGenerator,
          nostrGenerator,
        ],
        inlineSyntaxList: [
          LatexSyntax(),
          nostrSyntax(),
        ],
        textGenerator: (node, config, visitor) =>
            CustomTextNode(node.textContent, config, visitor),
      ),
      config: context.read<ThemeCubit>().state.theme == AppTheme.purpleDark
          ? MarkdownConfig.darkConfig.copy(
              configs: [
                context.read<ThemeCubit>().state.theme == AppTheme.purpleDark
                    ? PreConfig.darkConfig.copy(
                        wrapper: codeWrapper,
                        textStyle: TextStyle(
                          color: kWhite,
                        ),
                      )
                    : PreConfig().copy(wrapper: codeWrapper),
                ...configs(context)
              ],
            )
          : MarkdownConfig.defaultConfig.copy(
              configs: [
                context.read<ThemeCubit>().state.theme == AppTheme.purpleDark
                    ? PreConfig.darkConfig.copy(wrapper: codeWrapper)
                    : PreConfig().copy(wrapper: codeWrapper),
                ...configs(context),
              ],
            ),
      physics: ScrollPhysics(
        parent: NeverScrollableScrollPhysics(),
      ),
    );
  }

  List<WidgetConfig> configs(BuildContext context) {
    return [
      ImgConfig(
        builder: (url, attributes) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final imageProvider = CachedNetworkImageProvider(url);
                  showImageViewer(
                    context,
                    imageProvider,
                    doubleTapZoomable: true,
                    swipeDismissible: true,
                  );
                },
                child: url.isEmpty
                    ? SizedBox(
                        height: 120,
                        width: 200,
                        child: NoMediaPlaceHolder(
                          image: '',
                          isError: false,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: url,
                        errorWidget: (context, url, error) => SizedBox(
                          height: 120,
                          width: 200,
                          child: NoMediaPlaceHolder(
                            image: '',
                            isError: false,
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
      BlockquoteConfig(
        textColor: kDimGrey,
      ),
      ListConfig(),
      LinkConfig(
        onTap: onLinkClicked,
        style: TextStyle(
          color: Colors.blue,
        ),
      ),
    ];
  }
}

class CustomTextNode extends ElementNode {
  final String text;
  final MarkdownConfig config;
  final WidgetVisitor visitor;
  CustomTextNode(this.text, this.config, this.visitor);

  @override
  void onAccepted(SpanNode parent) async {
    final textStyle = config.p.textStyle.merge(parentStyle);
    children.clear();

    if (isURL(text)) {
      accept(LinkifierNode(text));
      return;
    } else if (!text.contains(htmlRep) &&
        !(text.startsWith('\$\$') && text.endsWith('\$\$'))) {
      accept(TextNode(text: text, style: textStyle));
      return;
    } else if (text.trim().startsWith('<blockquote class=')) {
      accept(BlockQuoteNode(text));
      return;
    } else if (text.trim().startsWith('<img') &&
        text.trim().contains('src="')) {
      var document = parse(text);
      dom.Element? link = document.querySelector('img');
      accept(LinkifierNode('${link != null ? link.attributes['src'] : ''}'));
    } else if (text.toLowerCase().contains('iframe')) {
      final urlMatches = urlRegExp.allMatches(text);
      List<String> urls = urlMatches
          .map((urlMatch) => text.substring(urlMatch.start, urlMatch.end))
          .toList();

      if (urls.isNotEmpty) {
        accept(IframeNode(urls.first));
      }

      return;
    }
  }
}
