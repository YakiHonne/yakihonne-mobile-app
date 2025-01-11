// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/zap_split_user.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_details.dart';

class ContentZapSplits extends StatelessWidget {
  const ContentZapSplits({
    Key? key,
    required this.zaps,
    required this.isZapSplitEnabled,
    required this.onToggleZapSplit,
    required this.onAddZapSplitUser,
    required this.onRemoveZapSplitUser,
    required this.onSetZapProportions,
  }) : super(key: key);

  final List<ZapSplit> zaps;
  final bool isZapSplitEnabled;
  final Function() onToggleZapSplit;
  final Function(String) onAddZapSplitUser;
  final Function(String) onRemoveZapSplitUser;
  final Function(int, ZapSplit, int) onSetZapProportions;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return FadeInRight(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: const SizedBox(
                height: kDefaultPadding,
              ),
            ),
            SliverToBoxAdapter(
              child: ArticleCheckBoxListTile(
                isEnabled: true,
                status: isZapSplitEnabled,
                text: 'Enable zap splits',
                onToggle: () {
                  onToggleZapSplit.call();
                },
              ),
            ),
            SliverToBoxAdapter(
              child: const SizedBox(
                height: kDefaultPadding,
              ),
            ),
            if (!isZapSplitEnabled)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Zap splits',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Text(
                      'This feature allows you to add users whom you think are elgibile to split zaps with you once your content is Zapped.',
                      style: Theme.of(context).textTheme.bodyMedium!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Split zaps with users',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) {
                            return ZapSplitUsers(
                              currentPubkeys:
                                  zaps.map((e) => e.pubkey).toList(),
                              onAddUser: (pubkey) {
                                onAddZapSplitUser.call(pubkey);
                              },
                              onRemoveUser: (pubkey) {
                                onRemoveZapSplitUser.call(pubkey);
                              },
                            );
                          },
                          isScrollControlled: true,
                          useRootNavigator: true,
                          useSafeArea: true,
                          elevation: 0,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      },
                      label: SvgPicture.asset(
                        FeatureIcons.user,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorLight,
                          BlendMode.srcIn,
                        ),
                        fit: BoxFit.scaleDown,
                      ),
                      icon: Text(
                        'Add user',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: Theme.of(context).primaryColorLight,
                                ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorDark,
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(left: kDefaultPadding / 4),
                sliver: SliverList.separated(
                  separatorBuilder: (context, index) => SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  itemBuilder: (context, index) {
                    final zap = zaps[index];

                    return ZapSplitUser(
                      key: ValueKey(zap.pubkey),
                      pubkey: zap.pubkey,
                      percentage: getPercentage(
                        zaps: zaps,
                        currentZap: zap,
                      ),
                      onRemove: () {
                        onRemoveZapSplitUser.call(zap.pubkey);
                      },
                      textFieldValue: zap.percentage.toString(),
                      onProportionChanged: (percentage) {
                        onSetZapProportions.call(index, zap, percentage);
                      },
                    );
                  },
                  itemCount: zaps.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int getPercentage({
    required List<ZapSplit> zaps,
    required ZapSplit currentZap,
  }) {
    if (zaps.isEmpty) {
      return 0;
    }

    num total = 0;
    zaps.forEach((zap) {
      total += zap.percentage;
    });

    if (total == 0) {
      return (100 / zaps.length).round();
    } else {
      return (currentZap.percentage * 100 / total).round();
    }
  }
}

class ZapSplitUser extends StatelessWidget {
  final String pubkey;
  final String textFieldValue;
  final int percentage;
  final Function(int) onProportionChanged;
  final Function() onRemove;

  const ZapSplitUser({
    Key? key,
    required this.pubkey,
    required this.textFieldValue,
    required this.percentage,
    required this.onProportionChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthorsCubit, AuthorsState>(
      builder: (context, state) {
        final author = state.authors[pubkey] ??
            emptyUserModel.copyWith(
              pubKey: pubkey,
              picturePlaceholder: getRandomPlaceholder(
                input: pubkey,
                isPfp: true,
              ),
            );
        return Container(
          child: Row(
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
                flex: 3,
                child: Text(
                  getAuthorName(author),
                ),
              ),
              Text(
                '% ${percentage}',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Flexible(
                flex: 1,
                child: TextFormField(
                  initialValue: textFieldValue,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    if (value.isEmpty) {
                      onProportionChanged.call(0);
                    } else {
                      onProportionChanged.call(int.tryParse(value) ?? 0);
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  onRemove.call();
                },
                icon: Icon(
                  Icons.close,
                  color: kRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
