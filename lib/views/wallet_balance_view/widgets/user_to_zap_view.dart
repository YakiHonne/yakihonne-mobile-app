// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/search_user_cubit/search_user_cubit.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/markdown/nostr_scheme.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class UserToZap extends HookWidget {
  final Function(UserModel) onUserSelected;

  UserToZap({
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();

    return BlocProvider(
      create: (context) => SearchUserCubit(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.40,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Column(
              children: [
                Center(
                  child: ModalBottomSheetHandle(),
                ),
                TextFormField(
                  controller: textEditingController,
                  onChanged: (search) async {
                    context.read<SearchUserCubit>().getAuthors(
                      search,
                      (user) {
                        onUserSelected.call(user);
                      },
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'search',
                    prefixIcon: Icon(
                      Icons.search,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        textEditingController.clear();
                        context.read<SearchUserCubit>().emptyAuthorsList();
                      },
                      icon: Icon(Icons.close),
                    ),
                  ),
                ),
                SizedBox(height: kDefaultPadding / 2),
                Expanded(
                  child: BlocBuilder<SearchUserCubit, SearchUserState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return SearchLoading();
                      } else if (state.authors.isEmpty) {
                        return EmptyList(
                          description: 'No users can be found',
                          icon: FeatureIcons.user,
                        );
                      }
                      return ListView.builder(
                        itemBuilder: (context, index) {
                          final author = state.authors[index];

                          return ArticleUserMention(
                            author: author,
                            onClicked: () {
                              onUserSelected.call(author);
                            },
                          );
                        },
                        itemCount: state.authors.length,
                      );
                    },
                  ),
                ),
                SizedBox(height: kDefaultPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
