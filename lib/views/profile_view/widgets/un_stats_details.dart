// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

import '../../../utils/utils.dart';

class UnStatsDetails extends StatelessWidget {
  const UnStatsDetails({
    Key? key,
    required this.isWriting,
    required this.totalVal,
    required this.firstVal,
    required this.secondVal,
    required this.thirdVal,
    required this.fourthVal,
    required this.fifthVal,
  }) : super(key: key);

  final bool isWriting;
  final num totalVal;
  final num firstVal;
  final num secondVal;
  final num thirdVal;
  final num fourthVal;
  final num fifthVal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            primary: false,
            shrinkWrap: true,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: totalVal == 0
                      ? kDimGrey
                      : totalVal < 0
                          ? kRed
                          : kGreen,
                ),
                child: Column(
                  children: [
                    ModalBottomSheetHandle(
                      color: kWhite,
                    ),
                    Text(
                      'Uncensored Notes stats',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: kWhite,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${totalVal} ',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                color: kWhite,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          isWriting ? 'Writing impact' : 'Rating impact',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: kWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Column(
                  children: [
                    Builder(builder: (context) {
                      final texts = getFirstTexts(isWriting, 0);

                      return unStatsDataColumn(
                        totalVal: '+${firstVal}',
                        color: kGreen,
                        title: texts.first,
                        description: texts.last,
                      );
                    }),
                    Divider(
                      thickness: 0.5,
                      height: kDefaultPadding * 2,
                      endIndent: kDefaultPadding * 2,
                      indent: kDefaultPadding * 2,
                    ),
                    Builder(builder: (context) {
                      final texts = getFirstTexts(isWriting, 1);
                      return unStatsDataColumn(
                        totalVal: '${isWriting ? '-' : '+'}$secondVal',
                        color: isWriting ? kRed : kGreen,
                        title: texts.first,
                        description: texts.last,
                      );
                    }),
                    Divider(
                      thickness: 0.5,
                      height: kDefaultPadding * 2,
                      endIndent: kDefaultPadding * 2,
                      indent: kDefaultPadding * 2,
                    ),
                    Builder(builder: (context) {
                      final texts = getFirstTexts(isWriting, 2);
                      return unStatsDataColumn(
                        totalVal: '${isWriting ? '' : '-'}${thirdVal}',
                        color: isWriting ? kDimGrey : kRed,
                        title: texts.first,
                        description: texts.last,
                      );
                    }),
                    if (!isWriting) ...[
                      Divider(
                        thickness: 0.5,
                        height: kDefaultPadding * 2,
                        endIndent: kDefaultPadding * 2,
                        indent: kDefaultPadding * 2,
                      ),
                      unStatsDataColumn(
                        timeTwo: true,
                        totalVal: '-${fourthVal}',
                        color: kRed,
                        title:
                            'Ratings of Not Helpful on notes that ended up with a status of Helpful',
                        description:
                            'These ratings are counted twice because they often indicate support for notes that others deemed helpful.',
                      ),
                      Divider(
                        thickness: 0.5,
                        height: kDefaultPadding * 2,
                        endIndent: kDefaultPadding * 2,
                        indent: kDefaultPadding * 2,
                      ),
                      unStatsDataColumn(
                        totalVal: '${fifthVal}',
                        color: kDimGrey,
                        title: 'Notes with ongoing ratings',
                        description:
                            "Ratings on notes that don't currently have a status of Helpful or Not Helpful",
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> getFirstTexts(bool isWriting, int isFirst) {
    return isFirst == 0
        ? [
            isWriting
                ? 'Notes that earned the status of Helpful'
                : 'Ratings that helped a note earn the status of Helpful',
            isWriting
                ? 'These notes are now showing to everyone who sees the post, adding context and helping keep people informed.'
                : 'These ratings identified Helpful notes that gets shown to everyone, adding context and helping keep people informed.',
          ]
        : isFirst == 1
            ? [
                isWriting
                    ? 'Notes that reached the status of Not Helpful'
                    : 'Ratings that helped a note earn the status of Not Helpful',
                isWriting
                    ? 'These notes have been rated Not Helpful by enough contributors, including those who sometimes disagree in their past ratings.'
                    : 'These ratings improve Uncensored Notes by giving feedback to note authors, and allowing contributors to focus on the most promising notes',
              ]
            : [
                isWriting
                    ? 'Notes that need more ratings'
                    : 'Ratings of Not Helpful on notes that ended up with a status of Helpful',
                isWriting
                    ? "Notes that don't yet have a status of Helpful or Not Helpful."
                    : "Don't worry, everyone gets some of these! These ratings are common and can lead to status changes if enough people agree that a 'Helpful' note isn't sufficiently helpful.",
              ];
  }
}

class unStatsDataColumn extends StatelessWidget {
  const unStatsDataColumn(
      {Key? key,
      required this.totalVal,
      required this.title,
      required this.description,
      required this.color,
      this.timeTwo})
      : super(key: key);

  final String totalVal;
  final String title;
  final String description;
  final Color color;
  final bool? timeTwo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${totalVal}',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            if (timeTwo != null) ...[
              SizedBox(
                width: kDefaultPadding / 2,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 3),
                  color: kRed.withValues(alpha: 0.4),
                ),
                child: Text(
                  'x2',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.w700, color: kRed),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          description,
          style:
              Theme.of(context).textTheme.bodySmall!.copyWith(color: kDimGrey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
