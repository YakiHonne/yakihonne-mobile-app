import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:yakihonne/utils/utils.dart';

void singleSnackBar({
  required BuildContext context,
  required String message,
  required Color color,
  required Color backGroundColor,
  required String icon,
}) {
  bool isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

  showTopSnackBar(
    Overlay.of(context),
    dismissType: DismissType.onTap,
    curve: Curves.decelerate,
    animationDuration: const Duration(milliseconds: 300),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.w : 0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: kTransparent,
        child: Container(
          decoration: BoxDecoration(
            color: backGroundColor,
            borderRadius: BorderRadius.circular(kDefaultPadding),
            border: Border.all(color: color),
          ),
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding - 5),
            child: Row(
              children: [
                SvgPicture.asset(
                  height: 30,
                  width: 30,
                  icon,
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: kBlack,
                        ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: kBlack,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void showCupertinoDeletionDialogue({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  required Function() onDelete,
  bool? setMaxLine,
}) {
  showCupertinoDialog(
    context: context,
    builder: (alertContext) => CupertinoAlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: setMaxLine != null ? 3 : null,
        overflow: TextOverflow.ellipsis,
      ),
      content: Text(
        description,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              color: kRed,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'cancel',
            style: TextStyle(
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
        ),
      ],
    ),
  );
}

void showCupertinoCustomDialogue({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  required Color buttonTextColor,
  required Function() onClicked,
  bool? setMaxLine,
}) {
  showCupertinoDialog(
    context: context,
    builder: (alertContext) => CupertinoAlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: setMaxLine != null ? 3 : null,
        overflow: TextOverflow.ellipsis,
      ),
      content: Text(
        description,
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: onClicked,
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              color: buttonTextColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'cancel',
            style: TextStyle(
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
        ),
      ],
    ),
  );
}

void showDeletionDialogue({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  required Function() onDelete,
  bool? setMaxLine,
}) {
  showDialog(
    context: context,
    builder: (alertContext) => AlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: setMaxLine != null ? 3 : null,
        overflow: TextOverflow.ellipsis,
      ),
      titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w800,
          ),
      content: Text(
        description,
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: onDelete,
          child: Text(
            buttonText,
            style: TextStyle(color: kWhite),
          ),
          style: TextButton.styleFrom(
            backgroundColor: kRed,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: kRed,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            side: BorderSide(
              color: kRed,
            ),
          ),
        ),
      ],
    ),
  );
}

void showAccountDeletionDialogue({
  required BuildContext context,
  required Function() onDelete,
}) {
  showDialog(
    context: context,
    builder: (_) {
      final confirm = TextEditingController();
      final _formKey = GlobalKey<FormState>();

      return AlertDialog(
        title: Text(
          'Delete account?',
          textAlign: TextAlign.center,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w800,
            ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You are about to delete your account permenantly, you won't be able to log back in.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: confirm,
                decoration: InputDecoration(
                  hintText: 'Type DELETE',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value != 'DELETE') {
                    return 'invalid input';
                  }

                  return null;
                },
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                onDelete.call();
              }
            },
            child: Text(
              'Delete',
            ),
            style: TextButton.styleFrom(
              backgroundColor: kRed,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: kRed,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: kTransparent,
              side: BorderSide(
                color: kRed,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void showDeletedAccountDialogue({
  required BuildContext context,
}) {
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(
          'Deleted account!',
          textAlign: TextAlign.center,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w800,
            ),
        content: Text(
          'You are attempting to login to a deleted account.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Exit',
              style: TextStyle(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: kTransparent,
              side: BorderSide(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
          ),
        ],
      );
    },
  );
}
