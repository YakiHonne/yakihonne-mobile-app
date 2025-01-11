// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class UnFlashNewsAddNote extends HookWidget {
  const UnFlashNewsAddNote({
    required this.onAdd,
  });

  final Function(String, String, bool) onAdd;

  @override
  Widget build(BuildContext context) {
    final content = useTextEditingController();
    final source = useTextEditingController();
    final isCorrect = useState(false);

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
        initialChildSize: 0.95,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          children: [
            Center(child: ModalBottomSheetHandle()),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: kWhite,
                        ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: kRed,
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (content.text.trim().isEmpty) {
                      BotToastUtils.showError('Empty uncensored note content!');
                    } else {
                      onAdd.call(
                        content.text.trim(),
                        source.text.trim(),
                        isCorrect.value,
                      );
                    }
                  },
                  label: SvgPicture.asset(
                    FeatureIcons.add,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorLight,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.scaleDown,
                  ),
                  icon: Text(
                    'Post',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).primaryColorLight,
                        ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorDark,
                  ),
                ),
              ],
            ),
            Divider(
              height: kDefaultPadding,
              thickness: 0.5,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final pubKey = nostrRepository.user.pubKey;

                        return BlocSelector<AuthorsCubit, AuthorsState,
                            UserModel?>(
                          selector: (state) => state.authors[pubKey],
                          builder: (context, user) {
                            final author = user ??
                                emptyUserModel.copyWith(
                                  pubKey: pubKey,
                                  picturePlaceholder: getRandomPlaceholder(
                                    input: pubKey,
                                    isPfp: true,
                                  ),
                                );
                            return Row(
                              children: [
                                ProfilePicture2(
                                  size: 40,
                                  image: author.picture,
                                  placeHolder: author.picturePlaceholder,
                                  padding: 0,
                                  strokeWidth: 1,
                                  reduceSize: true,
                                  strokeColor: kWhite,
                                  onClicked: () {
                                    openProfileFastAccess(
                                      context: context,
                                      pubkey: author.pubKey,
                                    );
                                  },
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 2,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'See anything you want to improve?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium!,
                                      ),
                                      Text(
                                        'Write a note',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              maxLines: 6,
              controller: content,
              decoration: InputDecoration(
                hintText: 'What do you think about this ?',
              ),
              maxLength: 500,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              controller: source,
              decoration: InputDecoration(
                hintText: 'Source (recommended)',
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'You find this flash news ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        isCorrect.value ? 'correct.' : 'misleading.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: isCorrect.value,
                  onChanged: (value) => isCorrect.value = value,
                  trackColor: kRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
