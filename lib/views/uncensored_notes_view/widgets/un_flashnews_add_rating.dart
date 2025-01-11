// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/uncensored_notes_cubit/set_un_rating_cubit/set_un_rating_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class UnFlashNewsAddRating extends StatefulWidget {
  const UnFlashNewsAddRating({
    Key? key,
    required this.isUpvote,
    required this.uncensoredNoteId,
    required this.onSuccess,
  }) : super(key: key);

  final bool isUpvote;
  final String uncensoredNoteId;
  final Function() onSuccess;

  @override
  State<UnFlashNewsAddRating> createState() => _UnFlashNewsAddRatingState();
}

class _UnFlashNewsAddRatingState extends State<UnFlashNewsAddRating> {
  final selectionReasons = <String>[];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SetUnRatingCubit(),
      child: Container(
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
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
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
                  BlocBuilder<SetUnRatingCubit, SetUnRatingState>(
                    builder: (context, state) {
                      return TextButton.icon(
                        onPressed: () {
                          if (selectionReasons.isEmpty) {
                            BotToastUtils.showError(
                                'Select at least one reason');
                            return;
                          }

                          context.read<SetUnRatingCubit>().addRating(
                                isUpvote: widget.isUpvote,
                                uncensoredNoteId: widget.uncensoredNoteId,
                                reasons: selectionReasons,
                                onSuccess: widget.onSuccess,
                              );
                        },
                        label: SvgPicture.asset(
                          widget.isUpvote
                              ? FeatureIcons.like
                              : FeatureIcons.dislike,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorLight,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.scaleDown,
                        ),
                        icon: Text(
                          'Rate ${widget.isUpvote ? 'helpful' : 'not helpful'}',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Theme.of(context).primaryColorLight,
                                  ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorDark,
                        ),
                      );
                    },
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
                                          'Do you find this ${widget.isUpvote ? 'helpful' : 'not helpful'}?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!,
                                        ),
                                        Text(
                                          'Set your rating',
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
                height: kDefaultPadding,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What do you think that?',
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    if (widget.isUpvote)
                      ListView(
                        shrinkWrap: true,
                        primary: false,
                        padding: EdgeInsets.zero,
                        children: helpfulRatingPoints
                            .map(
                              (e) => RatingTile(
                                title: e,
                                isSelected: selectionReasons.contains(e),
                                onClicked: () {
                                  setState(() {
                                    if (selectionReasons.contains(e)) {
                                      selectionReasons.remove(e);
                                    } else {
                                      selectionReasons.add(e);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      )
                    else
                      ListView(
                        shrinkWrap: true,
                        primary: false,
                        padding: EdgeInsets.zero,
                        children: notHelpfulRatingPoints
                            .map(
                              (e) => RatingTile(
                                title: e,
                                isSelected: selectionReasons.contains(e),
                                onClicked: () {
                                  setState(
                                    () {
                                      if (selectionReasons.contains(e)) {
                                        selectionReasons.remove(e);
                                      } else {
                                        selectionReasons.add(e);
                                      }
                                    },
                                  );
                                },
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: Theme.of(context).primaryColorLight,
                ),
                padding: const EdgeInsets.all(kDefaultPadding),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.labelMedium,
                    children: [
                      TextSpan(
                        text: 'Note: ',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: kRed,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      TextSpan(
                          text:
                              'changing your rating will only be valid for 5 minutes, after that you will no longer have the option to undo or change it.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingTile extends StatelessWidget {
  const RatingTile({
    Key? key,
    required this.title,
    required this.isSelected,
    required this.onClicked,
  }) : super(key: key);

  final String title;
  final bool isSelected;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).primaryColorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
      ),
      leading: Checkbox(
        value: isSelected,
        onChanged: (value) {
          onClicked.call();
        },
        side: BorderSide(
          color: Theme.of(context).primaryColorDark,
          width: 1.5,
        ),
        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
        activeColor: kPurple,
        checkColor: kWhite,
      ),
      dense: true,
      title: Text(
        title,
      ),
      onTap: onClicked,
    );
  }
}
