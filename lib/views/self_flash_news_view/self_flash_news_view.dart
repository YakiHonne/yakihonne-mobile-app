// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/self_flash_news_cubit/self_flash_news_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/flash_news_container.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class SelfFlashNewsView extends StatelessWidget {
  const SelfFlashNewsView({
    Key? key,
    required this.mainScrollController,
  }) : super(key: key);

  final ScrollController mainScrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelfFlashNewsCubit()..getFlashNews(),
      child: BlocBuilder<SelfFlashNewsCubit, SelfFlashNewsState>(
        builder: (context, state) {
          return getView(state.isFlashLoading, context);
        },
      ),
    );
  }

  Widget getView(bool isLoading, BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
        child: SpinKitThreeBounce(
          size: 25,
          color: Theme.of(context).primaryColorDark,
        ),
      );
    } else {
      return SelfFlashNewsList();
    }
  }
}

class SelfFlashNewsList extends StatelessWidget {
  const SelfFlashNewsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocBuilder<SelfFlashNewsCubit, SelfFlashNewsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 2,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.isFlashNewsSelected
                                ? 'Flash news'
                                : 'Pending FlashNews',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => context
                              .read<SelfFlashNewsCubit>()
                              .filterByImportance(),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: state.isImportant
                                ? Theme.of(context).primaryColorDark
                                : Theme.of(context).primaryColorLight,
                          ),
                          icon: SvgPicture.asset(
                            FeatureIcons.flame,
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              !state.isImportant
                                  ? Theme.of(context).primaryColorDark
                                  : Theme.of(context).primaryColorLight,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        PullDownButton(
                          animationBuilder: (context, state, child) {
                            return child;
                          },
                          routeTheme: PullDownMenuRouteTheme(
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                          itemBuilder: (context) {
                            return [
                              PullDownMenuItem.selectable(
                                onTap: () {
                                  context
                                      .read<SelfFlashNewsCubit>()
                                      .setFlashNewsSelected(true);
                                },
                                selected: state.isFlashNewsSelected,
                                title: 'Active flash news',
                                itemTheme: PullDownMenuItemTheme(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        fontWeight: state.isFlashNewsSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                              PullDownMenuItem.selectable(
                                onTap: () {
                                  context
                                      .read<SelfFlashNewsCubit>()
                                      .setFlashNewsSelected(false);
                                },
                                selected: !state.isFlashNewsSelected,
                                title: 'Pending flash news',
                                itemTheme: PullDownMenuItemTheme(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        fontWeight: !state.isFlashNewsSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                            ];
                          },
                          buttonBuilder: (context, showMenu) => IconButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                            icon: SvgPicture.asset(
                              FeatureIcons.flashNews,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: state.isFlashNewsSelected
                ? state.flashNews.isEmpty
                    ? EmptyList(
                        description: 'No flash news can be found',
                        icon: FeatureIcons.flashNews,
                      )
                    : isMobile
                        ? ListView.separated(
                            itemBuilder: (context, index) {
                              final flashNews = state.flashNews[index];

                              return FlashNewsContainer(
                                mainFlashNews:
                                    MainFlashNews(flashNews: flashNews),
                                flashNewsType: FlashNewsType.userActive,
                                userStatus: state.userStatus,
                                onClicked: () {
                                  Navigator.pushNamed(
                                    context,
                                    FlashNewsDetailsView.routeName,
                                    arguments: [
                                      MainFlashNews(flashNews: flashNews),
                                      true
                                    ],
                                  );
                                },
                                onDelete: () {
                                  showCupertinoDeletionDialogue(
                                    context: context,
                                    title: 'Delete flash news?',
                                    description:
                                        "You're about to delete this flash news, do you wish to proceed?",
                                    buttonText: 'delete',
                                    onDelete: () {
                                      context
                                          .read<SelfFlashNewsCubit>()
                                          .deleteFlashNews(
                                        flashNews,
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            separatorBuilder: (context, index) => SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            itemCount: state.flashNews.length,
                          )
                        : MasonryGridView.builder(
                            gridDelegate:
                                SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                            ),
                            mainAxisSpacing: kDefaultPadding / 2,
                            crossAxisSpacing: kDefaultPadding / 2,
                            itemBuilder: (context, index) {
                              final flashNews = state.flashNews[index];

                              return FlashNewsContainer(
                                mainFlashNews:
                                    MainFlashNews(flashNews: flashNews),
                                flashNewsType: FlashNewsType.userActive,
                                userStatus: state.userStatus,
                                onClicked: () {
                                  Navigator.pushNamed(
                                    context,
                                    FlashNewsDetailsView.routeName,
                                    arguments: [
                                      MainFlashNews(flashNews: flashNews),
                                      true
                                    ],
                                  );
                                },
                                onDelete: () {
                                  showCupertinoDeletionDialogue(
                                    context: context,
                                    title: 'Delete flash news?',
                                    description:
                                        "You're about to delete this flash news, do you wish to proceed?",
                                    buttonText: 'delete',
                                    onDelete: () {
                                      context
                                          .read<SelfFlashNewsCubit>()
                                          .deleteFlashNews(
                                        flashNews,
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            itemCount: state.flashNews.length,
                          )
                : state.pendingFlashNews.isEmpty
                    ? EmptyList(
                        description: 'No pending flash news can be found',
                        icon: FeatureIcons.flashNews,
                      )
                    : isMobile
                        ? ListView.separated(
                            itemBuilder: (context, index) {
                              final pendingFlashNews =
                                  state.pendingFlashNews[index];

                              return FlashNewsContainer(
                                mainFlashNews: MainFlashNews(
                                  flashNews: pendingFlashNews.flashNews,
                                ),
                                flashNewsType: FlashNewsType.userPending,
                                userStatus: state.userStatus,
                                onPayWithAlby: () {
                                  final _cancel = BotToast.showLoading();

                                  context
                                      .read<LightningZapsCubit>()
                                      .handleWalletZap(
                                        sats: (nostrRepository.flashNewsPrice +
                                                (pendingFlashNews
                                                        .flashNews.isImportant
                                                    ? nostrRepository
                                                        .importantTagPrice
                                                    : 0))
                                            .toInt(),
                                        user: emptyUserModel.copyWith(
                                          lud16:
                                              nostrRepository.yakihonneWallet,
                                          pubKey: yakihonneHex,
                                          picturePlaceholder:
                                              getRandomPlaceholder(
                                            input: yakihonneHex,
                                            isPfp: true,
                                          ),
                                        ),
                                        comment:
                                            '${nostrRepository.user.name.isNotEmpty ? nostrRepository.user.name : 'unknown'} has paid for a flash news',
                                        eventId: pendingFlashNews.eventId,
                                        onFinished: (invoice) {},
                                        onSuccess: (invoice) {
                                          _cancel.call();
                                          context
                                              .read<SelfFlashNewsCubit>()
                                              .submitPendingFlashNews(
                                                pendingFlashNews:
                                                    pendingFlashNews,
                                              );
                                        },
                                        onFailure: (message) {
                                          _cancel.call();
                                          singleSnackBar(
                                            context: context,
                                            message: message,
                                            color: kRed,
                                            backGroundColor: kRedSide,
                                            icon: ToastsIcons.error,
                                          );
                                        },
                                      );
                                },
                                onConfirmPayment: () {
                                  context
                                      .read<SelfFlashNewsCubit>()
                                      .submitPendingFlashNews(
                                        pendingFlashNews: pendingFlashNews,
                                      );
                                },
                                onCopyInvoice: () {
                                  Clipboard.setData(
                                    new ClipboardData(
                                      text: pendingFlashNews.lnbc,
                                    ),
                                  );

                                  singleSnackBar(
                                    context: context,
                                    message: 'Invoice code copied!',
                                    color: kGreen,
                                    backGroundColor: kGreenSide,
                                    icon: ToastsIcons.success,
                                  );
                                },
                              );
                            },
                            separatorBuilder: (context, index) => SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            itemCount: state.pendingFlashNews.length,
                          )
                        : MasonryGridView.builder(
                            gridDelegate:
                                SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                            ),
                            mainAxisSpacing: kDefaultPadding / 2,
                            crossAxisSpacing: kDefaultPadding / 2,
                            itemBuilder: (context, index) {
                              final pendingFlashNews =
                                  state.pendingFlashNews[index];

                              return FlashNewsContainer(
                                mainFlashNews: MainFlashNews(
                                  flashNews: pendingFlashNews.flashNews,
                                ),
                                flashNewsType: FlashNewsType.userPending,
                                userStatus: state.userStatus,
                                onConfirmPayment: () {
                                  context
                                      .read<SelfFlashNewsCubit>()
                                      .submitPendingFlashNews(
                                        pendingFlashNews: pendingFlashNews,
                                      );
                                },
                                onCopyInvoice: () {
                                  Clipboard.setData(
                                    new ClipboardData(
                                      text: pendingFlashNews.lnbc,
                                    ),
                                  );

                                  singleSnackBar(
                                    context: context,
                                    message: 'Invoice code copied!',
                                    color: kGreen,
                                    backGroundColor: kGreenSide,
                                    icon: ToastsIcons.success,
                                  );
                                },
                              );
                            },
                            itemCount: state.pendingFlashNews.length,
                          ),
          ),
        );
      },
    );
  }
}
