// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pod_player/pod_player.dart';
import 'package:yakihonne/utils/string_inlineSpan.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/gallery_view/gallery_view.dart';
import 'package:yakihonne/views/widgets/seek_bar.dart';

class LinkPreviewer extends HookWidget {
  const LinkPreviewer({
    Key? key,
    required this.url,
    required this.onOpen,
    this.textStyle,
    this.isScreenshot,
    required this.urlType,
    this.checkType,
    this.inverseNoteColor,
  }) : super(key: key);

  final String url;
  final Function()? onOpen;
  final TextStyle? textStyle;
  final bool? isScreenshot;
  final UrlType urlType;
  final bool? checkType;
  final bool? inverseNoteColor;

  @override
  Widget build(BuildContext context) {
    if (checkType != null) {
      return FutureBuilder(
        future: getUrlType(url: url),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == UrlType.image) {
            return ImageDisplayer(
              link: url,
              isScreenshot: isScreenshot,
            );
          } else if (urlType == UrlType.audio) {
            return AudioDisplayer(
              url: url,
              inverseNoteColor: inverseNoteColor,
            );
          } else if (snapshot.hasData && snapshot.data == UrlType.video) {
            return CustomVideoPlayer(link: url);
          } else {
            return UrlDisplayer(
              url: url,
              onOpen: onOpen,
              textStyle: textStyle,
            );
          }
        },
      );
    } else {
      return Builder(
        builder: (context) {
          if (urlType == UrlType.image) {
            return ImageDisplayer(
              link: url,
              isScreenshot: isScreenshot,
            );
          } else if (urlType == UrlType.video) {
            return CustomVideoPlayer(link: url);
          } else if (urlType == UrlType.audio) {
            return AudioDisplayer(
              url: url,
              inverseNoteColor: inverseNoteColor,
            );
          } else {
            return UrlDisplayer(
              url: url,
              onOpen: onOpen,
              textStyle: textStyle,
            );
          }
        },
      );
    }
  }
}

class AudioDisplayer extends StatefulWidget {
  const AudioDisplayer({
    Key? key,
    this.inverseNoteColor,
    required this.url,
  }) : super(key: key);

  final bool? inverseNoteColor;
  final String url;

  @override
  State<AudioDisplayer> createState() => _AudioDisplayerState();
}

class _AudioDisplayerState extends State<AudioDisplayer>
    with WidgetsBindingObserver {
  final _player = AudioPlayer();
  final combinedController = StreamController<PositionData>();

  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(widget.url)));
      _player.positionStream.listen(
        (event) {
          combinedController.add(
            PositionData(
              _player.position,
              _player.bufferedPosition,
              _player.duration!,
            ),
          );
        },
      );
      _player.bufferedPositionStream.listen(
        (event) {
          combinedController.add(
            PositionData(
              _player.position,
              _player.bufferedPosition,
              _player.duration!,
            ),
          );
        },
      );
      _player.durationStream.listen(
        (event) {
          combinedController.add(
            PositionData(
              _player.position,
              _player.bufferedPosition,
              _player.duration!,
            ),
          );
        },
      );
    } on PlayerException catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: widget.inverseNoteColor != null
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).primaryColorLight,
      ),
      margin: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ControlButtons(_player),
          StreamBuilder<PositionData>(
            stream: combinedController.stream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return SeekBar(
                duration: positionData?.duration ?? Duration.zero,
                position: positionData?.position ?? Duration.zero,
                bufferedPosition:
                    positionData?.bufferedPosition ?? Duration.zero,
                onChangeEnd: _player.seek,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Opens volume slider dialog
        IconButton(
          icon: const Icon(
            Icons.volume_up,
          ),
          iconSize: 25,
          visualDensity: VisualDensity(vertical: -2),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "Adjust volume",
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: player.volume,
              stream: player.volumeStream,
              onChanged: player.setVolume,
            );
          },
        ),

        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            } else if (playing != true) {
              return IconButton(
                visualDensity: VisualDensity(vertical: -2),
                icon: const Icon(Icons.play_arrow),
                iconSize: 25,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                visualDensity: VisualDensity(vertical: -2),
                icon: const Icon(Icons.pause),
                iconSize: 25,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                visualDensity: VisualDensity(vertical: -2),
                icon: const Icon(Icons.replay),
                iconSize: 25,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),

        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            visualDensity: VisualDensity(vertical: -2),
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Adjust speed",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: player.speed,
                stream: player.speedStream,
                onChanged: player.setSpeed,
              );
            },
          ),
        ),
      ],
    );
  }
}

class UrlDisplayer extends HookWidget {
  UrlDisplayer({
    Key? key,
    required this.url,
    required this.onOpen,
    this.textStyle,
  }) : super(key: key);

  final String url;
  final Function()? onOpen;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onOpen?.call(),
      child: Text(
        url,
        style: textStyle ??
            Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: kOrange,
                ),
      ),
    );
  }
}

class ImageDisplayer extends StatelessWidget {
  const ImageDisplayer({
    Key? key,
    required this.link,
    this.isScreenshot,
  }) : super(key: key);

  final String link;
  final bool? isScreenshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: GalleryImageView(
            listImage: [CachedNetworkImageProvider(link)],
            seperatorColor: Theme.of(context).primaryColorLight,
            width: MediaQuery.of(context).size.width,
            boxFit: BoxFit.cover,
            imageDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff8E2DE2),
                  Color(0xff4B1248),
                ],
              ),
            ),
            onDownload: shareImage,
            height: 180,
          ),
        ),
      ),
    );
  }
}

class CustomVideoPlayer extends StatefulWidget {
  const CustomVideoPlayer({
    Key? key,
    required this.link,
    this.removePadding,
  }) : super(key: key);

  final String link;
  final bool? removePadding;
  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late final PodPlayerController controller;
  // late FlickManager flickManager;
  final ratio = 16 / 9;

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() {
    final type = ((widget.link.contains('youtu.be/') ||
                widget.link.contains('youtube.com/')) &&
            !widget.link.contains('channel'))
        ? VideosKinds.youtube
        : widget.link.contains('vimeo.com/')
            ? VideosKinds.vimeo
            : VideosKinds.regular;

    final playVideoFrom = type == VideosKinds.youtube
        ? PlayVideoFrom.youtube(widget.link)
        : type == VideosKinds.vimeo
            ? PlayVideoFrom.vimeo(widget.link.split('/').last)
            : PlayVideoFrom.network(widget.link);

    try {
      controller = PodPlayerController(
        playVideoFrom: playVideoFrom,
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: false,
          isLooping: false,
        ),
      )..initialise();
    } catch (e, stackTrace) {
      lg.i(stackTrace);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.removePadding != null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: kBlack,
          ),
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
          child: PodVideoPlayer(
            controller: controller,
            onVideoError: () {
              return AspectRatio(
                aspectRatio: ratio,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 20,
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      Text(
                        'Error while loading the video',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
            podProgressBarConfig: PodProgressBarConfig(
              circleHandlerRadius: 6,
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 3,
                vertical: kDefaultPadding / 4,
              ),
            ),
            matchFrameAspectRatioToVideo: true,
            matchVideoAspectRatioToFrame: true,
          ),
        ),
      ),
    );
  }
}
