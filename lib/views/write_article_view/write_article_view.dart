import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/write_article_cubit/write_article_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/content_zap_splits.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_content.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_details.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_selected_relays.dart';
import 'package:yakihonne/views/write_article_view/widgets/responding_relays_view.dart';

class WriteArticleView extends HookWidget {
  WriteArticleView({
    required this.mainCubit,
    required this.article,
    super.key,
  }) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'Write article screen');
  }

  static const routeName = '/writeArticle';
  static Route route(RouteSettings settings) {
    final list = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => WriteArticleView(
        mainCubit: list[0],
        article: list.length > 1 ? list[1] : null,
      ),
    );
  }

  final MainCubit mainCubit;
  final Article? article;
  late final WriteArticleCubit writeArticleCubit;

  @override
  Widget build(BuildContext context) {
    final toggleArticleContent = useState(true);

    useMemoized(() async {
      writeArticleCubit = WriteArticleCubit(
        nostrRepository: nostrRepository,
        article: article,
      );

      if (article == null && nostrRepository.articleAutoSave.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 500));

        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: writeArticleCubit,
            child: CupertinoAlertDialog(
              actions: [
                TextButton(
                  onPressed: () {
                    writeArticleCubit.loadArticleAutoSaveModel();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                  child: Text(
                    'load',
                    style: TextStyle(
                      color: kGreen,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    writeArticleCubit.deleteArticleAutoSaveModel();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'delete',
                    style: TextStyle(
                      color: kRed,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'cancel',
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                ),
              ],
              title: Text(
                'Unsaved article content!',
                style: TextStyle(
                  height: 1.5,
                ),
              ),
              content: Text(
                "It seems that you made some progress on writing an article and you didn't save, do you wish to load the auto-saved article and proceed?",
              ),
            ),
          ),
        );
      }
    });

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: mainCubit,
        ),
        BlocProvider.value(
          value: writeArticleCubit,
        ),
      ],
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<WriteArticleCubit, WriteArticleState>(
            builder: (context, state) {
              final title = state.articlePublishSteps ==
                      ArticlePublishSteps.content
                  ? 'Article content'
                  : state.articlePublishSteps == ArticlePublishSteps.details
                      ? 'Publish your article'
                      : state.articlePublishSteps == ArticlePublishSteps.zaps
                          ? 'Set your zaps'
                          : 'Select your relays';
              final desc = state.articlePublishSteps ==
                      ArticlePublishSteps.content
                  ? 'write down your thoughts'
                  : state.articlePublishSteps == ArticlePublishSteps.details
                      ? "let's finish the job"
                      : state.articlePublishSteps == ArticlePublishSteps.zaps
                          ? 'Share your zaps with users'
                          : 'list of available relays';

              return AppBar(
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                  ),
                ),
                title: Column(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      desc,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                  ],
                ),
                actions: [
                  if (state.articlePublishSteps ==
                      ArticlePublishSteps.content) ...[
                    BorderedIconButton(
                      firstSelection: toggleArticleContent.value,
                      onClicked: () {
                        toggleArticleContent.value =
                            !toggleArticleContent.value;
                      },
                      primaryIcon: FeatureIcons.visible,
                      secondaryIcon: FeatureIcons.notVisible,
                      borderColor: Theme.of(context).primaryColor,
                      size: 35,
                    ),
                    const SizedBox(
                      width: kDefaultPadding - 5,
                    ),
                  ]
                ],
                centerTitle: true,
              );
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<WriteArticleCubit, WriteArticleState>(
          builder: (context, state) {
            final step =
                state.articlePublishSteps == ArticlePublishSteps.content
                    ? 1
                    : state.articlePublishSteps == ArticlePublishSteps.details
                        ? 2
                        : state.articlePublishSteps == ArticlePublishSteps.zaps
                            ? 3
                            : 4;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 2,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: step / 4,
                    ),
                    builder: (context, value, _) =>
                        LinearProgressIndicator(value: value),
                  ),
                ),
                Container(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                  padding: EdgeInsets.only(
                    left: kDefaultPadding,
                    right: kDefaultPadding,
                    bottom: MediaQuery.of(context).padding.bottom / 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedOpacity(
                        opacity: state.articlePublishSteps ==
                                    ArticlePublishSteps.content ||
                                (state.articlePublishSteps ==
                                        ArticlePublishSteps.publish &&
                                    !state.forwardedAsDraft)
                            ? 1
                            : 0,
                        duration: const Duration(milliseconds: 300),
                        child: StatusButton(
                          isDisabled:
                              state.title.isEmpty || state.content.isEmpty,
                          onClicked: () {
                            if (state.articlePublishSteps ==
                                ArticlePublishSteps.content) {
                              context.read<WriteArticleCubit>().setFinalStep();
                            } else {
                              context.read<WriteArticleCubit>().setArticle(
                                    isDraft: true,
                                    onFailure: (message) {
                                      singleSnackBar(
                                        context: context,
                                        message: message,
                                        color: kRed,
                                        backGroundColor: kRedSide,
                                        icon: ToastsIcons.error,
                                      );
                                    },
                                    onSuccess:
                                        (successfulRelays, unsuccessfulRelays) {
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          opaque: false,
                                          pageBuilder:
                                              (BuildContext _, __, ___) =>
                                                  BlocProvider.value(
                                            value: context.read<MainCubit>(),
                                            child: RespondingRelaysView(
                                              successfulRelays:
                                                  successfulRelays,
                                              unsuccessfulRelays:
                                                  unsuccessfulRelays,
                                              index: 4,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                            }
                          },
                          text: 'Save as draft',
                        ),
                      ),
                      Spacer(),
                      Visibility(
                        visible: state.articlePublishSteps !=
                            ArticlePublishSteps.content,
                        child: IconButton(
                          onPressed: () {
                            context
                                .read<WriteArticleCubit>()
                                .setArticleStep(false);
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_left_rounded,
                            color: kWhite,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: kPurple,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      StatusButton(
                        isDisabled:
                            state.title.isEmpty || state.content.isEmpty,
                        onClicked: () {
                          if (state.articlePublishSteps ==
                              ArticlePublishSteps.publish) {
                            context.read<WriteArticleCubit>().setArticle(
                                  isDraft: state.forwardedAsDraft,
                                  onFailure: (message) {
                                    singleSnackBar(
                                      context: context,
                                      message: message,
                                      color: kRed,
                                      backGroundColor: kRedSide,
                                      icon: ToastsIcons.error,
                                    );
                                  },
                                  onSuccess:
                                      (successfulRelays, unsuccessfulRelays) {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        pageBuilder:
                                            (BuildContext _, __, ___) =>
                                                BlocProvider.value(
                                          value: context.read<MainCubit>(),
                                          child: RespondingRelaysView(
                                            successfulRelays: successfulRelays,
                                            unsuccessfulRelays:
                                                unsuccessfulRelays,
                                            index: 4,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                          } else {
                            context
                                .read<WriteArticleCubit>()
                                .setArticleStep(true);
                          }
                        },
                        text: state.articlePublishSteps !=
                                ArticlePublishSteps.publish
                            ? 'Next'
                            : state.forwardedAsDraft
                                ? 'Save as draft'
                                : 'Publish',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        body: BlocBuilder<WriteArticleCubit, WriteArticleState>(
          buildWhen: (previous, current) =>
              previous.articlePublishSteps != current.articlePublishSteps,
          builder: (context, state) {
            return getView(
              state.articlePublishSteps,
              toggleArticleContent.value,
            );
          },
        ),
      ),
    );
  }

  Widget getView(ArticlePublishSteps articlePublishSteps, bool isToggled) {
    if (articlePublishSteps == ArticlePublishSteps.content) {
      return ArticleContent(
        toggleArticleContent: isToggled,
      );
    } else if (articlePublishSteps == ArticlePublishSteps.details) {
      return ArticleDetails();
    } else if (articlePublishSteps == ArticlePublishSteps.zaps) {
      return BlocBuilder<WriteArticleCubit, WriteArticleState>(
        buildWhen: (previous, current) =>
            previous.isZapSplitEnabled != current.isZapSplitEnabled ||
            previous.zapsSplits != current.zapsSplits,
        builder: (context, state) {
          return ContentZapSplits(
            isZapSplitEnabled: state.isZapSplitEnabled,
            zaps: state.zapsSplits,
            onToggleZapSplit: () {
              context.read<WriteArticleCubit>().toggleZapsSplits();
            },
            onAddZapSplitUser: (pubkey) {
              context.read<WriteArticleCubit>().addZapSplit(pubkey);
            },
            onRemoveZapSplitUser: (pubkey) {
              context.read<WriteArticleCubit>().onRemoveZapSplit(pubkey);
            },
            onSetZapProportions: (index, zap, percentage) {
              context.read<WriteArticleCubit>().setZapPropertion(
                    index: index,
                    zapSplit: zap,
                    newPercentage: percentage,
                  );
            },
          );
        },
      );
    } else {
      return BlocBuilder<WriteArticleCubit, WriteArticleState>(
        builder: (context, state) {
          return ArticleSelectedRelays(
            selectedRelays: state.selectedRelays,
            totaRelays: state.totalRelays,
            deleteDraft: state.deleteDraft,
            isDraft: state.isDraft,
            isDraftShown: true,
            isForwardedAsDraft: state.forwardedAsDraft,
            onDeleteDraft: () {
              context.read<WriteArticleCubit>().toggleDraftDeletion();
            },
            onToggle: (relay) {
              if (!mandatoryRelays.contains(relay)) {
                context.read<WriteArticleCubit>().setRelaySelection(relay);
              }
            },
          );
        },
      );
    }
  }
}
