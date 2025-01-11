// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/blocs/properties_cubit/properties_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/home_view/widgets/topics_view.dart';
import 'package:yakihonne/views/points_management_view/widgets/points_login_popup.dart';
import 'package:yakihonne/views/properties_view/widgets/keys_view.dart';
import 'package:yakihonne/views/properties_view/widgets/mute_list_view.dart';
import 'package:yakihonne/views/properties_view/widgets/profile_image_update.dart';
import 'package:yakihonne/views/properties_view/widgets/relays_update.dart';
import 'package:yakihonne/views/properties_view/widgets/thumbnail_update.dart';
import 'package:yakihonne/views/properties_view/widgets/wallet_property.dart';
import 'package:yakihonne/views/properties_view/widgets/zaps_configurations.dart';
import 'package:yakihonne/views/wallet_balance_view/widgets/wallet_options_view.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class PropertiesView extends StatelessWidget {
  PropertiesView({
    Key? key,
  }) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'Properties screen');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertiesCubit(
        nostrRepository: context.read<NostrDataRepository>(),
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
      ),
      child: BlocBuilder<PropertiesCubit, PropertiesState>(
        builder: (context, state) {
          return getView(context: context, userStatus: state.userStatus);
        },
      ),
    );
  }

  Widget getView({
    required UserStatus userStatus,
    required BuildContext context,
  }) {
    if (userStatus == UserStatus.UsingPrivKey) {
      return PropertiesList();
    } else if (userStatus == UserStatus.UsingPubKey) {
      return NoPrivateWidget(
        title: 'Private key required!',
        description:
            "It seems that you don't own this account, please reconnect with the secret key to commit actions on this account.",
        icon: PagesIcons.noPrivate,
        buttonText: 'Logout',
        onClicked: () {
          context.read<MainCubit>().disconnect();
        },
      );
    } else {
      return NotConnectedWidget();
    }
  }
}

class PropertiesList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final name = useTextEditingController(text: '');
    final displayName = useTextEditingController(text: '');
    final website = useTextEditingController(text: '');
    final description = useTextEditingController(text: '');
    final nip05 = useTextEditingController(text: '');

    return ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? ListView(
            padding: const EdgeInsets.all(kDefaultPadding),
            children: [
              PropertyThumbnail(),
              const SizedBox(
                height: kDefaultPadding,
              ),
              PropertyDescription(
                description: description,
                name: name,
                displayName: displayName,
                website: website,
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              MasonryGridView(
                gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                crossAxisSpacing: kDefaultPadding / 2,
                mainAxisSpacing: kDefaultPadding / 2,
                shrinkWrap: true,
                primary: false,
                children: [
                  PropertyKeys(),
                  PropertyNip05(nip05: nip05),
                  PropertyComment(),
                  PropertyRelaySettings(),
                  PropertyYakiChest(),
                  PropertyLightning(),
                  PropertyWallets(),
                  PropertyZaps(),
                  PropertyAccountDeletion(),
                ],
              ),
            ],
          )
        : ListView(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding,
              horizontal: kDefaultPadding / 2,
            ),
            children: [
              PropertyThumbnail(),
              const SizedBox(
                height: kDefaultPadding,
              ),
              PropertyDescription(
                description: description,
                name: name,
                displayName: displayName,
                website: website,
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              PropertyKeys(),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              PropertyRelaySettings(),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              PropertyNip05(nip05: nip05),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              PropertyComment(),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              PropertyYakiChest(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: const Divider(
                  height: kDefaultPadding * 2,
                ),
              ),
              PropertyLightning(),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              PropertyWallets(),
              // PropertyWallet(),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              PropertyZaps(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: const Divider(
                  height: kDefaultPadding * 2,
                ),
              ),
              PropertyAccountDeletion(),
              const SizedBox(
                height: 45,
              ),
            ],
          );
  }
}

class PropertyDescription extends StatelessWidget {
  const PropertyDescription({
    Key? key,
    required this.description,
    required this.name,
    required this.displayName,
    required this.website,
  }) : super(key: key);

  final TextEditingController description;
  final TextEditingController name;
  final TextEditingController displayName;
  final TextEditingController website;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        description.text = state.description;
        name.text = state.name;
        displayName.text = state.displayName;
        website.text = state.website;
        final hintStyle = Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(color: kDimGrey, fontStyle: FontStyle.italic);
        if (state.propertiesToggle == PropertiesToggle.personal) {
          return Column(
            children: [
              TextFormField(
                controller: name,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  hintStyle: hintStyle,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              TextFormField(
                controller: displayName,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Your display name',
                  hintStyle: hintStyle,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              TextFormField(
                controller: description,
                maxLines: 4,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Your decription',
                  hintStyle: hintStyle,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              TextFormField(
                controller: website,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Your website',
                  hintStyle: hintStyle,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        context.read<PropertiesCubit>().updateMetadata(
                          data: {
                            'about': description.text,
                            'displayName': displayName.text,
                            'name': name.text,
                            'website': website.text,
                          },
                          onFailure: (message) {
                            singleSnackBar(
                              context: context,
                              message: message,
                              color: kRed,
                              backGroundColor: kRedSide,
                              icon: ToastsIcons.error,
                            );
                          },
                          onSuccess: (message) {
                            context
                                .read<PropertiesCubit>()
                                .setPropertyToggle(PropertiesToggle.none);
                            singleSnackBar(
                              context: context,
                              message: message,
                              color: kGreen,
                              backGroundColor: kGreenSide,
                              icon: ToastsIcons.success,
                            );
                          },
                        );
                      },
                      child: Text(
                        'Update',
                        style: Theme.of(context).textTheme.bodyMedium!,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        context
                            .read<PropertiesCubit>()
                            .setPropertyToggle(PropertiesToggle.none);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: kTransparent,
                        side: BorderSide(
                          color: kRed,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: kRed,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          final isNameInactive = state.name.isEmpty;
          final isDisplayNameInactive = state.displayName.isEmpty;
          final isDescriptionInactive = state.description.isEmpty;
          final isWebsiteInactive = state.website.isEmpty;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isNameInactive ? 'No name' : state.name,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isNameInactive ? kDimGrey : null,
                      fontStyle:
                          isNameInactive ? FontStyle.italic : FontStyle.normal,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                isDisplayNameInactive
                    ? 'Your display name'
                    : '@${state.displayName}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: kDimGrey,
                      fontStyle: isDisplayNameInactive
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              SelectableText(
                isDescriptionInactive ? 'Your description' : state.description,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: isDescriptionInactive ? kDimGrey : null,
                      fontStyle: isDescriptionInactive
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              if (!isWebsiteInactive)
                GestureDetector(
                  onTap: () => openWebPage(url: state.website),
                  behavior: HitTestBehavior.translucent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        FeatureIcons.link,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      Text(
                        state.website,
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: kOrangeContrasted,
                                ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  state.website,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: kDimGrey,
                        fontStyle: isDisplayNameInactive
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                ),
              Center(
                child: TextButton(
                  onPressed: () {
                    context
                        .read<PropertiesCubit>()
                        .setPropertyToggle(PropertiesToggle.personal);
                  },
                  child: Text(
                    'Edit',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).primaryColorDark,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                    visualDensity: VisualDensity(
                      horizontal: 0,
                      vertical: -3,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class PropertyThumbnail extends StatelessWidget {
  const PropertyThumbnail({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      buildWhen: (previous, current) =>
          previous.propertiesViews != current.propertiesViews ||
          previous.imageLink != current.imageLink ||
          previous.bannerLink != current.bannerLink,
      builder: (context, state) {
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 150 + 130 / 2,
            ),
            Stack(
              children: [
                Container(
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                    gradient: LinearGradient(
                      colors: [
                        kTransparent,
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => ArticleThumbnail(
                      image: state.bannerLink,
                      width: constraints.maxWidth,
                      placeholder: state.placeHolder,
                      height: 150,
                    ),
                  ),
                ),
                Positioned(
                  left: kDefaultPadding / 2,
                  top: kDefaultPadding / 2,
                  right: kDefaultPadding / 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ThumbnailUpdate.routeName,
                          );
                        },
                        icon: Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        label: Text(
                          state.bannerLink.isEmpty
                              ? 'upload cover'
                              : 'update cover',
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    height: 1,
                                  ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(
                                alpha: 0.8,
                              ),
                        ),
                      ),
                      if (state.bannerLink.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: context.read<PropertiesCubit>(),
                                child: CupertinoAlertDialog(
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);

                                        context
                                            .read<PropertiesCubit>()
                                            .updateMetadata(
                                          data: {'banner': ''},
                                          onFailure: (message) {
                                            singleSnackBar(
                                              context: context,
                                              message: message,
                                              color: kRed,
                                              backGroundColor: kRedSide,
                                              icon: ToastsIcons.error,
                                            );
                                          },
                                          onSuccess: (message) {
                                            context
                                                .read<PropertiesCubit>()
                                                .deleteBanner(state.bannerLink);
                                            singleSnackBar(
                                              context: context,
                                              message: message,
                                              color: kGreen,
                                              backGroundColor: kGreenSide,
                                              icon: ToastsIcons.success,
                                            );
                                          },
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: kTransparent,
                                      ),
                                      child: Text(
                                        'delete',
                                        style: TextStyle(
                                          color: kRed,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'cancel',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: kTransparent,
                                      ),
                                    ),
                                  ],
                                  title: Text(
                                    'Delete cover picture!',
                                    style: TextStyle(
                                      height: 1.5,
                                    ),
                                  ),
                                  content: Text(
                                    "You're about to delete your cover picture, do you wish to proceed?",
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            CupertinoIcons.delete,
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .scaffoldBackgroundColor
                                .withValues(
                                  alpha: 0.8,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, ProfileImageUpdate.routeName);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Stack(
                    children: [
                      ProfilePicture2(
                        size: 130,
                        image: state.imageLink,
                        placeHolder: state.random,
                        padding: 0,
                        strokeWidth: 3,
                        strokeColor: Theme.of(context).scaffoldBackgroundColor,
                        onClicked: () {
                          Navigator.pushNamed(
                            context,
                            ProfileImageUpdate.routeName,
                          );
                        },
                      ),
                      Positioned(
                        right: kDefaultPadding / 2,
                        bottom: kDefaultPadding / 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColorLight,
                          ),
                          child: Icon(Icons.add),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PropertyKeys extends StatelessWidget {
  const PropertyKeys({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                KeysView.routeName,
                arguments: [
                  state.authPubKey,
                  state.authPrivKey,
                  state.isUsingSigner,
                ],
              );
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 1.5,
              ),
              child: PropertyRow(
                isToggled: false,
                icon: FeatureIcons.keys,
                title: 'Your keys',
                isRaw: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PropertyNip05 extends StatelessWidget {
  const PropertyNip05({
    super.key,
    required this.nip05,
  });

  final TextEditingController nip05;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        nip05.text = state.nip05;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (state.propertiesToggle == PropertiesToggle.nip05) {
                    context.read<PropertiesCubit>().setPropertyToggle(
                          PropertiesToggle.none,
                        );
                  } else {
                    context.read<PropertiesCubit>().setPropertyToggle(
                          PropertiesToggle.nip05,
                        );
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding / 1.5,
                  ),
                  child: PropertyRow(
                    isToggled: state.propertiesToggle == PropertiesToggle.nip05,
                    icon: FeatureIcons.nip05,
                    title: 'NIP-05 address',
                  ),
                ),
              ),
              Visibility(
                visible: state.propertiesToggle == PropertiesToggle.nip05,
                child: Column(
                  children: [
                    Divider(
                      height: 0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(kDefaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nip05,
                            decoration: InputDecoration(
                              hintText: 'Enter your NIP-05 address',
                              enabledBorder: containerBorder,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kDimGrey,
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(
                                  kDefaultPadding / 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          Text(
                            'Enter a NIP-05 address to verify your public key.',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: kDimGrey,
                                ),
                          ),
                          const SizedBox(
                            height: kDefaultPadding,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                context.read<PropertiesCubit>().updateMetadata(
                                  data: {
                                    'nip05': nip05.text,
                                  },
                                  onFailure: (message) {
                                    singleSnackBar(
                                      context: context,
                                      message: message,
                                      color: kRed,
                                      backGroundColor: kRedSide,
                                      icon: ToastsIcons.error,
                                    );
                                  },
                                  onSuccess: (message) {
                                    singleSnackBar(
                                      context: context,
                                      message: message,
                                      color: kGreen,
                                      backGroundColor: kGreenSide,
                                      icon: ToastsIcons.success,
                                    );
                                  },
                                );
                              },
                              child: Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PropertyComment extends StatelessWidget {
  const PropertyComment({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (state.propertiesToggle == PropertiesToggle.comments) {
                    context.read<PropertiesCubit>().setPropertyToggle(
                          PropertiesToggle.none,
                        );
                  } else {
                    context.read<PropertiesCubit>().setPropertyToggle(
                          PropertiesToggle.comments,
                        );
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding / 1.5,
                  ),
                  child: PropertyRow(
                    isToggled:
                        state.propertiesToggle == PropertiesToggle.comments,
                    icon: FeatureIcons.shuffle,
                    title: 'Content moderation',
                  ),
                ),
              ),
              Visibility(
                visible: state.propertiesToggle == PropertiesToggle.comments,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 0,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mute list',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                MuteListView.routeName,
                              );
                            },
                            child: Text(
                              'edit',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: kTransparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Topics configuration',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                TopicsView.routeName,
                              );
                            },
                            child: Text(
                              'edit',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: kTransparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Media uploader',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
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
                                        .read<PropertiesCubit>()
                                        .updateUploadServer(
                                          UploadServers.NOSTR_BUILD,
                                        );
                                  },
                                  selected: UploadServers.NOSTR_BUILD ==
                                      state.uploadServer,
                                  title: UploadServers.NOSTR_BUILD,
                                  itemTheme: PullDownMenuItemTheme(
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .labelMedium!,
                                  ),
                                ),
                                PullDownMenuItem.selectable(
                                  onTap: () {
                                    context
                                        .read<PropertiesCubit>()
                                        .updateUploadServer(
                                          UploadServers.YAKIHONNE,
                                        );
                                  },
                                  selected: UploadServers.YAKIHONNE ==
                                      state.uploadServer,
                                  title: UploadServers.YAKIHONNE,
                                  itemTheme: PullDownMenuItemTheme(
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .labelMedium!,
                                  ),
                                ),
                              ];
                            },
                            buttonBuilder: (context, showMenu) =>
                                GestureDetector(
                              onTap: showMenu,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      state.uploadServer,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    const SizedBox(
                                      width: kDefaultPadding / 4,
                                    ),
                                    Icon(
                                      CupertinoIcons.chevron_up_chevron_down,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Use nip 44 for private messaging',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: CupertinoSwitch(
                              value: state.isUsingNip44,
                              onChanged: (isToggled) {
                                context
                                    .read<PropertiesCubit>()
                                    .setUsedMessagingNip(isToggled);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                      ),
                      child: Text(
                        'By enabling this, you will be using the new specification for the private messaging which is based on nip 44, hence that disabling it will allow you to use the older version nip 4.',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: kDimGrey,
                            ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Crossposting suffix',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: CupertinoSwitch(
                              value: state.isPrefixUsed,
                              onChanged: (isToggled) {
                                context
                                    .read<PropertiesCubit>()
                                    .setYakihonnePrefix(isToggled);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                      ),
                      child: Text(
                        'Enabling this, will mark your comments with YakiHonne suffix that will be recognized on NOSTR notes clients.',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: kDimGrey,
                            ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PropertyWallets extends StatelessWidget {
  PropertyWallets({
    super.key,
  });

  final gK = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send zaps',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                color: Theme.of(context).primaryColorLight,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (state.propertiesToggle == PropertiesToggle.wallets) {
                        context.read<PropertiesCubit>().setPropertyToggle(
                              PropertiesToggle.none,
                            );
                      } else {
                        context.read<PropertiesCubit>().setPropertyToggle(
                              PropertiesToggle.wallets,
                            );
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding / 1.5,
                      ),
                      child: PropertyRow(
                        isToggled:
                            state.propertiesToggle == PropertiesToggle.wallets,
                        icon: FeatureIcons.wallet,
                        title: 'Wallets',
                      ),
                    ),
                  ),
                  BlocBuilder<LightningZapsCubit, LightningZapsState>(
                    builder: (context, lState) {
                      return Visibility(
                        visible:
                            state.propertiesToggle == PropertiesToggle.wallets,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                              height: 0,
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 4,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: kDefaultPadding / 4,
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: kDefaultPadding / 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Add wallet',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: kDimGrey,
                                                ),
                                          ),
                                        ),
                                        CustomIconButton(
                                          onClicked: () {
                                            showBlurredModal(
                                              context: context,
                                              view: WalletOptions(),
                                            );
                                          },
                                          icon: FeatureIcons.addRaw,
                                          size: 15,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (lState.wallets.isNotEmpty) ...[
                                    const SizedBox(
                                      height: kDefaultPadding / 2,
                                    ),
                                    ...lState.wallets.values
                                        .map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: kDefaultPadding / 2,
                                              vertical: kDefaultPadding / 4,
                                            ),
                                            child: Row(
                                              children: [
                                                SvgPicture.asset(
                                                  e.kind == 1
                                                      ? FeatureIcons.nwc
                                                      : FeatureIcons.alby,
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                const SizedBox(
                                                  width: kDefaultPadding / 2,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    e.lud16,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (e.id !=
                                                    lState
                                                        .selectedWalletId) ...[
                                                  const SizedBox(
                                                    width: kDefaultPadding / 2,
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      lightningZapsCubit
                                                          .setSelectedWallet(
                                                        e.id,
                                                        () {},
                                                      );
                                                    },
                                                    style: IconButton.styleFrom(
                                                      visualDensity:
                                                          VisualDensity(
                                                        horizontal: -4,
                                                        vertical: -4,
                                                      ),
                                                    ),
                                                    icon: SvgPicture.asset(
                                                      FeatureIcons.refresh,
                                                      width: 20,
                                                      height: 20,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                        Theme.of(context)
                                                            .primaryColorDark,
                                                        BlendMode.srcIn,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (e.id ==
                                                    lState
                                                        .selectedWalletId) ...[
                                                  const SizedBox(
                                                    width: kDefaultPadding / 2,
                                                  ),
                                                  DotContainer(
                                                    color: kGreen,
                                                  ),
                                                  const SizedBox(
                                                    width: kDefaultPadding / 4,
                                                  ),
                                                ],
                                                IconButton(
                                                  onPressed: () {
                                                    lightningZapsCubit
                                                        .removeWallet(
                                                      e.id,
                                                      () {},
                                                    );
                                                  },
                                                  style: IconButton.styleFrom(
                                                    visualDensity:
                                                        VisualDensity(
                                                      horizontal: -4,
                                                      vertical: -4,
                                                    ),
                                                  ),
                                                  icon: Icon(
                                                    Icons.remove,
                                                    color: kRed,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: kDefaultPadding,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class PropertyAccountDeletion extends StatelessWidget {
  const PropertyAccountDeletion({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: GestureDetector(
            onTap: () {
              showAccountDeletionDialogue(
                context: context,
                onDelete: () {
                  context.read<PropertiesCubit>().deleteUserAccount(
                    onSuccess: () {
                      Navigator.pop(context);
                      context.read<MainCubit>().disconnect();
                      context
                          .read<LightningZapsCubit>()
                          .deleteWalletConfiguration();
                    },
                  );
                },
              );
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 1.5,
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.delete,
                    color: kRed,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 1.5,
                  ),
                  Expanded(
                    child: Text(
                      'Delete account',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .copyWith(color: kRed),
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PropertyYakiChest extends StatelessWidget {
  const PropertyYakiChest({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kDefaultPadding / 1.5,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  FeatureIcons.reward,
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 1.5,
                ),
                Expanded(
                  child: Text(
                    'Yaki chest',
                    style: Theme.of(context).textTheme.labelLarge!,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                if (state.userGlobalStats != null)
                  Row(
                    children: [
                      Text(
                        'Connected',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: kGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      DotContainer(
                        color: kGreen,
                        isNotMarging: true,
                      ),
                    ],
                  )
                else
                  TextButton(
                    onPressed: () {
                      showBlurredModal(
                        context: context,
                        view: PointsLoginPopup(),
                      );
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity(
                        vertical: -4,
                        horizontal: 2,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Connect',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PropertyZaps extends StatelessWidget {
  const PropertyZaps({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, ZapsView.routeName);
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 1.5,
              ),
              child: PropertyRow(
                isToggled: false,
                icon: FeatureIcons.zap,
                title: 'Zaps configuration',
                isRaw: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PropertyRelaySettings extends StatelessWidget {
  const PropertyRelaySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      buildWhen: (previous, current) =>
          previous.relays != current.relays ||
          previous.activeRelays != current.activeRelays,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, RelayUpdateView.routeName);
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 1.5,
              ),
              child: PropertyRow(
                isToggled: false,
                icon: FeatureIcons.relays,
                title:
                    'Relays settings  ${state.activeRelays.length} / ${state.relays.length}',
                isRaw: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PropertyWallet extends StatelessWidget {
  const PropertyWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Send zaps',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorLight,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, WalletView.routeName);
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 1.5,
              ),
              child: PropertyRow(
                isToggled: false,
                icon: FeatureIcons.wallet,
                title: 'Wallet configuration',
                isRaw: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PropertyLightning extends HookWidget {
  const PropertyLightning({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final lud16Controller = useTextEditingController(
      text: context.read<PropertiesCubit>().state.lud16,
    );

    final lud06Controller = useTextEditingController(
      text: context.read<PropertiesCubit>().state.lud6,
    );

    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Receive zaps',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                color: Theme.of(context).primaryColorLight,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (state.propertiesToggle ==
                          PropertiesToggle.lightning) {
                        context.read<PropertiesCubit>().setPropertyToggle(
                              PropertiesToggle.none,
                            );
                      } else {
                        context.read<PropertiesCubit>().setPropertyToggle(
                              PropertiesToggle.lightning,
                            );
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kDefaultPadding / 1.5,
                      ),
                      child: PropertyRow(
                        isToggled: state.propertiesToggle ==
                            PropertiesToggle.lightning,
                        icon: FeatureIcons.zaps,
                        title: 'Lightning addresses',
                      ),
                    ),
                  ),
                  Visibility(
                    visible:
                        state.propertiesToggle == PropertiesToggle.lightning,
                    child: Column(
                      children: [
                        Divider(
                          height: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(kDefaultPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LUD-16',
                                style: Theme.of(context).textTheme.bodySmall!,
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter your address LUD-06 or LUD-16',
                                  enabledBorder: containerBorder,
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: kDimGrey,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      kDefaultPadding / 1.5,
                                    ),
                                  ),
                                ),
                                controller: lud16Controller,
                                onChanged: (lud16) {
                                  context.read<PropertiesCubit>().setLud16(
                                    lud16,
                                    (lud06) {
                                      lud06Controller.text = lud06;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                              Text(
                                'Enter a LUD-16 address to enable sending and receiving lightning tips.',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: kDimGrey,
                                    ),
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(
                                height: kDefaultPadding,
                              ),
                              Text(
                                'LUD-06',
                                style: Theme.of(context).textTheme.bodySmall!,
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              TextField(
                                controller: lud06Controller,
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter your address LUD-06 or LUD-16',
                                  enabledBorder: containerBorder,
                                  focusedBorder: containerBorder,
                                ),
                                enabled: false,
                              ),
                              const SizedBox(
                                height: kDefaultPadding,
                              ),
                              StatusButton(
                                text: 'Save',
                                isDisabled: state.isSameLud16,
                                onClicked: () {
                                  context.read<PropertiesCubit>().updateLud16(
                                    onFailed: (message) {
                                      singleSnackBar(
                                        context: context,
                                        message: message,
                                        color: kRed,
                                        backGroundColor: kRedSide,
                                        icon: ToastsIcons.error,
                                      );
                                    },
                                    onSuccess: (message) {
                                      context
                                          .read<PropertiesCubit>()
                                          .setPropertyToggle(
                                              PropertiesToggle.none);
                                      singleSnackBar(
                                        context: context,
                                        message: message,
                                        color: kGreen,
                                        backGroundColor: kGreenSide,
                                        icon: ToastsIcons.success,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class PropertyRow extends StatelessWidget {
  const PropertyRow({
    Key? key,
    required this.icon,
    required this.title,
    required this.isToggled,
    this.isRaw,
  }) : super(key: key);

  final String icon;
  final String title;
  final bool isToggled;
  final bool? isRaw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 25,
          height: 25,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 1.5,
        ),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Icon(
          isRaw != null
              ? Icons.keyboard_arrow_right_outlined
              : isToggled
                  ? Icons.keyboard_arrow_up_outlined
                  : Icons.keyboard_arrow_down_outlined,
          color: Theme.of(context).primaryColorDark,
        ),
      ],
    );
  }
}

class PropertiesTextControllers extends StatelessWidget {
  const PropertiesTextControllers({
    super.key,
    required this.textController,
    required this.onClose,
    required this.onSubmit,
    this.maxLines,
  });

  final TextEditingController textController;
  final Function() onClose;
  final Function() onSubmit;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: textController,
          minLines: maxLines,
          maxLines: maxLines,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onSubmit,
              icon: SvgPicture.asset(
                FeatureIcons.send,
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: SvgPicture.asset(
                FeatureIcons.close,
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}
