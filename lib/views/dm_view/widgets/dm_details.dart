// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/dm_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/dm_view/widgets/camera_options_view.dart';
import 'package:yakihonne/views/giphy_view/giphy_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class DmDetails extends HookWidget {
  static const routeName = '/dmDetailsView';
  static Route route(RouteSettings settings) {
    final data = settings.arguments as List;
    nostrRepository.usersMessageNotifications.add(data[0]);

    return CupertinoPageRoute(
      builder: (_) => DmDetails(
        pubkey: data[0],
      ),
    );
  }

  const DmDetails({
    Key? key,
    required this.pubkey,
  }) : super(key: key);

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    final scrollController = useScrollController();
    final isShrinked = useState(false);
    final replyId = useState<String?>(null);
    final replyPubkey = useState<String?>(null);
    final replyText = useState<String?>(null);

    useEffect(
      () {
        return () {
          nostrRepository.usersMessageNotifications.remove(pubkey);
        };
      },
      [],
    );

    return Scaffold(
      appBar: DmAppBar(
        pubkey: pubkey,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BlocBuilder<DmsCubit, DmsState>(
                      buildWhen: (previous, current) =>
                          previous.rebuild != current.rebuild,
                      builder: (context, state) {
                        final dm = state.dmSessionDetails[pubkey];
                        if (dm == null || dm.dmSession.length() == 0) {
                          return Center(
                            child: EmptyList(
                              description:
                                  'There are no message to be displayed with this user.',
                              icon: FeatureIcons.dms,
                            ),
                          );
                        }

                        final dmLength = dm.dmSession.length();

                        return ScrollShadow(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: ListView.custom(
                            reverse: true,
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding,
                              horizontal: kDefaultPadding / 2,
                            ),
                            childrenDelegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final event = dm.dmSession.getByIndex(index);

                                return BlocBuilder<AuthorsCubit, AuthorsState>(
                                  key: GlobalObjectKey(event!.id),
                                  builder: (context, state) {
                                    final isCurrentUser = event.pubkey ==
                                        nostrRepository.usm!.pubKey;

                                    UserModel? peerUserModel;
                                    UserModel? ownUserModel;

                                    if (!isCurrentUser) {
                                      peerUserModel =
                                          state.authors[event.pubkey] ??
                                              emptyUserModel.copyWith(
                                                pubKey: event.pubkey,
                                                picturePlaceholder:
                                                    getRandomPlaceholder(
                                                  input: event.pubkey,
                                                  isPfp: true,
                                                ),
                                              );
                                    } else {
                                      ownUserModel =
                                          state.authors[event.pubkey] ??
                                              emptyUserModel.copyWith(
                                                pubKey: event.pubkey,
                                                picturePlaceholder:
                                                    getRandomPlaceholder(
                                                  input: event.pubkey,
                                                  isPfp: true,
                                                ),
                                              );
                                    }

                                    return DmChatContainer(
                                      event: event,
                                      dmSession: dm.dmSession,
                                      isCurrentUser: isCurrentUser,
                                      peerUserModel: peerUserModel,
                                      ownUserModel: ownUserModel,
                                      scrollToIndex: (id) async {
                                        final componentContext =
                                            GlobalObjectKey(id).currentContext;

                                        if (componentContext != null) {
                                          await Scrollable.ensureVisible(
                                            componentContext,
                                            duration: Duration(seconds: 1),
                                            alignment: .5,
                                            curve: Curves.fastOutSlowIn,
                                          );
                                        }
                                      },
                                      onMessageReply:
                                          (messageId, message, pubkey) {
                                        replyId.value = messageId;
                                        replyText.value = message;
                                        replyPubkey.value = pubkey;
                                      },
                                    );
                                  },
                                );
                              },
                              childCount: dmLength,
                              findChildIndexCallback: (Key key) {
                                final valueKey = key as GlobalObjectKey;
                                final val = dm.dmSession.getAll().indexWhere(
                                      (message) => message.id == valueKey.value,
                                    );

                                return val;
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ChatResetScrollButton(scrollController: scrollController),
                ],
              ),
            ),
            Builder(
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                    bottom: kDefaultPadding / 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (replyId.value != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: kDefaultPadding / 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    BlocBuilder<AuthorsCubit, AuthorsState>(
                                      builder: (context, state) {
                                        final author =
                                            state.authors[replyPubkey.value] ??
                                                emptyUserModel.copyWith(
                                                  pubKey: pubkey,
                                                  picturePlaceholder:
                                                      getRandomPlaceholder(
                                                          input: pubkey,
                                                          isPfp: true),
                                                );

                                        return Text(
                                          'Replying to: ${getAuthorName(author)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .copyWith(
                                                color: kOrange,
                                              ),
                                        );
                                      },
                                    ),
                                    const SizedBox(
                                      height: kDefaultPadding / 6,
                                    ),
                                    Text(
                                      replyText.value!,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  replyId.value = null;
                                  replyText.value = null;
                                  replyPubkey.value = null;
                                },
                                icon: Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedCrossFade(
                                firstChild: SizedBox.shrink(),
                                secondChild: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (_) {
                                            return GiphyView(
                                              onGifSelected: (link) {
                                                context
                                                    .read<DmsCubit>()
                                                    .sendEvent(
                                                      pubkey,
                                                      link,
                                                      '',
                                                      () {},
                                                    );
                                              },
                                            );
                                          },
                                          isScrollControlled: true,
                                          useRootNavigator: true,
                                          useSafeArea: true,
                                          elevation: 0,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: kDefaultPadding / 8,
                                        ),
                                        child: SvgPicture.asset(
                                          FeatureIcons.giphy,
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: kDefaultPadding / 2,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) {
                                            return CameraOptions(
                                              pubkey: pubkey,
                                              replyId: replyId.value,
                                              onFailed: () {},
                                              onSuccess: () {
                                                replyId.value = null;
                                                replyPubkey.value = null;
                                                replyText.value = null;
                                                scrollController.animateTo(
                                                  0.0,
                                                  duration:
                                                      Duration(seconds: 1),
                                                  curve: Curves.easeOut,
                                                );
                                                Navigator.pop(context);
                                              },
                                            );
                                          },
                                          backgroundColor: kTransparent,
                                          useRootNavigator: true,
                                          elevation: 0,
                                          useSafeArea: true,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: kDefaultPadding / 8,
                                        ),
                                        child: SvgPicture.asset(
                                          FeatureIcons.camera,
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
                                crossFadeState: isShrinked.value
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 300),
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 2,
                              ),
                              GestureDetector(
                                onTap: () {
                                  isShrinked.value = !isShrinked.value;
                                },
                                child: AnimatedRotation(
                                  duration: const Duration(milliseconds: 300),
                                  turns: isShrinked.value ? 0 : 0.5,
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 2,
                              ),
                            ],
                          ),
                          BlocBuilder<DmsCubit, DmsState>(
                            builder: (context, state) {
                              return Expanded(
                                child: TextField(
                                  controller: textEditingController,
                                  decoration: InputDecoration(
                                    hintText: 'Write a message',
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        if (!state.isSendingMessage) {
                                          final text =
                                              textEditingController.text.trim();

                                          if (text.isNotEmpty) {
                                            context.read<DmsCubit>().sendEvent(
                                              pubkey,
                                              text,
                                              replyId.value,
                                              () {
                                                textEditingController.clear();
                                                replyId.value = null;
                                                replyPubkey.value = null;
                                                replyText.value = null;
                                                scrollController.animateTo(
                                                  0.0,
                                                  duration:
                                                      Duration(seconds: 1),
                                                  curve: Curves.easeOut,
                                                );
                                              },
                                            );
                                          }
                                        }
                                      },
                                      icon: state.isSendingMessage
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: SpinKitChasingDots(
                                                size: 10,
                                                color: Theme.of(context)
                                                    .primaryColorDark,
                                              ),
                                            )
                                          : SvgPicture.asset(
                                              FeatureIcons.send,
                                              width: 20,
                                              height: 20,
                                              colorFilter: ColorFilter.mode(
                                                Theme.of(context)
                                                    .primaryColorDark,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                    ),
                                  ),
                                  maxLines: 3,
                                  minLines: 1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DmAppBar extends HookWidget implements PreferredSizeWidget {
  const DmAppBar({
    Key? key,
    required this.pubkey,
  }) : super(key: key);

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthorsCubit, AuthorsState>(
      builder: (context, state) {
        final author = state.authors[pubkey] ??
            emptyUserModel.copyWith(
              pubKey: pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: pubkey, isPfp: true),
            );

        return AppBar(
          leading: FadeInRight(
            duration: const Duration(milliseconds: 500),
            from: 30,
            child: SizedBox(
              height: 45,
              width: 45,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                iconSize: 20,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                ),
              ),
            ),
          ),
          actions: [
            BlocBuilder<DmsCubit, DmsState>(
              builder: (context, state) {
                return PullDownButton(
                  animationBuilder: (context, state, child) {
                    return child;
                  },
                  routeTheme: PullDownMenuRouteTheme(
                    backgroundColor: Theme.of(context).primaryColorLight,
                  ),
                  itemBuilder: (context) {
                    final textStyle = Theme.of(context).textTheme.labelMedium;

                    return [
                      PullDownMenuItem(
                        title: 'Zap',
                        onTap: () {
                          showModalBottomSheet(
                            elevation: 0,
                            context: context,
                            builder: (_) {
                              return SetZapsView(
                                author: author,
                                isZapSplit: false,
                                zapSplits: [],
                              );
                            },
                            isScrollControlled: true,
                            useRootNavigator: true,
                            useSafeArea: true,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        },
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                        iconWidget: SvgPicture.asset(
                          FeatureIcons.zap,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      PullDownMenuItem(
                        title: dmsCubit.state.isUsingNip44
                            ? 'Disable Nip 44'
                            : 'Enabled Nip 44',
                        onTap: () {
                          final currentStatus = dmsCubit.state.isUsingNip44;

                          dmsCubit.setUsedMessagingNip(!currentStatus);
                          if (currentStatus) {
                            BotToastUtils.showSuccess(
                              'You are no longer using nip 44 to send messages',
                            );
                          } else {
                            BotToastUtils.showSuccess(
                              'You are now using nip 44 to send messages',
                            );
                          }
                        },
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                        isDestructive: dmsCubit.state.isUsingNip44,
                        iconWidget: SvgPicture.asset(
                          FeatureIcons.link,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      PullDownMenuItem(
                        title: state.mutes.contains(author.pubKey)
                            ? 'Unmute'
                            : 'Mute',
                        onTap: () {
                          final isMuted = state.mutes.contains(author.pubKey);
                          final isUsingPrivKey = getUserStatus();
                          String description = '';

                          if (isUsingPrivKey == UserStatus.UsingPrivKey) {
                            description =
                                'You are about to ${isMuted ? 'unmute' : 'mute'} "${author.name}", do you wish to proceed?';
                          } else {
                            description =
                                'You are about to ${isMuted ? 'unmute' : 'mute'} "${author.name}". ${!isMuted ? "This will be stored locally while you are not connected or using a public key," : ""} do you wish to proceed?';
                          }

                          showCupertinoCustomDialogue(
                            context: context,
                            title: isMuted ? 'Unmute user' : 'Mute user',
                            description: description,
                            buttonText: isMuted ? 'Unmute' : 'Mute',
                            buttonTextColor: isMuted ? kGreen : kRed,
                            onClicked: () {
                              context.read<DmsCubit>().setMuteStatus(
                                    pubkey: author.pubKey,
                                    onSuccess: () => Navigator.pop(context),
                                  );
                            },
                          );
                        },
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle?.copyWith(
                            color: state.mutes.contains(author.pubKey)
                                ? Theme.of(context).primaryColorDark
                                : kRed,
                          ),
                        ),
                        iconWidget: SvgPicture.asset(
                          state.mutes.contains(author.pubKey)
                              ? FeatureIcons.unmute
                              : FeatureIcons.mute,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            state.mutes.contains(author.pubKey)
                                ? Theme.of(context).primaryColorDark
                                : kRed,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ];
                  },
                  buttonBuilder: (context, showMenu) => IconButton(
                    onPressed: showMenu,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorLight,
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                );
              },
            ),
            SizedBox(
              width: kDefaultPadding / 2,
            ),
          ],
          leadingWidth: 45,
          titleSpacing: 0,
          centerTitle: false,
          title: BlocBuilder<AuthorsCubit, AuthorsState>(
            builder: (context, state) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.pushNamed(
                  context,
                  ProfileView.routeName,
                  arguments: pubkey,
                ),
                child: Row(
                  children: [
                    ProfilePicture3(
                      size: 30,
                      image: author.picture,
                      placeHolder: author.picturePlaceholder,
                      padding: 0,
                      strokeWidth: 0,
                      reduceSize: true,
                      strokeColor: kTransparent,
                      onClicked: () {},
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 3,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.name.isEmpty
                                ? Nip19.encodePubkey(author.pubKey)
                                    .substring(0, 10)
                                : author.name,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (state.nip05Validations[pubkey] ?? false)
                            Row(
                              children: [
                                Text(
                                  author.nip05,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        color: kDimGrey,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                SvgPicture.asset(
                                  FeatureIcons.verified,
                                  width: 15,
                                  height: 15,
                                  colorFilter: ColorFilter.mode(
                                    kOrangeContrasted,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class DmChatContainer extends HookWidget {
  DmChatContainer({
    Key? key,
    required this.event,
    required this.dmSession,
    required this.isCurrentUser,
    required this.peerUserModel,
    required this.ownUserModel,
    required this.onMessageReply,
    required this.scrollToIndex,
  }) : super(key: key);

  final Event event;
  final DMSession dmSession;
  final bool isCurrentUser;
  final UserModel? peerUserModel;
  final UserModel? ownUserModel;
  final Function(String, String, String) onMessageReply;
  final Function(String) scrollToIndex;

  @override
  Widget build(BuildContext context) {
    final copiedText = useState<String?>(null);
    final replyId = useState<String?>(null);
    final contentText = useState('');
    final mountedStatus = useIsMounted();

    useMemoized(() async {
      if (mountedStatus()) {
        final content = await nostrRepository.getMessage(event);
        contentText.value = content.first.trim();
        replyId.value = content.last;
        copiedText.value = content.first.trim();
      }
    });

    useAutomaticKeepAlive();

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 3,
        ),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isCurrentUser) ...[
                ProfilePicture3(
                  size: 30,
                  image: peerUserModel!.picture,
                  placeHolder: peerUserModel!.picturePlaceholder,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {},
                ),
              ],
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              if (isCurrentUser)
                ChatContainerPullDownMenu(
                  eventId: event.id,
                  copiedText: copiedText.value,
                  onMessageReply: () {
                    if (copiedText.value != null) {
                      onMessageReply.call(
                        event.id,
                        copiedText.value!,
                        isCurrentUser
                            ? ownUserModel!.pubKey
                            : peerUserModel!.pubKey,
                      );
                    }
                  },
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Theme.of(context).primaryColorLight
                        : null,
                    gradient: isCurrentUser
                        ? null
                        : LinearGradient(
                            colors: [
                              Color(0xff392D69),
                              Color(0xffB57BEE),
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          if (replyId.value != null) {
                            final searchedEvent =
                                dmSession.getById(replyId.value!);
                            if (searchedEvent != null) {
                              return GestureDetector(
                                onTap: () {
                                  scrollToIndex.call(searchedEvent.id);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: kDefaultPadding / 2,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        VerticalDivider(
                                          thickness: 2,
                                          width: 0,
                                          color: kRed,
                                        ),
                                        Flexible(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: kDefaultPadding / 2,
                                              vertical: kDefaultPadding / 3,
                                            ),
                                            child: FutureBuilder(
                                              future: nostrRepository
                                                  .getMessage(searchedEvent),
                                              builder: (context, snapshot) {
                                                String text = '';

                                                if (snapshot.hasData) {
                                                  text = snapshot.data!.first
                                                      .trim();
                                                }

                                                return linkifiedText(
                                                  context: context,
                                                  text: text,
                                                  color: isCurrentUser
                                                      ? null
                                                      : kWhite,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                      linkifiedText(
                        context: context,
                        text: contentText.value,
                        color: isCurrentUser ? null : kWhite,
                        inverseNoteColor: true,
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            event.kind == EventKind.DIRECT_MESSAGE
                                ? FeatureIcons.nonSecure
                                : FeatureIcons.secure,
                            width: 15,
                            height: 15,
                            colorFilter: ColorFilter.mode(
                              !isCurrentUser
                                  ? kWhite
                                  : Theme.of(context)
                                      .primaryColorDark
                                      .withValues(alpha: 0.5),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Flexible(
                            child: Text(
                              dateFormat3.format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  event.createdAt * 1000,
                                ),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: !isCurrentUser
                                        ? kWhite
                                        : Theme.of(context)
                                            .primaryColorDark
                                            .withValues(alpha: 0.5),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!isCurrentUser)
                ChatContainerPullDownMenu(
                  eventId: event.id,
                  copiedText: copiedText.value,
                  onMessageReply: () {
                    if (copiedText.value != null) {
                      onMessageReply.call(
                        event.id,
                        copiedText.value!,
                        isCurrentUser
                            ? ownUserModel!.pubKey
                            : peerUserModel!.pubKey,
                      );
                    }
                  },
                ),
              if (isCurrentUser) ...[
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                ProfilePicture3(
                  size: 30,
                  image: ownUserModel!.picture,
                  placeHolder: ownUserModel!.picturePlaceholder,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {},
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class ChatContainerPullDownMenu extends StatelessWidget {
  const ChatContainerPullDownMenu({
    Key? key,
    required this.eventId,
    required this.copiedText,
    required this.onMessageReply,
  }) : super(key: key);

  final String eventId;
  final String? copiedText;
  final Function() onMessageReply;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          PullDownMenuItem(
            title: 'Copy',
            onTap: () {
              if (copiedText != null) {
                Clipboard.setData(
                  new ClipboardData(
                    text: copiedText!,
                  ),
                );

                BotToastUtils.showSuccess(
                  'Message successfully copied!',
                );
              } else {
                BotToastUtils.showError(
                  'Message has not been decrypted yet!',
                );
              }
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.copy,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          PullDownMenuItem(
            title: 'Reply',
            onTap: () {
              onMessageReply.call();
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: Icon(
              CupertinoIcons.reply,
              size: 20,
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity(
          vertical: -4,
          horizontal: -4,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).primaryColorDark,
          size: 20,
        ),
      ),
    );
  }
}
