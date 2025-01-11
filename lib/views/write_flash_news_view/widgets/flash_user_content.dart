// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:yakihonne/blocs/write_flash_news_cubit/flash_user_content_cubit/flash_user_content_cubit.dart';
import 'package:yakihonne/blocs/write_flash_news_cubit/write_flash_news_cubit.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class FlashUserContent extends StatelessWidget {
  const FlashUserContent({
    Key? key,
    required this.isArticles,
  }) : super(key: key);

  final bool isArticles;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlashUserContentCubit(
        isArticles: isArticles,
      )..initView(),
      child: Container(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.60,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              ModalBottomSheetHandle(),
              SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                '${isArticles ? 'My articles' : 'My curations'}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(
                height: kDefaultPadding / 2,
              ),
              Expanded(
                child:
                    BlocBuilder<FlashUserContentCubit, FlashUserContentState>(
                  buildWhen: (previous, current) =>
                      previous.isLoading != current.isLoading,
                  builder: (context, state) {
                    return getView(
                      context,
                      state.isLoading,
                      scrollController,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getView(
    BuildContext context,
    bool isLoading,
    ScrollController scrollController,
  ) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
        child: SpinKitThreeBounce(
          size: 25,
          color: Theme.of(context).primaryColorDark,
        ),
      );
    } else {
      return FlashContentList(
        scrollController: scrollController,
      );
    }
  }
}

class FlashContentList extends StatelessWidget {
  const FlashContentList({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashUserContentCubit, FlashUserContentState>(
      builder: (context, state) {
        if (state.isArticles && state.articles.isEmpty) {
          return EmptyList(
            description: 'You have no articles at this moment.',
            icon: FeatureIcons.selfArticles,
          );
        } else if (!state.isArticles && state.curations.isEmpty) {
          return EmptyList(
            description: 'You have no curations at this moment.',
            icon: FeatureIcons.selfCurations,
          );
        } else if (state.isArticles) {
          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(
              height: kDefaultPadding,
            ),
            controller: scrollController,
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            itemBuilder: (context, index) {
              final article = state.articles[index];

              return FlashContentContainer(
                image: article.image,
                placeholder: article.placeholder,
                title: article.title,
                onClicked: () {
                  context.read<WriteFlashNewsCubit>().setFlashNewsKindValue(
                        isArticle: true,
                        article: article,
                      );

                  BotToastUtils.showSuccess('Article has been selected');
                  Navigator.pop(context);
                },
              );
            },
            itemCount: state.articles.length,
          );
        } else {
          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(
              height: kDefaultPadding,
            ),
            controller: scrollController,
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            itemBuilder: (context, index) {
              final curation = state.curations[index];

              return FlashContentContainer(
                image: curation.image,
                placeholder: curation.placeHolder,
                title: curation.title,
                onClicked: () {
                  context.read<WriteFlashNewsCubit>().setFlashNewsKindValue(
                        isArticle: false,
                        curation: curation,
                      );
                  BotToastUtils.showSuccess('Curation has been selected');
                  Navigator.pop(context);
                },
              );
            },
            itemCount: state.curations.length,
          );
        }
      },
    );
  }
}

class FlashContentContainer extends StatelessWidget {
  const FlashContentContainer({
    Key? key,
    required this.image,
    required this.placeholder,
    required this.title,
    required this.onClicked,
  }) : super(key: key);

  final String image;
  final String placeholder;
  final String title;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Row(
        children: [
          ArticleThumbnail(
            image: image,
            placeholder: placeholder,
            width: 50,
            height: 50,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
          IconButton(
            onPressed: onClicked,
            icon: Icon(
              Icons.add_rounded,
            ),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity(
                horizontal: -2,
                vertical: -2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
