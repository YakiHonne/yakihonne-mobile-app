import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/home_cubit/topcis_cubit/topics_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/auto_complete_textfield.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

class AddCustomTopic extends StatefulWidget {
  AddCustomTopic({super.key});

  @override
  State<AddCustomTopic> createState() => _AddCustomTopicState();
}

class _AddCustomTopicState extends State<AddCustomTopic> {
  final GlobalKey<AutoCompleteTextFieldState<String>> key = GlobalKey();
  final textEditingController = TextEditingController();
  List<String> selectedTopics = [];

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
        initialChildSize: 0.9,
        minChildSize: 0.60,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            ModalBottomSheetHandle(),
            BlocBuilder<TopicsCubit, TopicsState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: SimpleAutoCompleteTextField(
                          key: key,
                          cursorColor: Theme.of(context).primaryColorDark,
                          decoration: InputDecoration(
                            hintText: 'Add your custom topic',
                          ),
                          controller: textEditingController,
                          suggestions: state.suggestions,
                          clearOnSubmit: true,
                          textSubmitted: (text) {
                            if (!selectedTopics.contains(text)) {
                              setState(
                                () {
                                  selectedTopics.add(text.trim());
                                },
                              );
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final text = textEditingController.text;

                          if (text.isNotEmpty &&
                              !selectedTopics.contains(text.trim())) {
                            setState(
                              () {
                                selectedTopics.add(text);
                                textEditingController.clear();
                              },
                            );
                          }
                        },
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Wrap(
                  runSpacing: kDefaultPadding / 4,
                  spacing: kDefaultPadding / 4,
                  alignment: WrapAlignment.center,
                  children: selectedTopics
                      .map(
                        (keyword) => Chip(
                          visualDensity: VisualDensity(vertical: -4),
                          label: Text(
                            keyword,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  height: 1.5,
                                ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(200),
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedTopics.remove(keyword);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Container(
              height: kBottomNavigationBarHeight +
                  MediaQuery.of(context).padding.bottom,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
                left: kDefaultPadding,
                right: kDefaultPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 15,
                      ),
                    ),
                    onPressed: () {
                      if (selectedTopics.isNotEmpty) {
                        context.read<TopicsCubit>().addCustomTopics(
                              topics: selectedTopics,
                              onSuccess: () {
                                Navigator.pop(context);
                              },
                            );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor:
                          selectedTopics.isNotEmpty ? kGreen : kDimGrey,
                    ),
                    label: Text(
                      'update',
                      style: TextStyle(
                        color: kWhite,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
