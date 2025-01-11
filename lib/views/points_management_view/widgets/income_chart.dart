import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/utils/utils.dart';

class IncomeChart extends StatefulWidget {
  const IncomeChart({
    required this.chart,
    super.key,
  });

  final Color barColor = kPurple;
  final Color touchedBarColor = kDimPurple;
  final List<Chart> chart;

  @override
  State<StatefulWidget> createState() => IncomeChartState();
}

class IncomeChartState extends State<IncomeChart> {
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
      ),
      padding: const EdgeInsets.all(
        kDefaultPadding / 2,
      ),
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Engagement chart',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Expanded(
            child: BarChart(
              mainBarData(context),
              swapAnimationDuration: animDuration,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    required BuildContext context,
    Color? barColor,
    double width = 20,
    List<int> showTooltips = const [],
  }) {
    barColor ??= widget.barColor;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + (highestNumber() / 20) : y,
          color: isTouched ? kOrange : kRed,
          width: width,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: highestNumber() + highestNumber() / 10,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  double highestNumber() {
    final list = widget.chart.map((e) => e.action?.allTimePoints ?? 0).toList();
    final highest = list.reduce(max);
    return (highest == 0 ? 1 : highest).toDouble();
  }

  List<BarChartGroupData> showingGroups(BuildContext context) => List.generate(
        widget.chart.length,
        (i) {
          return makeGroupData(
            i,
            (widget.chart[i].action?.allTimePoints ?? 0).toDouble() +
                (highestNumber() / 10),
            isTouched: i == touchedIndex,
            context: context,
          );
        },
      );

  BarChartData mainBarData(BuildContext context) {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          tooltipRoundedRadius: kDefaultPadding / 2,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding / 4,
          ),
          fitInsideVertically: true,
          fitInsideHorizontally: true,
          tooltipBorder: BorderSide(color: kGreen),
          getTooltipColor: (group) {
            return Theme.of(context).primaryColorLight;
          },
          maxContentWidth: double.infinity,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final chartItem = widget.chart[groupIndex];

            return BarTooltipItem(
              '',
              Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
              textAlign: TextAlign.center,
              children: [
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${chartItem.standard.displayName}',
                    ),
                    TextSpan(
                      text: ' • ',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: '${chartItem.action?.allTimePoints ?? 0} ',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kOrange,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    TextSpan(
                      text: 'xp\n',
                    ),
                    TextSpan(
                      text:
                          'Last gained: ${chartItem.action != null ? dateFormat4.format(chartItem.action!.lastUpdated) : 'N/A'}',
                    )
                  ],
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 45,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(context),
      gridData: FlGridData(show: false),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    TextStyle style = TextStyle(
      color: kDimGrey,
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: Text(
          '${(widget.chart[value.toInt()].action?.allTimePoints ?? 0).toString()}\nxp',
          style: style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
