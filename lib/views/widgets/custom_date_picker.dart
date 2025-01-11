// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/utils/utils.dart';

import '../flash_news_view/widgets/flash_news_timeline_container.dart';

class PickDateTimeWidget extends HookWidget {
  const PickDateTimeWidget({
    Key? key,
    required this.focusedDate,
    required this.onDateSelected,
    required this.onClearDate,
    required this.isAfter,
  }) : super(key: key);

  final DateTime focusedDate;
  final Function(DateTime) onDateSelected;
  final Function() onClearDate;
  final bool isAfter;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final timeOfDay = useState<TimeOfDay>(
      TimeOfDay(hour: 0, minute: 0),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      height: isMobile ? 60.h : 40.h,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: ListView(
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Select a date',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: CustomIconButton(
                  onClicked: () {
                    Navigator.pop(context);
                  },
                  icon: FeatureIcons.close,
                  size: 25,
                  backgroundColor: Theme.of(context).primaryColorLight,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _buildDefaultSingleDatePickerWithValue(
            singleDatePickerValueWithDefaultValue: [focusedDate],
            onValueChanged: (p0) {
              onDateSelected.call(p0.first ?? DateTime.now());
            },
            context: context,
          ),
          Row(
            children: [
              Builder(
                builder: (context) {
                  final date = DateTime(
                    focusedDate.year,
                    focusedDate.month,
                    focusedDate.day,
                    timeOfDay.value.hour,
                    timeOfDay.value.minute,
                  );

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      final tod = await showTimePicker(
                        context: context,
                        initialTime: timeOfDay.value,
                      );

                      if (tod != null) {
                        timeOfDay.value = tod;
                        onDateSelected.call(
                          DateTime(
                            focusedDate.year,
                            focusedDate.month,
                            focusedDate.day,
                            timeOfDay.value.hour,
                            timeOfDay.value.minute,
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(kDefaultPadding / 2),
                        color: Theme.of(context).primaryColorLight,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 3,
                        horizontal: kDefaultPadding / 1.5,
                      ),
                      child: Text(
                        date.toHourMinutes(),
                      ),
                    ),
                  );
                },
              ),
              Spacer(),
              TextButton(
                onPressed: onClearDate,
                child: Text(
                  'Clear date',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSingleDatePickerWithValue({
    required List<DateTime> singleDatePickerValueWithDefaultValue,
    required Function(List<DateTime?>) onValueChanged,
    required BuildContext context,
  }) {
    final config = CalendarDatePicker2Config(
      selectedDayHighlightColor: kPurple,
      weekdayLabels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      weekdayLabelTextStyle: Theme.of(context).textTheme.labelMedium,
      firstDayOfWeek: 1,
      controlsHeight: 50,
      controlsTextStyle: TextStyle(
        color: Theme.of(context).primaryColorDark,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      selectedDayTextStyle: Theme.of(context).textTheme.labelMedium!,
      dayTextStyle: Theme.of(context).textTheme.labelMedium!,
      disabledDayTextStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: kDimGrey,
          ),
      selectableDayPredicate: (day) {
        final isNegative = day.difference(DateTime.now()).isNegative;
        return isAfter ? !isNegative : isNegative;
      },
    );

    return CalendarDatePicker2(
      config: config,
      value: singleDatePickerValueWithDefaultValue,
      onValueChanged: (dates) {
        onValueChanged.call(dates);
      },
    );
  }
}
