import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/markdown/nostr_scheme.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_details.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';

class DmUserSearch extends HookWidget {
  static const routeName = '/dmUserSearchView';

  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => DmUserSearch(),
    );
  }

  const DmUserSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    final authors = useState(<UserModel>[]);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'New message',
        notElevated: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            pinned: true,
            actions: [
              const SizedBox.shrink(),
            ],
            title: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Row(
                children: [
                  Text(
                    'To:',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: textEditingController,
                      onChanged: (search) async {
                        if (search.isEmpty) {
                          authors.value = [];
                        } else {
                          if (search.startsWith('npub')) {
                            final author = await authorsCubit
                                .getFutureAuthor(Nip19.decodePubkey(search));

                            if (author != null) {
                              authors.value = [author];
                            } else {
                              authors.value = [];
                            }
                          } else if (search.startsWith('nprofile')) {
                            final s = Nip19.decodeShareableEntity(search);
                            final auth = s['author'] as String?;

                            if (auth != null && auth.isNotEmpty) {
                              final author =
                                  await authorsCubit.getFutureAuthor(auth);

                              if (author != null) {
                                authors.value = [author];
                              } else {
                                authors.value = [];
                              }
                            }
                          } else if (search.length == 64) {
                            final author =
                                await authorsCubit.getFutureAuthor(search);

                            if (author != null) {
                              authors.value = [author];
                            } else {
                              authors.value = [];
                            }
                          } else {
                            authors.value =
                                authorsCubit.getAuthorsByNameNip05(search);
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'search by name, npub, nprofile',
                        prefixIcon: Icon(
                          Icons.search,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            textEditingController.clear();
                            authors.value = [];
                          },
                          icon: Icon(Icons.close),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: kDefaultPadding / 2),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            sliver: SliverList.builder(
              itemBuilder: (context, index) {
                final author = authors.value[index];

                return ArticleUserMention(
                  author: author,
                  onClicked: () {
                    context.read<DmsCubit>().updateReadedTime(
                          author.pubKey,
                        );

                    Navigator.pushNamed(
                      context,
                      DmDetails.routeName,
                      arguments: [
                        author.pubKey,
                      ],
                    );
                  },
                );
              },
              itemCount: authors.value.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: kDefaultPadding),
          ),
        ],
      ),
    );
  }
}
