import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class EmptyList extends StatelessWidget {
  const EmptyList({
    Key? key,
    required this.description,
    required this.icon,
  }) : super(key: key);

  final String description;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      primary: false,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding * 2,
      ),
      children: [
        Text(
          'Oops! Nothing to show here!',
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
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: kDimGrey,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SvgPicture.asset(
          icon,
          width: 35,
          height: 35,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }
}
