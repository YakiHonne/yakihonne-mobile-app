import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'tag_state.dart';

class TagCubit extends Cubit<TagState> {
  TagCubit({
    required String tag,
    required this.nostrRepository,
  }) : super(
          TagState(
            tag: tag,
            articles: [],
            flashNews: [],
            videos: [],
            notes: [],
            tagType: TagType.article,
            isArticleLoading: true,
            isFlashNewsLoading: true,
            isVideosLoading: true,
            isNotesLoading: true,
            mutes: nostrRepository.mutes,
            followings: nostrRepository.usm != null
                ? nostrRepository.user.followings.map((e) => e.key).toList()
                : [],
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            loadingBookmarks: nostrRepository.loadingBookmarks.keys.toSet(),
            userStatus: getUserStatus(),
            isSubscribed: nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                List<String>.from(nostrRepository.userTopics)
                    .toLowerCaseTrim()
                    .contains(
                      tag.toLowerCase().trim(),
                    ),
          ),
        ) {
    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            ),
          );
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              articles: state.articles
                  .where((article) => !mutes.contains(article.pubkey))
                  .toList(),
              flashNews: state.flashNews
                  .where((flashNews) => !mutes.contains(flashNews.pubkey))
                  .toList(),
            ),
          );
      },
    );

    loadingBookmarksSubscription =
        nostrRepository.loadingBookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getLoadingBookmarkIds(bookmarks).toSet(),
            ),
          );
      },
    );

    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        if (!isClosed)
          emit(
            state.copyWith(
              followings: followings,
            ),
          );
      },
    );

    userTopicsSubscription = nostrRepository.userTopicsStream.listen(
      (topics) {
        if (!isClosed)
          emit(
            state.copyWith(
              isSubscribed: topics.contains(tag),
            ),
          );
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription loadingBookmarksSubscription;
  late StreamSubscription followingsSubscription;
  late StreamSubscription userTopicsSubscription;
  late StreamSubscription muteListSubscription;
  Set<String> requests = {};

  void setSelection(TagType tagType) {
    emit(
      state.copyWith(
        tagType: tagType,
      ),
    );
  }

  void getTagData() {
    NostrFunctionsRepository.getTagData(
      tag: state.tag,
      onArticles: (articles) {
        if (!isClosed)
          emit(
            state.copyWith(
              articles: articles,
              isArticleLoading: false,
            ),
          );
      },
      onVideos: (videos) {
        if (!isClosed)
          emit(
            state.copyWith(
              videos: videos,
              isVideosLoading: false,
            ),
          );
      },
      onFlashNews: (flashNews) {
        if (!isClosed)
          emit(
            state.copyWith(
              flashNews: flashNews,
              isFlashNewsLoading: false,
            ),
          );
      },
      onNotes: (notes) {
        if (!isClosed)
          emit(
            state.copyWith(
              notes: notes,
              isNotesLoading: false,
            ),
          );
      },
      onDone: () {
        if (!isClosed)
          emit(
            state.copyWith(
              isArticleLoading: false,
              isVideosLoading: false,
              isFlashNewsLoading: false,
              isNotesLoading: false,
            ),
          );
      },
    );
  }

  void setCustomTags() async {
    final _cancel = BotToast.showLoading();

    List<String> currentTopics =
        List<String>.from(nostrRepository.userTopics).toLowerCaseTrim();

    if (currentTopics.contains(state.tag.trim())) {
      currentTopics.remove(state.tag.trim());
    } else {
      currentTopics.add(state.tag);
    }

    final event = await Event.genEvent(
      kind: EventKind.APP_CUSTOM,
      tags: [
        ['d', yakihonneTopicTag],
        ...currentTopics.map((e) => ['t', e]).toList(),
      ],
      content: '',
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
    );

    if (event == null) {
      _cancel.call();
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.addEvent(event: event);

    if (isSuccessful) {
      nostrRepository.setTopics(currentTopics);
      BotToastUtils.showSuccess('Your topics have been updated');
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  @override
  Future<void> close() {
    bookmarksSubscription.cancel();
    loadingBookmarksSubscription.cancel();
    followingsSubscription.cancel();
    muteListSubscription.cancel();
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    return super.close();
  }
}
