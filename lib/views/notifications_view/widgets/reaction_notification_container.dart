// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/models/event_relation.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/notifications_view/widgets/notification_event_quote.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class ReactionNotificationContainer extends StatelessWidget {
  final Event event;
  const ReactionNotificationContainer({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventRelation = EventRelation.fromEvent(event);

    return Container(
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

          return IntrinsicHeight(
            child: Row(
              children: [
                if (event.content == '+')
                  SvgPicture.asset(
                    FeatureIcons.like,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  )
                else if (event.content == '-')
                  SvgPicture.asset(
                    FeatureIcons.dislike,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  )
                else
                  Text(
                    event.content,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                VerticalDivider(
                  width: kDefaultPadding,
                  indent: kDefaultPadding / 4,
                  endIndent: kDefaultPadding / 4,
                ),
                ProfilePicture2(
                  size: 30,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              getAuthorName(author),
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
