// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/self_smart_widgets_view/widgets/self_smart_widget_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

import '../../nostr/nips/nips.dart';

SpanNodeGeneratorWithTag nostrGenerator = SpanNodeGeneratorWithTag(
  tag: _nostrTag,
  generator: (e, config, visitor) => nostrNode(
    e.attributes,
    e.textContent,
    config,
  ),
);

const _nostrTag = 'nostr';

class nostrSyntax extends m.InlineSyntax {
  nostrSyntax()
      : super(
          r'@?(nostr:)?@?(npub1|nevent1|naddr1|note1|nprofile1|nrelay1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
          caseSensitive: false,
        );

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final input = match.input.toLowerCase();

    final matchValue = input.substring(match.start, match.end);
    String content = '';

    const initial = 'nostr:';

    if (matchValue.startsWith(initial)) {
      content = matchValue.substring(6, matchValue.length);
    } else {
      content = matchValue;
    }

    m.Element el = m.Element.text(_nostrTag, matchValue);
    el.attributes['content'] = content;

    parser.addNode(el);
    return true;
  }
}

class nostrNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  nostrNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final map = getMap(content);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: getView(nostrDecode: map),
    );
  }

  Map<String, dynamic> getMap(String content) {
    try {
      RegExpMatch? selectedMatch = Nip19.nip19regex.firstMatch(content);
      var key = selectedMatch!.group(2)! + selectedMatch.group(3)!;
      Map<String, dynamic> map = {};

      if (selectedMatch.group(2) == 'npub1') {
        map['prefix'] = 'npub';
        map['special'] = Nip19.decodePubkey(key);
      } else if (selectedMatch.group(2) == 'note1') {
        map['prefix'] = 'note';
        map['special'] = Nip19.decodeNote(key);
      } else {
        map = Nip19.decodeShareableEntity(key);
      }

      return map;
    } catch (_) {
      return {};
    }
  }

  Widget getView({
    required Map<String, dynamic> nostrDecode,
  }) {
    if (nostrDecode['prefix'] == 'nprofile' ||
        nostrDecode['prefix'] == 'npub') {
      if (nostrDecode['special'] == '') {
        return RegularText(text: attributes['content'] ?? '');
      } else {
        return ArticleNprofile(
          pubkey: nostrDecode['special'],
        );
      }
    } else if (nostrDecode['prefix'] == 'note' ||
        nostrDecode['prefix'] == 'nevent') {
      return ArticleNote(
        noteId: nostrDecode['special'],
      );
    } else if (nostrDecode['prefix'] == 'naddr' &&
        nostrDecode['kind'] == EventKind.LONG_FORM) {
      final hexCode = hex.decode(nostrDecode['special']);
      final id = String.fromCharCodes(hexCode);

      return NaddrArticleContainer(
        eventId: id,
        pubkey: nostrDecode['author'],
        naddrType: ArticleNaddrTypes.article,
      );
    } else if (nostrDecode['prefix'] == 'naddr' &&
        nostrDecode['kind'] == EventKind.CURATION_ARTICLES) {
      final hexCode = hex.decode(nostrDecode['special']);
      final id = String.fromCharCodes(hexCode);

      return NaddrArticleContainer(
        eventId: id,
        pubkey: nostrDecode['author'],
        naddrType: ArticleNaddrTypes.curation,
      );
    } else if (nostrDecode['prefix'] == 'naddr' &&
        nostrDecode['kind'] == EventKind.SMART_WIDGET) {
      final hexCode = hex.decode(nostrDecode['special']);
      final id = String.fromCharCodes(hexCode);

      return NaddrArticleContainer(
        eventId: id,
        pubkey: nostrDecode['author'],
        naddrType: ArticleNaddrTypes.smart,
      );
    } else {
      return RegularText(text: attributes['content'] ?? '');
    }
  }
}

class RegularText extends StatelessWidget {
  final String text;

  const RegularText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class ArticleNprofile extends StatelessWidget {
  ArticleNprofile({
    Key? key,
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
      selector: (state) => authorsCubit.getAuthor(pubkey),
      builder: (context, author) {
        final user = author ??
            emptyUserModel.copyWith(
              pubKey: pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: pubkey, isPfp: true),
            );

        return Center(
          child: ArticleUserMention(
            author: user,
            onClicked: () => Navigator.pushNamed(
              context,
              ProfileView.routeName,
              arguments: user.pubKey,
            ),
          ),
        );
      },
    );
  }
}

class ArticleUserMention extends StatelessWidget {
  const ArticleUserMention({
    Key? key,
    required this.author,
    required this.onClicked,
  }) : super(key: key);

  final UserModel author;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).primaryColorLight,
        ),
        margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: Row(
          children: [
            ProfilePicture2(
              image: author.picture,
              placeHolder: author.picturePlaceholder,
              size: 30,
              padding: 3,
              strokeWidth: 1,
              strokeColor: Theme.of(context).primaryColorDark,
              onClicked: () {
                openProfileFastAccess(context: context, pubkey: author.pubKey);
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name.trim().isNotEmpty
                        ? author.name
                        : Nip19.encodePubkey(author.pubKey).nineCharacters(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (author.about.isNotEmpty)
                    Text(
                      author.about,
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
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            PubKeyContainer(pubKey: author.pubKey),
          ],
        ),
      ),
    );
  }
}

class NaddrArticleContainer extends StatelessWidget {
  const NaddrArticleContainer({
    Key? key,
    required this.pubkey,
    required this.eventId,
    required this.naddrType,
  }) : super(key: key);

  final String pubkey;
  final String eventId;
  final ArticleNaddrTypes naddrType;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
      selector: (state) => authorsCubit.getAuthor(pubkey),
      builder: (context, author) {
        return BlocSelector<SingleEventCubit, SingleEventState, Event?>(
          selector: (state) => singleEventCubit.getEvent(eventId, true),
          builder: (context, event) {
            final user = author ??
                emptyUserModel.copyWith(
                  pubKey: pubkey,
                  picturePlaceholder:
                      getRandomPlaceholder(input: pubkey, isPfp: true),
                );

            final component = event != null
                ? naddrType == ArticleNaddrTypes.article
                    ? Article.fromEvent(event)
                    : naddrType == ArticleNaddrTypes.curation
                        ? Curation.fromEvent(event, '')
                        : SmartWidgetModel.fromEvent(event)
                : null;

            if (component == null) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: Theme.of(context).primaryColorLight,
                ),
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'This is ${naddrType == ArticleNaddrTypes.article ? 'an article' : naddrType == ArticleNaddrTypes.article ? 'a curation' : 'a smart widget'} event',
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'By: ',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                ProfileView.routeName,
                                arguments: user.pubKey,
                              );
                            },
                            child: Text(
                              getAuthorName(user),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                    color: kOrange,
                                  ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }

            final sm = (component as SmartWidgetModel);

            if (naddrType == ArticleNaddrTypes.smart) {
              return sm.container != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      child: SmartWidget(
                        smartWidgetContainer: sm.container!,
                      ),
                    )
                  : NoSmartWidgetContainer(
                      backgroundColor: Theme.of(context).primaryColorLight,
                    );
            } else {
              DateTime createdAt;
              DateTime publishedAt;
              String title;
              String about;
              String backgroundImage;
              String placeHolder;

              if (naddrType == ArticleNaddrTypes.article) {
                final article = (component as Article);
                createdAt = article.createdAt;
                publishedAt = article.publishedAt;
                title = article.title;
                about = article.summary;
                backgroundImage = article.image;
                placeHolder = article.placeholder;
              } else {
                final curation = (component as Curation);
                createdAt = curation.createdAt;
                publishedAt = curation.publishedAt;
                title = curation.title;
                about = curation.description;
                backgroundImage = curation.image;
                placeHolder = curation.placeHolder;
              }

              return GestureDetector(
                onTap: () {
                  if (naddrType == ArticleNaddrTypes.article) {
                    Navigator.pushNamed(
                      context,
                      ArticleView.routeName,
                      arguments: component as Article,
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      CurationView.routeName,
                      arguments: component as Curation,
                    );
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding + 5),
                    color: Theme.of(context).primaryColorLight,
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: kDefaultPadding,
                            ),
                            foregroundDecoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColorLight,
                                  kTransparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: [
                                  0.1,
                                  0.5,
                                ],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(kDefaultPadding),
                                topRight: Radius.circular(kDefaultPadding),
                              ),
                              child: ArticleThumbnail(
                                image: backgroundImage,
                                placeholder: placeHolder,
                                width: double.infinity,
                                height: 70,
                                radius: 0,
                                isRound: false,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: kDefaultPadding / 2,
                                ),
                                child: ProfilePicture2(
                                  size: 60,
                                  image: user.picture,
                                  placeHolder: user.picturePlaceholder,
                                  padding: 0,
                                  strokeWidth: 3,
                                  strokeColor:
                                      Theme.of(context).primaryColorLight,
                                  onClicked: () {},
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: kDefaultPadding / 2,
                                  top: kDefaultPadding / 2,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColorLight,
                                    borderRadius: BorderRadius.circular(
                                      kDefaultPadding / 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 4,
                                    horizontal: kDefaultPadding / 2,
                                  ),
                                  child: Text(
                                    naddrType == ArticleNaddrTypes.article
                                        ? 'Article'
                                        : 'Curation',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: kOrange,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: kDefaultPadding / 2,
                                ),
                                child: Text(
                                  getAuthorName(user),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kDefaultPadding,
                          right: kDefaultPadding,
                          bottom: kDefaultPadding,
                          top: kDefaultPadding / 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.about.isNotEmpty) ...[
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                              Text(
                                about,
                                style: Theme.of(context).textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                              PublishDateRow(
                                createdAtDate: createdAt,
                                publishedAtDate: publishedAt,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class ArticleNote extends StatelessWidget {
  ArticleNote({
    Key? key,
    required this.noteId,
  });

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SingleEventCubit, SingleEventState, Event?>(
      selector: (state) => singleEventCubit.getEvent(noteId, false),
      builder: (context, event) {
        final note = event != null ? DetailedNoteModel.fromEvent(event) : null;

        if (note == null) {
          return Text(Nip19.encodeNote(noteId));
        }

        return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
          selector: (state) => authorsCubit.getAuthor(note.pubkey),
          builder: (context, author) {
            final user = author ??
                emptyUserModel.copyWith(
                  pubKey: '',
                  picturePlaceholder:
                      getRandomPlaceholder(input: noteId, isPfp: true),
                );

            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 2,
                ),
                margin:
                    const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: Theme.of(context).primaryColorLight,
                ),
                child: getView(
                  note: note,
                  author: user,
                  context: context,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget getView({
    required BuildContext context,
    required DetailedNoteModel note,
    required UserModel author,
  }) {
    final noteRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfilePicture2(
          image: author.picture,
          placeHolder: author.picturePlaceholder,
          size: 35,
          padding: 3,
          strokeWidth: 1,
          strokeColor: Theme.of(context).primaryColorDark,
          onClicked: () {
            openProfileFastAccess(context: context, pubkey: author.pubKey);
          },
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.name.trim().isNotEmpty
                    ? author.name
                    : Nip19.encodePubkey(author.pubKey).nineCharacters(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${dateFormat3.format(note.createdAt)}',
                style: Theme.of(context).textTheme.labelSmall!,
              ),
              Divider(
                height: kDefaultPadding,
              ),
              linkifiedText(context: context, text: note.content),
            ],
          ),
        ),
      ],
    );

    return noteRow;
  }
}
