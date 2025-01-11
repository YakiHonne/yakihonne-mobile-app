import 'package:flutter/material.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/bookmarks_view/widgets/add_bookmarks_list_view.dart';
import 'package:yakihonne/views/bookmarks_view/widgets/bookmarks_list_details.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_source_view.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_details.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_user_search.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/home_view/widgets/topics_view.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/points_management_view/points_management_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/properties_view/widgets/keys_view.dart';
import 'package:yakihonne/views/properties_view/widgets/mute_list_view.dart';
import 'package:yakihonne/views/properties_view/widgets/profile_image_update.dart';
import 'package:yakihonne/views/properties_view/widgets/relays_update.dart';
import 'package:yakihonne/views/properties_view/widgets/thumbnail_update.dart';
import 'package:yakihonne/views/properties_view/widgets/wallet_property.dart';
import 'package:yakihonne/views/properties_view/widgets/zaps_configurations.dart';
import 'package:yakihonne/views/rewards_view/rewards_view.dart';
import 'package:yakihonne/views/routing_view/routing_view.dart';
import 'package:yakihonne/views/self_curations_view/widgets/add_curation_articles.dart';
import 'package:yakihonne/views/self_curations_view/widgets/add_self_curation.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_explanation.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/write_article_view/write_article_view.dart';
import 'package:yakihonne/views/write_flash_news_view/write_flash_news_view.dart';
import 'package:yakihonne/views/write_smart_widget_view/write_smart_widget_view.dart';
import 'package:yakihonne/views/write_video_view/write_video_view.dart';

Route onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case RoutingView.routeName:
      return RoutingView.route();
    case WriteArticleView.routeName:
      return WriteArticleView.route(settings);
    case CurationView.routeName:
      return CurationView.route(settings);
    case ArticleView.routeName:
      return ArticleView.route(settings);
    case TagView.routeName:
      return TagView.route(settings);
    case AddSelfCurationView.routeName:
      return AddSelfCurationView.route(settings);
    case AddCurationArticlesView.routeName:
      return AddCurationArticlesView.route(settings);
    case ProfileView.routeName:
      return ProfileView.route(settings);
    case ProfileImageUpdate.routeName:
      return ProfileImageUpdate.route();
    case ThumbnailUpdate.routeName:
      return ThumbnailUpdate.route(settings);
    case WalletView.routeName:
      return WalletView.route();
    case ZapsView.routeName:
      return ZapsView.route();
    case RelayUpdateView.routeName:
      return RelayUpdateView.route(settings);
    case KeysView.routeName:
      return KeysView.route(settings);
    case TopicsView.routeName:
      return TopicsView.route(settings);
    case AddBookmarksListView.routeName:
      return AddBookmarksListView.route(settings);
    case BookmarksListDetails.routeName:
      return BookmarksListDetails.route(settings);
    case MuteListView.routeName:
      return MuteListView.route();
    case WriteFlashNewsView.routeName:
      return WriteFlashNewsView.route(settings);
    case FlashNewsDetailsView.routeName:
      return FlashNewsDetailsView.route(settings);
    case UnFlashNewsDetails.routeName:
      return UnFlashNewsDetails.route(settings);
    case NoteView.routeName:
      return NoteView.route(settings);
    case UncensoredNoteExplanation.routeName:
      return UncensoredNoteExplanation.route();
    case RewardsView.routeName:
      return RewardsView.route(settings);
    case DmDetails.routeName:
      return DmDetails.route(settings);
    case DmUserSearch.routeName:
      return DmUserSearch.route();
    case HorizontalVideoView.routeName:
      return HorizontalVideoView.route(settings);
    case VerticalVideoView.routeName:
      return VerticalVideoView.route(settings);
    case WriteVideoView.routeName:
      return WriteVideoView.route(settings);
    case BuzzFeedDetails.routeName:
      return BuzzFeedDetails.route(settings);
    case BuzzFeedSourceView.routeName:
      return BuzzFeedSourceView.route(settings);
    case PointsStatisticsView.routeName:
      return PointsStatisticsView.route(settings);
    case WriteSmartWidgetView.routeName:
      return WriteSmartWidgetView.route(settings);
    case SmartWidgetChecker.routeName:
      return SmartWidgetChecker.route(settings);

    default:
      return _errorRoute();
  }
}

Route _errorRoute() {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'error',
        ),
      ),
    ),
    settings: const RouteSettings(
      name: '/error',
    ),
  );
}
