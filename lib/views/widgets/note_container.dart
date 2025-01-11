// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class NoteContainer extends StatelessWidget {
  NoteContainer({
    Key? key,
    required this.note,
    this.inverseNoteColor,
    this.vMargin,
    this.hMargin,
  }) : super(key: key);

  final DetailedNoteModel note;
  final bool? inverseNoteColor;
  final double? vMargin;
  final double? hMargin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NoteView.routeName,
          arguments: note,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        margin: EdgeInsets.symmetric(
          vertical: vMargin ?? 0,
          horizontal: hMargin ?? 0,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: inverseNoteColor != null
              ? Theme.of(context).scaffoldBackgroundColor
              : Theme.of(context).primaryColorLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileInfoHeader(
              createdAt: note.createdAt,
              pubkey: note.pubkey,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            linkifiedText(
              context: context,
              text: note.content,
              disableVisualParsing: true,
              isKeepAlive: true,
              onClicked: () {
                Navigator.pushNamed(
                  context,
                  NoteView.routeName,
                  arguments: note,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GlobalNoteContainer extends StatelessWidget {
  GlobalNoteContainer({
    Key? key,
    required this.note,
    this.vMargin,
    this.hMargin,
  }) : super(key: key);

  final DetailedNoteModel note;
  final double? vMargin;
  final double? hMargin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NoteView.routeName,
          arguments: note,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        margin: EdgeInsets.symmetric(
          vertical: vMargin ?? 0,
          horizontal: hMargin ?? 0,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileInfoHeader(
              createdAt: note.createdAt,
              pubkey: note.pubkey,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            linkifiedText(
              context: context,
              text: note.content,
              inverseNoteColor: true,
              isKeepAlive: true,
              onClicked: () {
                Navigator.pushNamed(
                  context,
                  NoteView.routeName,
                  arguments: note,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoHeader extends StatelessWidget {
  const ProfileInfoHeader({
    super.key,
    required this.pubkey,
    required this.createdAt,
  });

  final String pubkey;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
      selector: (state) => authorsCubit.getAuthor(pubkey),
      builder: (context, user) {
        final author = user ??
            emptyUserModel.copyWith(
              pubKey: pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: pubkey, isPfp: true),
            );

        return Row(
          children: [
            ProfilePicture2(
              image: author.picture,
              placeHolder: author.picturePlaceholder,
              size: 20,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: author.pubKey,
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      getAuthorName(author),
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  BlocBuilder<AuthorsCubit, AuthorsState>(
                    builder: (context, state) {
                      if (state.nip05Validations[author.pubKey] ?? false) {
                        return Flexible(
                          child: Text(
                            ' @${getAuthorName(author)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: kRed),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                  DotContainer(
                    color: Theme.of(context).primaryColorDark,
                    size: 3,
                  ),
                  Text(
                    StringUtil.getLastDate(createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: kDimGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
