// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/tooltip_with_text.dart';

class MutedMark extends StatelessWidget {
  const MutedMark({
    Key? key,
    required this.kind,
  }) : super(key: key);

  final String kind;

  @override
  Widget build(BuildContext context) {
    return TooltipWithText(
      message: 'This $kind belongs to a muted user.',
      child: CircleAvatar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        radius: 12,
        child: SvgPicture.asset(
          FeatureIcons.mute,
          width: 15,
          height: 15,
          colorFilter: ColorFilter.mode(
            kRed,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
