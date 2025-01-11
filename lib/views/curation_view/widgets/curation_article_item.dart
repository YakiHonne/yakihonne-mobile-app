// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/muted_mark.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class CurationItem extends StatelessWidget {
  const CurationItem({
    Key? key,
    required this.isArticle,
    required this.pubkey,
    required this.image,
    required this.placeholder,
    required this.title,
    required this.createdAt,
    required this.muteKind,
    required this.index,
    required this.isMuted,
    required this.onClicked,
  }) : super(key: key);

  final bool isArticle;
  final String pubkey;
  final String image;
  final String placeholder;
  final String title;
  final DateTime createdAt;
  final String muteKind;
  final int index;
  final bool isMuted;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
      selector: (state) => state.authors[pubkey],
      builder: (context, user) {
        final author = user ??
            emptyUserModel.copyWith(
              pubKey: pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: pubkey, isPfp: true),
            );

        return GestureDetector(
          onTap: onClicked,
          behavior: HitTestBehavior.translucent,
          child: FadeInUp(
            duration: Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    spreadRadius: 0,
                  )
                ],
                borderRadius: BorderRadius.circular(
                  kDefaultPadding,
                ),
              ),
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: image.isEmpty
                        ? SizedBox(
                            child: NoMediaPlaceHolder(
                              isRound: true,
                              value: kDefaultPadding,
                              image: placeholder,
                              isError: true,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: image,
                            imageBuilder: (context, imageProvider) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    kDefaultPadding,
                                  ),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                            placeholder: (context, url) => NoMediaPlaceHolder(
                              isRound: true,
                              value: kDefaultPadding,
                              image: '',
                              isError: false,
                            ),
                            errorWidget: (context, url, error) =>
                                NoMediaPlaceHolder(
                              isRound: true,
                              value: kDefaultPadding,
                              image: placeholder,
                              isError: true,
                            ),
                          ),
                  ),
                  if (isMuted)
                    Positioned(
                      top: kDefaultPadding / 2,
                      right: kDefaultPadding / 2,
                      child: MutedMark(kind: muteKind),
                    ),
                  Positioned(
                    top: kDefaultPadding / 2,
                    left: kDefaultPadding / 2,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 2,
                              )
                            ],
                          ),
                          child: ProfilePicture2(
                            size: 30,
                            image: author.picture,
                            placeHolder: author.picturePlaceholder,
                            padding: 0,
                            strokeWidth: 1,
                            strokeColor: Theme.of(context).primaryColorDark,
                            onClicked: () {
                              openProfileFastAccess(
                                context: context,
                                pubkey: author.pubKey,
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        GestureDetector(
                          onTap: () {
                            BotToastUtils.showInformation(
                              'This is ${isArticle ? 'an article' : 'a video'}',
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isArticle ? kBlue : kOrange,
                              shape: BoxShape.circle,
                            ),
                            padding:
                                const EdgeInsets.all(kDefaultPadding / 3.5),
                            child: SvgPicture.asset(
                              isArticle
                                  ? FeatureIcons.selfArticles
                                  : FeatureIcons.videoOcta,
                              colorFilter: ColorFilter.mode(
                                kWhite,
                                BlendMode.srcIn,
                              ),
                              width: 18,
                              height: 18,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) => Container(
                      width: constraints.maxWidth,
                      margin: const EdgeInsets.only(top: 130),
                      decoration: BoxDecoration(
                        color: kBlack.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(kDefaultPadding),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                        vertical: kDefaultPadding / 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dateFormat2.format(createdAt)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: kOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          Text(
                            title.trim(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: kWhite,
                                  fontWeight: FontWeight.w800,
                                ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            maxLines: 4,
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'By: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        color: kWhite,
                                      ),
                                ),
                                TextSpan(
                                  text: getAuthorName(author),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        color: kLightPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
