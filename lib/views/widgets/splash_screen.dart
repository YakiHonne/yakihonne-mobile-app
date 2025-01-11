import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../utils/utils.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorLight,
      body: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                LogosIcons.logoPurple,
                width: 150,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              SpinKitSpinningLines(
                size: 30,
                color: Theme.of(context).primaryColorDark,
              )
            ],
          ),
        ),
      ),
    );
  }
}
