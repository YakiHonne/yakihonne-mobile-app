// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numeral/numeral.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/models/event_relation.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/notifications_view/widgets/notification_event_quote.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class ZapNotificationContainer extends StatefulWidget {
  final Event event;

  const ZapNotificationContainer({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<ZapNotificationContainer> createState() =>
      _ZapNotificationContainerState();
}

class _ZapNotificationContainerState extends State<ZapNotificationContainer> {
  late String senderPubkey;
  late String content;
  late String eventId;

  @override
  void initState() {
    super.initState();
    final result = getZapPubkey(widget.event.tags);
    senderPubkey = result.first;
    content = result.last;
  }

  @override
  Widget build(BuildContext context) {
    if (StringUtil.isBlank(senderPubkey)) {
      return SizedBox.shrink();
    }

    final eventRelation = EventRelation.fromEvent(widget.event);
    var zapNum = getZapValue(widget.event);

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
      ),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: BlocBuilder<AuthorsCubit, AuthorsState>(
        builder: (context, state) {
          final author = state.authors[senderPubkey] ??
              emptyUserModel.copyWith(
                pubKey: senderPubkey,
                picturePlaceholder: getRandomPlaceholder(
                  input: senderPubkey,
                  isPfp: true,
                ),
              );

          DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(
              widget.event.createdAt * 1000);
          DateTime publishedAt = widget.event.getPublishedAt();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicHeight(
                      child: Row(
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
                          VerticalDivider(),
                          Text(
                            '${Numeral(zapNum)} sats ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: kOrange,
                                ),
                          ),
                        ],
                      ),
                    ),
                    NotificationEventQuote(eventRelation: eventRelation),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    if (content.isNotEmpty) ...[
                      Divider(),
                      Text(
                        'Message',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: kOrange,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 8,
                      ),
                      Container(
                        padding: const EdgeInsets.all(kDefaultPadding / 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius:
                              BorderRadius.circular(kDefaultPadding / 2),
                        ),
                        child: Text(
                          content.trim().capitalize(),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      )
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
