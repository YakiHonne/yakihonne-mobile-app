import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/event_relation.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';

class NotificationEventQuote extends StatefulWidget {
  final EventRelation eventRelation;
  const NotificationEventQuote({
    Key? key,
    required this.eventRelation,
  }) : super(key: key);

  @override
  State<NotificationEventQuote> createState() => _NotificationEventQuoteState();
}

class _NotificationEventQuoteState extends State<NotificationEventQuote> {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<SingleEventCubit, SingleEventState, Event?>(
      selector: (state) => widget.eventRelation.replyId == null &&
              widget.eventRelation.rootId == null &&
              widget.eventRelation.rRootId == null
          ? null
          : singleEventCubit.getEvent(
              widget.eventRelation.replyId != null
                  ? widget.eventRelation.replyId!
                  : widget.eventRelation.rootId != null
                      ? widget.eventRelation.rootId!
                      : widget.eventRelation.rRootId!,
              widget.eventRelation.rootId == null &&
                  widget.eventRelation.replyId == null,
            ),
      builder: (context, event) {
        return NotificationEventMain(
          event: event,
          mainEvent: widget.eventRelation,
        );
      },
      bloc: singleEventCubit,
    );
  }
}

class NotificationEventMain extends StatelessWidget {
  const NotificationEventMain({
    Key? key,
    required this.event,
    required this.mainEvent,
  }) : super(key: key);

  final Event? event;
  final EventRelation mainEvent;

  @override
  Widget build(BuildContext context) {
    return getWidget(event, mainEvent, context);
  }

  Widget getWidget(
    Event? event,
    EventRelation mainEvent,
    BuildContext context,
  ) {
    final isAuthor =
        event != null && event.pubkey == nostrRepository.usm!.pubKey;

    if (mainEvent.kind == EventKind.ZAP) {
      List<InlineSpan> spans = [];

      if (event != null) {
        spans = getSpans(event, isAuthor, context);
      } else {
        spans.add(TextSpan(text: 'has zapped you'));
      }

      return RichText(
        text: TextSpan(
          children: spans,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } else if (mainEvent.kind == EventKind.REACTION) {
      List<InlineSpan> spans = [];

      if (event != null) {
        spans = getSpans(event, isAuthor, context);
      } else {
        spans.add(TextSpan(text: 'has reacted to you'));
      }

      return RichText(
        text: TextSpan(
          children: spans,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } else if (mainEvent.kind == EventKind.TEXT_NOTE ||
        mainEvent.kind == EventKind.LONG_FORM ||
        mainEvent.kind == EventKind.CURATION_ARTICLES) {
      List<InlineSpan> spans = [];

      if (event != null) {
        spans = getSpans(event, isAuthor, context);
      } else {
        spans.add(TextSpan(text: 'has mentioned you'));
      }

      return RichText(
        text: TextSpan(
          children: spans,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  List<InlineSpan> getSpans(
    Event event,
    bool isAuthor,
    BuildContext context,
  ) {
    TextStyle linkStyle = TextStyle(color: Colors.redAccent);
    late Function() func;
    List<InlineSpan> spans = [];

    if (event.kind == EventKind.LONG_FORM) {
      final article = Article.fromEvent(event);

      func = () => Navigator.pushNamed(
            context,
            ArticleView.routeName,
            arguments: article,
          );
    } else if (event.kind == EventKind.CURATION_ARTICLES) {
      final curation = Curation.fromEvent(event, '');

      func = () => Navigator.pushNamed(
            context,
            CurationView.routeName,
            arguments: curation,
          );
    } else if (event.kind == EventKind.SMART_WIDGET) {
      final sw = SmartWidgetModel.fromEvent(event);

      func = () => Navigator.pushNamed(
            context,
            SmartWidgetChecker.routeName,
            arguments: [
              sw.getNaddr(),
              sw,
            ],
          );
    } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
        event.kind == EventKind.VIDEO_VERTICAL) {
      final video = VideoModel.fromEvent(event);

      func = () => Navigator.pushNamed(
            context,
            video.isHorizontal
                ? HorizontalVideoView.routeName
                : VerticalVideoView.routeName,
            arguments: [video],
          );
    } else if (event.kind == EventKind.TEXT_NOTE) {
      if (event.isFlashNews()) {
        final flash = FlashNews.fromEvent(event);

        func = () => Navigator.pushNamed(
              context,
              FlashNewsDetailsView.routeName,
              arguments: [MainFlashNews(flashNews: flash), true],
            );
      } else {
        func = () => Navigator.pushNamed(
              context,
              NoteView.routeName,
              arguments: DetailedNoteModel.fromEvent(event),
            );
      }
    } else {
      func = () {};
    }

    if (event.kind != EventKind.LONG_FORM &&
        event.kind != EventKind.SMART_WIDGET &&
        event.kind != EventKind.REACTION &&
        event.kind != EventKind.CURATION_ARTICLES &&
        event.kind != EventKind.DIRECT_MESSAGE &&
        event.kind != EventKind.APP_CUSTOM &&
        event.kind != EventKind.VIDEO_HORIZONTAL &&
        event.kind != EventKind.VIDEO_VERTICAL &&
        event.kind != EventKind.POLL &&
        event.kind != EventKind.TEXT_NOTE) {
      spans.add(TextSpan(text: 'undefined'));
    } else {
      final containsAuthorTag = mainEvent.origin.content.contains(
        Nip19.encodePubkey(nostrRepository.usm!.pubKey),
      );

      final firstText = mainEvent.kind == EventKind.ZAP
          ? 'zapped'
          : mainEvent.kind == EventKind.REACTION
              ? 'reacted to'
              : isAuthor
                  ? mainEvent.isUncensoredNote()
                      ? 'published an uncensored note for'
                      : containsAuthorTag
                          ? 'mentioned you in'
                          : 'commented on'
                  : 'replied to';

      final secondText = event.kind == EventKind.LONG_FORM
          ? 'article'
          : event.kind == EventKind.CURATION_ARTICLES
              ? 'curation'
              : event.kind == EventKind.SMART_WIDGET
                  ? 'smart widget'
                  : event.kind == EventKind.REACTION
                      ? 'reaction'
                      : event.kind == EventKind.APP_CUSTOM
                          ? 'Sealed'
                          : (event.kind == EventKind.VIDEO_HORIZONTAL ||
                                  event.kind == EventKind.VIDEO_VERTICAL)
                              ? 'video'
                              : event.kind == EventKind.DIRECT_MESSAGE
                                  ? 'message'
                                  : event.kind == EventKind.TEXT_NOTE &&
                                          event.isFlashNews()
                                      ? 'flash news'
                                      : event.kind == EventKind.TEXT_NOTE &&
                                              event.isUncensoredNote()
                                          ? 'uncensored note'
                                          : event.kind == EventKind.POLL
                                              ? 'poll'
                                              : 'note';

      if (isAuthor) {
        spans = [
          TextSpan(text: 'has $firstText your '),
          TextSpan(
            text: secondText,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = func,
          ),
        ];
      } else {
        spans = [
          TextSpan(text: 'has $firstText a '),
          TextSpan(
            text: secondText,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = func,
          ),
          TextSpan(text: ' you were tagged in'),
        ];
      }
    }

    return spans;
  }
}
