import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/write_article_cubit/write_article_cubit.dart';
import 'package:yakihonne/utils/markdown/format_markdown.dart';
import 'package:yakihonne/utils/markdown/markdown_text_input.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/mark_down_widget.dart';

class ArticleContent extends HookWidget {
  const ArticleContent({
    super.key,
    required this.toggleArticleContent,
  });

  final bool toggleArticleContent;

  @override
  Widget build(BuildContext context) {
    final title = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.title,
    );

    final content = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.content,
    );

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return FadeInRight(
      duration: const Duration(milliseconds: 300),
      child: BlocConsumer<WriteArticleCubit, WriteArticleState>(
        listenWhen: (previous, current) =>
            previous.tryToLoad != current.tryToLoad,
        listener: (context, state) {
          title.text = state.title;
          content.text = state.content;
        },
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.all(isTablet ? 5.w : 0),
            child: toggleArticleContent
                ? MarkdownTextInput(
                    (content) {
                      context.read<WriteArticleCubit>().setContentText(content);
                    },
                    (title) {
                      context.read<WriteArticleCubit>().setTitleText(title);
                    },
                    title,
                    state.content,
                    label: 'Content of the article',
                    actions: MarkdownType.values,
                    textStyle: TextStyle(fontSize: 15),
                    controller: content,
                    maxLines:
                        ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                            ? 15
                            : 10,
                  )
                : Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding,
                            ),
                            child: BlocBuilder<WriteArticleCubit,
                                WriteArticleState>(
                              buildWhen: (previous, current) =>
                                  previous.title != current.title,
                              builder: (context, state) {
                                return Text(
                                  state.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                );
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: MarkDownWidget(
                            content: state.content,
                            onLinkClicked: (link) => openWebPage(url: link),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
