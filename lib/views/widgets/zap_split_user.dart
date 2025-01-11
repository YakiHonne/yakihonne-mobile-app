// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class ZapSplitUsers extends HookWidget {
  const ZapSplitUsers({
    required this.currentPubkeys,
    required this.onAddUser,
    required this.onRemoveUser,
  });

  final List<String> currentPubkeys;
  final Function(String) onAddUser;
  final Function(String) onRemoveUser;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    final authors = useState(<UserModel>[]);
    final pubkeysList = useState(currentPubkeys);

    return Container(
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.60,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(child: Center(child: ModalBottomSheetHandle())),
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
                child: TextFormField(
                  controller: textEditingController,
                  onChanged: (search) {
                    if (search.isEmpty) {
                      authors.value = [];
                    } else {
                      authors.value =
                          authorsCubit.getAuthorsByNameNip05(search);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
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

                  return ZapSplitUserContainer(
                    author: author,
                    isPresent: pubkeysList.value.contains(author.pubKey),
                    onRemoveUser: onRemoveUser,
                    pubkeysList: pubkeysList,
                    onAddUser: onAddUser,
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
      ),
    );
  }
}

class ZapSplitUserContainer extends StatelessWidget {
  const ZapSplitUserContainer({
    super.key,
    required this.author,
    required this.isPresent,
    required this.onRemoveUser,
    required this.pubkeysList,
    required this.onAddUser,
  });

  final UserModel author;
  final bool isPresent;
  final Function(String p1) onRemoveUser;
  final ValueNotifier<List<String>> pubkeysList;
  final Function(String p1) onAddUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
        border: Border.all(
          color: isPresent ? kGreen : kTransparent,
        ),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
      ),
      child: Row(
        children: [
          ProfilePicture2(
            image: author.picture,
            placeHolder: author.picturePlaceholder,
            size: 30,
            padding: 3,
            strokeWidth: 1,
            strokeColor: Theme.of(context).primaryColorDark,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.name.trim().isNotEmpty
                      ? author.name
                      : Nip19.encodePubkey(author.pubKey).nineCharacters(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (author.about.isNotEmpty)
                  Text(
                    author.about,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: kDimGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          BorderedIconButton(
            onClicked: () {
              if (isPresent) {
                onRemoveUser.call(author.pubKey);
                pubkeysList.value = [
                  ...pubkeysList.value..remove(author.pubKey)
                ];
              } else {
                onAddUser.call(author.pubKey);
                pubkeysList.value = [...pubkeysList.value..add(author.pubKey)];
              }
            },
            primaryIcon: !isPresent ? FeatureIcons.add : FeatureIcons.trash,
            borderColor: Theme.of(context).primaryColorLight,
            iconColor: kWhite,
            firstSelection: true,
            size: 40,
            secondaryIcon: FeatureIcons.trash,
            backGroundColor: !isPresent ? kGreen : kRed,
          ),
        ],
      ),
    );
  }
}
