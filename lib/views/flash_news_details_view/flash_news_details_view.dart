import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/flash_news_details_cubit/flash_news_details_cubit.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/views/flash_news_details_view/widgets/flash_news_details_data.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';

class FlashNewsDetailsView extends StatelessWidget {
  const FlashNewsDetailsView({
    Key? key,
    required this.flashNews,
    this.trySearch,
  }) : super(key: key);

  static const routeName = '/FlashNewsDetailsView';
  static Route route(RouteSettings settings) {
    final list = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => FlashNewsDetailsView(
        flashNews: list[0] as MainFlashNews,
        trySearch: list.length > 1,
      ),
    );
  }

  final MainFlashNews flashNews;
  final bool? trySearch;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FlashNewsDetailsCubit(
            flashNews: flashNews,
          ),
          lazy: false,
        ),
      ],
      child: Scaffold(
        appBar: CustomAppBar(title: 'News details'),
        body: FlashNewsDetailsData(
          mainFlashNews: flashNews,
          trySearch: trySearch,
        ),
      ),
    );
  }
}
