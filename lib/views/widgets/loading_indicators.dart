import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class EasyLoadingIndicatorWidget extends StatelessWidget {
  const EasyLoadingIndicatorWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          LogosIcons.logoMarkPurple,
          width: 15.w,
          height: 15.w,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        SizedBox(
          width: 25.w,
          height: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            child: const LinearProgressIndicator(
              color: kPurple,
              backgroundColor: kWhite,
            ),
          ),
        )
      ],
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pulse(
            infinite: true,
            duration: const Duration(seconds: 1),
            child: SvgPicture.asset(
              LogosIcons.logoMarkPurple,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
              width: 45,
              height: 45,
            ),
          ),
        ],
      ),
    );
  }
}
