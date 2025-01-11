// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

class HVDescription extends StatelessWidget {
  const HVDescription({
    Key? key,
    required this.title,
    required this.upvotes,
    required this.views,
    required this.tags,
    required this.createdAt,
    required this.description,
  }) : super(key: key);

  final String title;
  final String upvotes;
  final String views;
  final List<String> tags;
  final DateTime createdAt;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(kDefaultPadding),
      child: Container(
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.40,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              ModalBottomSheetHandle(),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Divider(
                height: 0,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(
                    kDefaultPadding / 1.5,
                  ),
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _descriptionColumn(
                            context: context,
                            description: 'Upvotes',
                            title: upvotes,
                          ),
                        ),
                        Expanded(
                          child: _descriptionColumn(
                            context: context,
                            description: 'Views',
                            title: views,
                          ),
                        ),
                        Expanded(
                          child: _descriptionColumn(
                            context: context,
                            description: createdAt.year.toString(),
                            title: dateFormat6.format(createdAt),
                          ),
                        ),
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(
                        height: kDefaultPadding,
                      ),
                      SizedBox(
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
                                  color: Theme.of(context).highlightColor,
                                  textColor: Theme.of(context).primaryColorDark,
                                  onClicked: () {
                                    Navigator.pushNamed(
                                      context,
                                      TagView.routeName,
                                      arguments: tag,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(
                        height: kDefaultPadding,
                      ),
                      Container(
                        padding: const EdgeInsets.all(kDefaultPadding / 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          borderRadius: BorderRadius.circular(
                            kDefaultPadding / 2,
                          ),
                        ),
                        child:
                            linkifiedText(context: context, text: description),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column _descriptionColumn({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
