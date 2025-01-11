// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

import '../../write_article_view/widgets/article_details.dart';

class CommentPrefix extends HookWidget {
  const CommentPrefix({
    required this.comment,
    required this.kind,
    required this.submitComment,
    required this.shareableLink,
  });

  final String comment;
  final int kind;
  final Function(bool, String) submitComment;
  final String shareableLink;

  @override
  Widget build(BuildContext context) {
    final isPrefixUsed = useState(true);

    return Container(
      height: 90.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          ModalBottomSheetHandle(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(kDefaultPadding),
              children: [
                Text(
                  'Be meaningful 🥳',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Container(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  margin: const EdgeInsets.only(top: kDefaultPadding / 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    border: Border.all(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your comment ${isPrefixUsed.value ? 'with' : 'without'} suffix.',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: comment,
                              style: TextStyle(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            if (isPrefixUsed.value)
                              TextSpan(
                                text:
                                    '\n\nThis is a comment on: ${baseUrl}${kind == EventKind.LONG_FORM ? 'article' : kind == EventKind.CURATION_ARTICLES ? 'curations' : 'flash-news'}/${shareableLink}',
                                style: TextStyle(color: kOrange),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    color: Theme.of(context).primaryColorLight,
                  ),
                  child: ArticleCheckBoxListTile(
                    isEnabled: true,
                    status: isPrefixUsed.value,
                    text: 'Use the YakiHonne suffix.',
                    onToggle: () {
                      isPrefixUsed.value = !isPrefixUsed.value;
                    },
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Text(
                  'This can always be changed in your account settings',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kDefaultPadding / 4,
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            alignment: Alignment.center,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: kTransparent,
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      submitComment.call(
                        isPrefixUsed.value,
                        '$comment' +
                            (isPrefixUsed.value
                                ? ' — This is a comment on: ${baseUrl}article/${shareableLink}'
                                : ''),
                      );
                    },
                    child: Text('Comment'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final description =
      'Let your comments be recognized on NOSTR notes clients by adding where did you comment. Choose what suits you best!';
}
