import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/utils/utils.dart';

class FrameContent extends HookWidget {
  const FrameContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final titleController = useTextEditingController(
        text: context.read<WriteSmartWidgetCubit>().state.title);
    final summaryController = useTextEditingController(
      text: context.read<WriteSmartWidgetCubit>().state.summary,
    );

    return BlocConsumer<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      listenWhen: (previous, current) =>
          previous.smartWidgetUpdate != current.smartWidgetUpdate,
      listener: (context, state) {
        titleController.text = state.title;
        summaryController.text = state.summary;
      },
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
          children: [
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Title (Optional)',
              ),
              maxLines: 1,
              onChanged: (text) {
                context.read<WriteSmartWidgetCubit>().setTitle(text);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              controller: summaryController,
              decoration: InputDecoration(
                hintText: 'Summary (Optional)',
              ),
              minLines: 4,
              maxLines: 4,
              onChanged: (text) {
                context.read<WriteSmartWidgetCubit>().setSummary(text);
              },
            ),
          ],
        );
      },
    );
  }
}
