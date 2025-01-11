// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/write_video_cubit/write_video_cubit.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';

class VideoContent extends HookWidget {
  const VideoContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final titleController = useTextEditingController(
        text: context.read<WriteVideoCubit>().state.title);
    final summaryController = useTextEditingController(
      text: context.read<WriteVideoCubit>().state.summary,
    );

    return BlocBuilder<WriteVideoCubit, WriteVideoState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            if (state.videoUrl.isEmpty)
              VideoSelectionContainer()
            else
              Stack(
                children: [
                  CustomVideoPlayer(link: state.videoUrl),
                  Positioned(
                    top: kDefaultPadding / 1.5,
                    left: kDefaultPadding / 4,
                    child: CustomIconButton(
                      onClicked: () {
                        context.read<WriteVideoCubit>().setUrl('');
                      },
                      icon: FeatureIcons.close,
                      size: 22,
                      backgroundColor: Theme.of(context).primaryColorLight,
                    ),
                  ),
                ],
              ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Title',
              ),
              maxLines: 1,
              onChanged: (text) {
                context.read<WriteVideoCubit>().setTitle(text);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              controller: summaryController,
              decoration: InputDecoration(
                hintText: 'Summary (Optional)',
              ),
              minLines: 4,
              maxLines: 4,
              onChanged: (text) {
                context.read<WriteVideoCubit>().setSummary(text);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
        );
      },
    );
  }
}

class VideoSelectionContainer extends HookWidget {
  const VideoSelectionContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final videoSourceType = useState<VideoSourceType?>(null);
    final videoUrlTextEditingController = useTextEditingController();

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Column(
        children: [
          if (videoSourceType.value == null) ...[
            Text(
              "Pick your video",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              'You can upload, paste a link or choose a kind 1063 nevent to your video.',
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: VideoPickChoice(
                      onClicked: () {
                        context.read<WriteVideoCubit>().selectAndUploadVideo();
                      },
                      icon: FeatureIcons.videoGallery,
                      title: 'Gallery',
                    ),
                  ),
                  VerticalDivider(
                    indent: kDefaultPadding / 2,
                    endIndent: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: VideoPickChoice(
                      onClicked: () {
                        videoSourceType.value = VideoSourceType.link;
                      },
                      icon: FeatureIcons.videoLink,
                      title: 'Link',
                    ),
                  ),
                  VerticalDivider(
                    indent: kDefaultPadding / 2,
                    endIndent: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: VideoPickChoice(
                      onClicked: () {
                        videoSourceType.value = VideoSourceType.kind1063;
                      },
                      icon: FeatureIcons.share,
                      title: 'File sharing',
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text(
                      videoSourceType.value == VideoSourceType.link
                          ? "Set up your link"
                          : 'Set up your nevent',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      videoSourceType.value == VideoSourceType.link
                          ? "Paste your link and submit it"
                          : 'Paste your kind 1063 nevent and submit it',
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    TextFormField(
                      controller: videoUrlTextEditingController,
                      decoration: InputDecoration(
                        hintText: videoSourceType.value == VideoSourceType.link
                            ? 'link...'
                            : 'nevent...',
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      maxLines: 1,
                      onChanged: (text) {
                        context.read<WriteVideoCubit>().setTitle(text);
                      },
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => videoSourceType.value = null,
                            child: Text(
                              'Cancel',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: kWhite,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: kRed,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              final url =
                                  videoUrlTextEditingController.text.trim();
                              if (url.isEmpty) {
                                BotToastUtils.showError(
                                  'Add a proper url/nevent',
                                );
                              } else {
                                if (videoSourceType.value ==
                                    VideoSourceType.link) {
                                  context.read<WriteVideoCubit>().setUrl(url);
                                } else {
                                  context
                                      .read<WriteVideoCubit>()
                                      .addFileMetadata(url);
                                }
                              }
                            },
                            child: Text(
                              'Submit',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: Theme.of(context).primaryColorLight,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }
}

class VideoPickChoice extends StatelessWidget {
  const VideoPickChoice({
    Key? key,
    required this.title,
    required this.icon,
    required this.onClicked,
  }) : super(key: key);

  final String title;
  final String icon;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked,
      child: Column(
        children: [
          SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
            width: 30,
            height: 30,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          )
        ],
      ),
    );
  }
}
