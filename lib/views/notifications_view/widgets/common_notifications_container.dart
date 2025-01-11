import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class CommonNotificationContainer extends StatelessWidget {
  final Event event;

  const CommonNotificationContainer({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle linkStyle = TextStyle(color: Colors.redAccent);
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
      ),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
        selector: (state) => authorsCubit.getAuthor(event.pubkey),
        builder: (context, user) {
          final author = user ??
              emptyUserModel.copyWith(
                pubKey: event.pubkey,
                picturePlaceholder: getRandomPlaceholder(
                  input: event.pubkey,
                  isPfp: true,
                ),
              );

          final secondText = event.kind == EventKind.LONG_FORM
              ? 'an article'
              : event.kind == EventKind.CURATION_ARTICLES
                  ? 'a curation'
                  : event.kind == EventKind.SMART_WIDGET
                      ? 'a smart widget'
                      : (event.kind == EventKind.VIDEO_HORIZONTAL ||
                              event.kind == EventKind.VIDEO_VERTICAL)
                          ? 'a video'
                          : 'a flash news';

          late Function() func;

          Article? article;
          Curation? curation;
          SmartWidgetModel? sw;
          VideoModel? video;
          FlashNews? flash;

          DateTime publishedAt = DateTime.now();
          DateTime createdAt = DateTime.now();
          String title = '';

          if (event.kind == EventKind.LONG_FORM) {
            article = Article.fromEvent(event);
            title = article.title;
            publishedAt = article.publishedAt;
            createdAt = article.createdAt;

            func = () => Navigator.pushNamed(
                  context,
                  ArticleView.routeName,
                  arguments: article,
                );
          } else if (event.kind == EventKind.CURATION_ARTICLES) {
            curation = Curation.fromEvent(event, '');
            publishedAt = curation.publishedAt;
            createdAt = curation.createdAt;
            title = curation.title;

            func = () => Navigator.pushNamed(
                  context,
                  CurationView.routeName,
                  arguments: curation,
                );
          } else if (event.kind == EventKind.SMART_WIDGET) {
            sw = SmartWidgetModel.fromEvent(event);
            publishedAt = sw.publishedAt;
            createdAt = sw.createdAt;
            title = sw.title;

            func = () => Navigator.pushNamed(
                  context,
                  SmartWidgetChecker.routeName,
                  arguments: [
                    sw!.getNaddr(),
                    sw,
                  ],
                );
          } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
              event.kind == EventKind.VIDEO_VERTICAL) {
            video = VideoModel.fromEvent(event);
            publishedAt = video.publishedAt;
            createdAt = video.createdAt;
            title = video.title;

            func = () => Navigator.pushNamed(
                  context,
                  video!.isHorizontal
                      ? HorizontalVideoView.routeName
                      : VerticalVideoView.routeName,
                  arguments: [video],
                );
          } else if (event.kind == EventKind.TEXT_NOTE) {
            flash = FlashNews.fromEvent(event);
            publishedAt = flash.createdAt;
            createdAt = flash.createdAt;
            title = flash.content;

            func = () => Navigator.pushNamed(
                  context,
                  FlashNewsDetailsView.routeName,
                  arguments: [MainFlashNews(flashNews: flash!), true],
                );
          } else {
            func = () {};
          }

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
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: 'has published ',
                          ),
                          TextSpan(
                            text: secondText,
                            style: linkStyle,
                            recognizer: TapGestureRecognizer()..onTap = func,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
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
