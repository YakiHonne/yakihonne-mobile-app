// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'flash_user_content_cubit.dart';

class FlashUserContentState extends Equatable {
  final bool isLoading;
  final List<Article> articles;
  final List<Curation> curations;
  final bool isArticles;

  FlashUserContentState({
    required this.isLoading,
    required this.articles,
    required this.curations,
    required this.isArticles,
  });

  @override
  List<Object> get props => [
        isLoading,
        articles,
        curations,
        isArticles,
      ];

  FlashUserContentState copyWith({
    bool? isLoading,
    List<Article>? articles,
    List<Curation>? curations,
    bool? isArticles,
  }) {
    return FlashUserContentState(
      isLoading: isLoading ?? this.isLoading,
      articles: articles ?? this.articles,
      curations: curations ?? this.curations,
      isArticles: isArticles ?? this.isArticles,
    );
  }
}
