// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';

class FlashTagsRow extends StatelessWidget {
  const FlashTagsRow({
    Key? key,
    required this.isImportant,
    required this.tags,
    this.selectedTag,
  }) : super(key: key);

  final bool isImportant;
  final List<String> tags;

  final String? selectedTag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isImportant) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(300),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  FeatureIcons.flame,
                  height: 16,
                  fit: BoxFit.fitHeight,
                  colorFilter: ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Text(
                  'Important',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: kWhite,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          )
        ],
        Expanded(
          child: SizedBox(
            height: 24,
            child: ScrollShadow(
              color: Theme.of(context).primaryColorLight,
              size: 10,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    width: kDefaultPadding / 4,
                  );
                },
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  if (tag.trim().isEmpty) {
                    return SizedBox.shrink();
                  }

                  return Center(
                    child: InfoRoundedContainer(
                      tag: tag,
                      color: selectedTag != null && selectedTag == tag
                          ? kPurple
                          : Theme.of(context).highlightColor,
                      textColor: Theme.of(context).primaryColorDark,
                      onClicked: () {
                        if (selectedTag == null || selectedTag != tag) {
                          Navigator.pushNamed(
                            context,
                            TagView.routeName,
                            arguments: tag,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
