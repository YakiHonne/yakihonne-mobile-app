// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class ArticleReports extends HookWidget {
  const ArticleReports({
    required this.onReport,
    required this.isArticle,
    required this.title,
  });

  final Function(String, String) onReport;
  final bool isArticle;
  final String title;

  @override
  Widget build(BuildContext context) {
    final selectedType = useState(-1);
    final commentController = useTextEditingController(text: '');
    const reasons = [
      'Nudity',
      'Profanity',
      'Illegal',
      'Spam',
      'Impersonation',
    ];

    return Container(
      height: 80.h,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Column(
          children: [
            ModalBottomSheetHandle(),
            Expanded(
              child: ListView(
                physics: ClampingScrollPhysics(),
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      children: [
                        TextSpan(text: 'Report '),
                        TextSpan(
                            text: '"$title"',
                            style: TextStyle(
                              color: kOrange,
                            )),
                        TextSpan(text: ' ?'),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    'We are sorry to hear that you have faced an inconvenice by reading this ${isArticle ? 'article' : 'curation'}, please state the reason behind your report.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ReportOption(
                          onClicked: () {
                            if (selectedType.value == 0) {
                              selectedType.value = -1;
                            } else {
                              selectedType.value = 0;
                            }
                          },
                          isSelected: selectedType.value == 0,
                          text: reasons[0],
                        ),
                      ),
                      Expanded(
                        child: ReportOption(
                          onClicked: () {
                            if (selectedType.value == 1) {
                              selectedType.value = -1;
                            } else {
                              selectedType.value = 1;
                            }
                          },
                          isSelected: selectedType.value == 1,
                          text: reasons[1],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ReportOption(
                          onClicked: () {
                            if (selectedType.value == 2) {
                              selectedType.value = -1;
                            } else {
                              selectedType.value = 2;
                            }
                          },
                          isSelected: selectedType.value == 2,
                          text: reasons[2],
                        ),
                      ),
                      Expanded(
                        child: ReportOption(
                          onClicked: () {
                            if (selectedType.value == 3) {
                              selectedType.value = -1;
                            } else {
                              selectedType.value = 3;
                            }
                          },
                          isSelected: selectedType.value == 3,
                          text: reasons[3],
                        ),
                      ),
                    ],
                  ),
                  ReportOption(
                    onClicked: () {
                      if (selectedType.value == 4) {
                        selectedType.value = -1;
                      } else {
                        selectedType.value = 4;
                      }
                    },
                    isSelected: selectedType.value == 4,
                    text: reasons[4],
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  TextFormField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment (Optional)',
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  if (selectedType.value == -1) {
                    singleSnackBar(
                      context: context,
                      message: 'Select a reason for your report',
                      color: kOrange,
                      backGroundColor: kOrangeSide,
                      icon: ToastsIcons.warning,
                    );
                  } else {
                    onReport.call(
                      reasons[selectedType.value],
                      commentController.text,
                    );
                  }
                },
                child: Text('Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportOption extends StatelessWidget {
  const ReportOption({
    Key? key,
    required this.onClicked,
    required this.isSelected,
    required this.text,
  }) : super(key: key);

  final Function() onClicked;
  final bool isSelected;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(kDefaultPadding / 1.5),
        margin: const EdgeInsets.all(kDefaultPadding / 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          border: Border.all(
            color: isSelected ? kOrange : kDimGrey,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
