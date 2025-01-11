// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_article_cubit.dart';

class WriteArticleState extends Equatable {
  final ArticlePublishSteps articlePublishSteps;
  final String title;
  final String content;
  final File? localImage;
  final bool isLocalImage;
  final bool isImageSelected;
  final String imageLink;
  final String excerpt;
  final bool isSensitive;
  final List<String> keywords;
  final bool deleteDraft;
  final bool isDraft;
  final bool forwardedAsDraft;
  final List<String> suggestions;
  final List<String> selectedRelays;
  final List<String> totalRelays;
  final bool isZapSplitEnabled;
  final List<ZapSplit> zapsSplits;
  final bool tryToLoad;

  WriteArticleState({
    required this.articlePublishSteps,
    required this.title,
    required this.content,
    this.localImage,
    required this.isLocalImage,
    required this.isImageSelected,
    required this.imageLink,
    required this.excerpt,
    required this.isSensitive,
    required this.keywords,
    required this.deleteDraft,
    required this.isDraft,
    required this.forwardedAsDraft,
    required this.suggestions,
    required this.selectedRelays,
    required this.totalRelays,
    required this.isZapSplitEnabled,
    required this.zapsSplits,
    required this.tryToLoad,
  });

  @override
  List<Object> get props => [
        articlePublishSteps,
        title,
        content,
        excerpt,
        isSensitive,
        keywords,
        selectedRelays,
        isLocalImage,
        isImageSelected,
        imageLink,
        totalRelays,
        deleteDraft,
        isDraft,
        suggestions,
        forwardedAsDraft,
        tryToLoad,
        isZapSplitEnabled,
        zapsSplits,
      ];

  WriteArticleState copyWith({
    ArticlePublishSteps? articlePublishSteps,
    String? title,
    String? content,
    File? localImage,
    bool? isLocalImage,
    bool? isImageSelected,
    String? imageLink,
    String? excerpt,
    bool? isSensitive,
    List<String>? keywords,
    bool? deleteDraft,
    bool? isDraft,
    bool? forwardedAsDraft,
    List<String>? suggestions,
    List<String>? selectedRelays,
    List<String>? totalRelays,
    bool? isZapSplitEnabled,
    List<ZapSplit>? zapsSplits,
    bool? tryToLoad,
  }) {
    return WriteArticleState(
      articlePublishSteps: articlePublishSteps ?? this.articlePublishSteps,
      title: title ?? this.title,
      content: content ?? this.content,
      localImage: localImage ?? this.localImage,
      isLocalImage: isLocalImage ?? this.isLocalImage,
      isImageSelected: isImageSelected ?? this.isImageSelected,
      imageLink: imageLink ?? this.imageLink,
      excerpt: excerpt ?? this.excerpt,
      isSensitive: isSensitive ?? this.isSensitive,
      keywords: keywords ?? this.keywords,
      deleteDraft: deleteDraft ?? this.deleteDraft,
      isDraft: isDraft ?? this.isDraft,
      forwardedAsDraft: forwardedAsDraft ?? this.forwardedAsDraft,
      suggestions: suggestions ?? this.suggestions,
      selectedRelays: selectedRelays ?? this.selectedRelays,
      totalRelays: totalRelays ?? this.totalRelays,
      isZapSplitEnabled: isZapSplitEnabled ?? this.isZapSplitEnabled,
      zapsSplits: zapsSplits ?? this.zapsSplits,
      tryToLoad: tryToLoad ?? this.tryToLoad,
    );
  }
}
