import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:yakihonne/utils/utils.dart';

SpanNodeGeneratorWithTag latexGenerator = SpanNodeGeneratorWithTag(
    tag: _latexTag,
    generator: (e, config, visitor) =>
        LatexNode(e.attributes, e.textContent, config));

const _latexTag = 'latex';

class LatexSyntax extends m.InlineSyntax {
  LatexSyntax() : super(r'(`\$\$[\s\S]+\$\$`)|(`\$.+?\$`)');

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final input = match.input;
    final matchValue = input.substring(match.start, match.end);
    String content = '';
    bool isInline = true;
    const blockSyntax = '`\$\$';
    const endBlockSyntax = '\$\$`';
    const inlineSyntax = '`\$';
    const endInlineSyntax = '\$`';
    if (matchValue.startsWith(blockSyntax) &&
        matchValue.endsWith(endBlockSyntax) &&
        (matchValue != blockSyntax)) {
      content = matchValue.substring(3, matchValue.length - 3);
      isInline = false;
    } else if (matchValue.startsWith(inlineSyntax) &&
        matchValue.endsWith(endInlineSyntax) &&
        matchValue != inlineSyntax) {
      content = matchValue.substring(2, matchValue.length - 2);
    }
    m.Element el = m.Element.text(_latexTag, matchValue);
    el.attributes['content'] = content;
    el.attributes['isInline'] = '$isInline';
    parser.addNode(el);
    return true;
  }
}

class LatexNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  LatexNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final isInline = attributes['isInline'] == 'true';
    final style = parentStyle ?? config.p.textStyle;
    if (content.isEmpty) return TextSpan(style: style, text: textContent);

    final latex = Math.tex(
      content,
      mathStyle: MathStyle.text,
      textScaleFactor: 1,
      textStyle: TextStyle(
        fontSize: 14,
        color: isInline ? null : kBlack,
      ),
      onErrorFallback: (error) {
        return Text(
          '$textContent',
          style: style.copyWith(color: Colors.red),
        );
      },
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: !isInline
          ? Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
              decoration: BoxDecoration(
                color: kDimGrey,
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              ),
              child: Center(
                child: latex,
              ),
            )
          : latex,
    );
  }
}
