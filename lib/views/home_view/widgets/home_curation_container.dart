// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

import '../../../nostr/nips/nips.dart';

class HomeCurationContainer extends StatelessWidget {
  const HomeCurationContainer({
    Key? key,
    required this.onClicked,
    required this.padding,
    required this.isBookmarked,
    required this.userStatus,
    required this.curation,
    this.isMuted,
  }) : super(key: key);

  final bool? isMuted;
  final Function() onClicked;
  final double padding;
  final bool isBookmarked;
  final UserStatus userStatus;
  final Curation curation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  child: curation.image.isEmpty
                      ? NoMediaPlaceHolder(
                          isError: true,
                          image: curation.placeHolder,
                          isRound: true,
                          value: kDefaultPadding,
                        )
                      : CachedNetworkImage(
                          imageUrl: curation.image,
                          errorWidget: (context, url, error) =>
                              NoMediaPlaceHolder(
                            isError: true,
                            image: curation.placeHolder,
                            isRound: true,
                            value: kDefaultPadding,
                          ),
                          imageBuilder: (context, imageProvider) {
                            return Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(
                                  kDefaultPadding,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                GestureDetector(
                  onTap: () {
                    BotToastUtils.showInformation(
                      'This curation contains ${curation.isArticleCuration() ? 'articles' : 'videos'}',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                      vertical: kDefaultPadding / 2,
                    ),
                    decoration: BoxDecoration(
                      color: curation.isArticleCuration()
                          ? kGreen
                          : kOrangeContrasted,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(kDefaultPadding),
                        bottomRight: Radius.circular(kDefaultPadding),
                      ),
                    ),
                    child: Text(
                      curation.isArticleCuration() ? 'Articles' : 'Videos',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kWhite,
                            height: 1,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    curation.title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: kWhite,
                          fontWeight: FontWeight.w800,
                        ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
                    selector: (state) => state.authors[curation.pubKey],
                    builder: (context, user) {
                      final author = user ??
                          emptyUserModel.copyWith(
                            pubKey: curation.pubKey,
                            picturePlaceholder: getRandomPlaceholder(
                              input: curation.pubKey,
                              isPfp: true,
                            ),
                          );

                      return Column(
                        children: [
                          Row(
                            children: [
                              ProfilePicture2(
                                size: 20,
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
                                width: kDefaultPadding / 4,
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        author.name.isEmpty
                                            ? Nip19.encodePubkey(
                                                curation.pubKey,
                                              ).substring(0, 10)
                                            : author.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              color: kWhite,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    DotContainer(
                                      color: kDimGrey,
                                      size: 3,
                                    ),
                                    Text(
                                      '${curation.eventsIds.length.toString().padLeft(2, '0')} ${curation.isArticleCuration() ? 'arts' : 'vids'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .copyWith(
                                            color: kOrange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 4,
                              ),
                              Text(
                                '${dateFormat2.format(curation.publishedAt)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      color: kDimGrey,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
