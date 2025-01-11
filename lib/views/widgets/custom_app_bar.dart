import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.notElevated,
    this.onBackClicked,
    this.onLogoClicked,
  });

  final String? title;
  final bool? notElevated;
  final Function()? onBackClicked;
  final Function()? onLogoClicked;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: FadeInRight(
        duration: const Duration(milliseconds: 500),
        from: 30,
        child: IconButton(
          onPressed: onBackClicked ??
              () {
                Navigator.pop(context);
              },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
      ),
      centerTitle: true,
      elevation: notElevated != null ? 0 : null,
      scrolledUnderElevation: notElevated != null ? 0 : null,
      title: title != null
          ? FadeInDown(
              duration: const Duration(milliseconds: 300),
              from: 15,
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            )
          : null,
      actions: [
        GestureDetector(
          onTap: onLogoClicked ??
              () {
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );

                context
                    .read<NostrDataRepository>()
                    .homeViewController
                    .add(true);
              },
          child: Hero(
            tag: 'mainIcon',
            child: SvgPicture.asset(
              LogosIcons.logoMarkPurple,
              height: kToolbarHeight / 1.8,
              fit: BoxFit.scaleDown,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
