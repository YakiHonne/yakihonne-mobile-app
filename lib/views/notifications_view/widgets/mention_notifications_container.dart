// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/event_relation.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/notifications_view/widgets/notification_event_quote.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class MentionNotificationContainer extends StatelessWidget {
  final Event event;
  const MentionNotificationContainer({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventRelation = EventRelation.fromEvent(event);

    return GestureDetector(
      onTap: () {
        if (event.isSimpleNote() && event.isUserTagged()) {
          Navigator.pushNamed(
            context,
            NoteView.routeName,
            arguments: DetailedNoteModel.fromEvent(event),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).primaryColorLight,
        ),
        margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: BlocBuilder<AuthorsCubit, AuthorsState>(
          builder: (context, state) {
            final author = state.authors[event.pubkey] ??
                emptyUserModel.copyWith(
                  pubKey: event.pubkey,
                  picturePlaceholder: getRandomPlaceholder(
                    input: event.pubkey,
                    isPfp: true,
                  ),
                );

            DateTime createdAt =
                DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
            DateTime publishedAt = event.getPublishedAt();
            final isUncensoredNote = eventRelation.isUncensoredNote();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfilePicture2(
                  size: 30,
                  image: isUncensoredNote ? '' : author.picture,
                  placeHolder: author.picturePlaceholder,
                  padding: 0,
                  strokeWidth: 1,
                  reduceSize: true,
                  strokeColor: kWhite,
                  onClicked: () {
                    if (!eventRelation.isUncensoredNote())
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isUncensoredNote
                                  ? 'unknown'
                                  : getAuthorName(author),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DotContainer(
                            color: kDimGrey,
                            size: 4,
                          ),
                          PublishDateRow(
                            publishedAtDate: publishedAt,
                            createdAtDate: createdAt,
                          ),
                        ],
                      ),
                      NotificationEventQuote(eventRelation: eventRelation),
                      Divider(),
                      Builder(builder: (context) {
                        String text = '';
                        if (event.kind == EventKind.APP_CUSTOM) {
                          final isAuthor = event.tags
                              .where((element) =>
                                  element.first == 'author' &&
                                  element[1] == nostrRepository.usm!.pubKey)
                              .toList()
                              .isNotEmpty;
                          text = isAuthor
                              ? 'Your uncensored note has been sealed.'
                              : 'An uncensored note you have rated has been sealed.';
                        } else {
                          text = event.content;
                        }

                        return linkifiedText(
                          context: context,
                          text: getCommentWithoutPrefix(text),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
