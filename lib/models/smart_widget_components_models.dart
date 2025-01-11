// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/poll_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

abstract class SmartWidgetComponent {
  String id;

  SmartWidgetComponent({
    required this.id,
  });

  Map<String, dynamic> toMap();
}

MapEntry<String, List<SmartWidgetTemplate>> parseSmartWidgetsTemplates(
  String type,
  Map<String, dynamic> qds,
) {
  List<SmartWidgetTemplate> smartWidgetTemplates = [];
  for (final item in qds.entries) {
    smartWidgetTemplates.add(
      SmartWidgetTemplate(
        title: item.key,
        description: item.value['description'],
        thumbnail: item.value['thumbnail'],
        smartWidgetContainer:
            SmartWidgetContainer.smartWidgetContrainerfromString(
          item.value['content'],
        )!,
      ),
    );
  }
  return MapEntry(type, smartWidgetTemplates);
}

class SWAutoSaveModel {
  final String id;
  final Map<String, dynamic> content;
  final String title;
  final String description;

  SWAutoSaveModel({
    required this.id,
    required this.content,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'content': content,
      'title': title,
      'description': description,
    };
  }

  factory SWAutoSaveModel.fromMap(Map<String, dynamic> map) {
    return SWAutoSaveModel(
      id: map['id'] as String,
      content: map['content'],
      title: map['title'] as String,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SWAutoSaveModel.fromJson(String source) =>
      SWAutoSaveModel.fromMap(json.decode(source) as Map<String, dynamic>);

  SWAutoSaveModel copyWith({
    String? id,
    Map<String, dynamic>? content,
    String? title,
    String? description,
  }) {
    return SWAutoSaveModel(
      id: id ?? this.id,
      content: content ?? this.content,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}

class SmartWidgetTemplate {
  final String title;
  final String description;
  final String thumbnail;
  final SmartWidgetContainer smartWidgetContainer;

  SmartWidgetTemplate({
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.smartWidgetContainer,
  });
}

class SmartWidgetModel extends Equatable {
  final String smartWidgetId;
  final String identifier;
  final String pubkey;
  final String title;
  final String summary;
  final DateTime createdAt;
  final DateTime publishedAt;
  final String client;
  final SmartWidgetContainer? container;
  final Map<String, dynamic> dataMap;

  SmartWidgetModel({
    required this.smartWidgetId,
    required this.identifier,
    required this.pubkey,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.publishedAt,
    required this.client,
    required this.container,
    required this.dataMap,
  });

  factory SmartWidgetModel.fromEvent(Event event) {
    String identifier = '';
    String title = '';
    String summary = '';
    String client = '';
    DateTime createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    DateTime publishedAt = createdAt;
    Map<String, dynamic> map = {};

    for (var tag in event.tags) {
      if (tag.first == 'd' && tag.length > 1 && identifier.isEmpty) {
        identifier = tag[1].trim();
      } else if (tag.first == 'client' && tag.length > 1) {
        client = tag[1];
      } else if (tag.first == 'summary' && tag.length > 1) {
        summary = tag[1];
      } else if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'published_at') {
        final time = tag[1].toString();
        if (time.isNotEmpty) {
          publishedAt = DateTime.fromMillisecondsSinceEpoch(
            (time.length <= 10
                ? num.parse(time).toInt() * 1000
                : num.parse(time).toInt()),
          );
        }
      }
    }

    try {
      map = jsonDecode(event.content);
    } catch (_) {}

    return SmartWidgetModel(
      smartWidgetId: event.id,
      identifier: identifier,
      pubkey: event.pubkey,
      title: title,
      summary: summary,
      createdAt: createdAt,
      publishedAt: publishedAt,
      client: client,
      dataMap: map,
      container:
          SmartWidgetContainer.smartWidgetContrainerfromString(event.content),
    );
  }

  @override
  List<Object?> get props => [
        smartWidgetId,
        identifier,
        pubkey,
        title,
        summary,
        createdAt,
        publishedAt,
        client,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'smartWidgetId': smartWidgetId,
      'identifier': identifier,
      'pubkey': pubkey,
      'title': title,
      'summary': summary,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'publishedAt': publishedAt.millisecondsSinceEpoch,
      'client': client,
      'container': jsonEncode(container?.toMap()),
      'dataMap': jsonEncode(dataMap),
    };
  }

  String toJson() => json.encode(toMap());

  factory SmartWidgetModel.fromMap(Map<String, dynamic> map) {
    return SmartWidgetModel(
      smartWidgetId: map['smartWidgetId'] as String,
      identifier: map['identifier'] as String,
      pubkey: map['pubkey'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      publishedAt:
          DateTime.fromMillisecondsSinceEpoch(map['publishedAt'] as int),
      client: map['client'] as String,
      container: map['container'] != null
          ? SmartWidgetContainer.smartWidgetContrainerfromString(
              map['container'])
          : null,
      dataMap: jsonDecode(map['dataMap']),
    );
  }

  factory SmartWidgetModel.fromJson(String source) =>
      SmartWidgetModel.fromMap(json.decode(source) as Map<String, dynamic>);

  String getNaddr() {
    List<int> charCodes = identifier.runes.toList();
    final special = charCodes.map((code) => code.toRadixString(16)).join('');

    return Nip19.encodeShareableEntity(
      'naddr',
      special,
      mandatoryRelays,
      pubkey,
      EventKind.SMART_WIDGET,
    );
  }
}

class SmartWidgetContainer extends SmartWidgetComponent {
  String? backgroundHex;
  String? borderColorHex;
  Map<String, SmartWidgetGrid> grids;
  String highlightedGrid;
  String highlightedComponent;
  List<MapEntry<String, dynamic>> allMapEntries = [];
  Map<String, dynamic> map;

  SmartWidgetContainer({
    required super.id,
    required this.highlightedComponent,
    required this.highlightedGrid,
    required this.grids,
    this.backgroundHex,
    this.borderColorHex,
    this.map = const {},
    this.allMapEntries = const [],
  });

  void addComponent({
    required SmartWidgetComponent frameComponent,
    String? horizontalGridId,
    bool? isLeftSide,
    int? index,
  }) {
    if (frameComponent is SmartWidgetGrid) {
      grids[frameComponent.id] = frameComponent;

      if (index != null) {
        final entries = grids.entries.toList();

        moveItem(
          entries,
          grids.length - 1,
          index + 1,
        );

        grids = Map.fromEntries(entries);
      }
    } else {
      final grid = grids[horizontalGridId];

      if (grid != null) {
        if (grid.layout == 1) {
          grid.leftSide[frameComponent.id] = frameComponent;
        } else {
          if (isLeftSide != null && isLeftSide) {
            grid.leftSide[frameComponent.id] = frameComponent;
          } else if (isLeftSide != null && !isLeftSide) {
            grid.rightSide[frameComponent.id] = frameComponent;
          }
        }
      }
    }
  }

  void moveComponent({
    required bool toBottom,
    required String componentId,
    String? horizontalGridId,
  }) {
    final grid = grids[componentId];

    if (grid != null) {
      updateMoveStatus(
        toBottom,
        componentId,
        grids,
        (map) {
          grids = Map.from(map);
        },
      );
    } else {
      final grid2 = grids[horizontalGridId];

      if (grid2 != null) {
        final list = grid2.leftSide[componentId];

        if (list != null) {
          updateMoveStatus(
            toBottom,
            componentId,
            grid2.leftSide,
            (map) {
              grid2.leftSide = Map.from(map);
            },
          );
        }

        final list2 = grid2.rightSide[componentId];

        if (list2 != null) {
          updateMoveStatus(
            toBottom,
            componentId,
            grid2.rightSide,
            (map) {
              grid2.rightSide = Map.from(map);
            },
          );
        }
      }
    }
  }

  void updateMoveStatus(
    bool toBottom,
    String componentId,
    Map<String, dynamic> map,
    Function(Map<String, dynamic>) onNewMap,
  ) {
    final currentIndex = map.keys.toList().indexOf(componentId);
    final entries = map.entries.toList();

    moveItem(
      entries,
      currentIndex,
      toBottom ? currentIndex + 1 : currentIndex - 1,
    );

    onNewMap.call(Map.fromEntries(entries));
  }

  void deleteComponent({
    required String componentId,
    String? horizontalGridId,
  }) {
    final grid = grids[componentId];

    if (grid != null) {
      grids.remove(componentId);
    } else {
      final grid2 = grids[horizontalGridId];

      if (grid2 != null) {
        grid2.leftSide.remove(componentId);
        grid2.rightSide.remove(componentId);
      }
    }
  }

  void updateComponent({
    required SmartWidgetComponent component,
  }) {
    if (id == component.id && component is SmartWidgetContainer) {
      backgroundHex = component.backgroundHex;
      borderColorHex = component.borderColorHex;
      grids = component.grids;
    } else {
      final grid = grids[component.id];
      if (grid != null) {
        grids[component.id] = component as SmartWidgetGrid;
      } else {
        for (final temp in grids.values) {
          if (temp.leftSide[component.id] != null) {
            temp.leftSide[component.id] = component;
          } else if (temp.rightSide[component.id] != null) {
            temp.rightSide[component.id] = component;
          }
        }
      }
    }
  }

  @override
  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> toBeAddedGrids = [];

    for (final e in grids.values) {
      if (e.leftSide.isNotEmpty || e.rightSide.isNotEmpty) {
        toBeAddedGrids.add(e.toMap());
      }
    }

    return {
      'background_color': backgroundHex,
      'border_color': borderColorHex,
      'components': toBeAddedGrids,
    };
  }

  bool canBeAdded() {
    bool canBeAdded = false;

    for (final e in grids.values) {
      if (e.leftSide.isNotEmpty || e.rightSide.isNotEmpty) {
        canBeAdded = true;
      }
    }

    return canBeAdded;
  }

  static SmartWidgetContainer? smartWidgetContrainerfromString(String content) {
    try {
      final map = jsonDecode(content);

      final bc = map['background_color'] as String?;
      final brc = map['border_color'] as String?;
      List<MapEntry<String, dynamic>> allMapEntries = [];

      for (final entry in map.entries) {
        allMapEntries.add(MapEntry(entry.key.toString(), entry.value));
      }

      return SmartWidgetContainer(
        id: Uuid().v4(),
        highlightedComponent: '',
        highlightedGrid: '',
        grids: gridsFromList(
          map['components'],
        ),
        backgroundHex: bc != null && bc.isNotEmpty ? bc : null,
        borderColorHex: brc != null && brc.isNotEmpty ? brc : null,
        allMapEntries: allMapEntries,
        map: map,
      );
    } catch (e) {
      return null;
    }
  }

  static SmartWidgetContainer? smartWidgetContrainerfromMap(
    Map<String, dynamic> map,
  ) {
    try {
      final bc = map['background_color'] as String?;
      final brc = map['border_color'] as String?;
      List<MapEntry<String, dynamic>> allMapEntries = [];

      for (final entry in map.entries) {
        allMapEntries.add(MapEntry(entry.key.toString(), entry.value));
      }

      return SmartWidgetContainer(
        id: Uuid().v4(),
        highlightedComponent: '',
        highlightedGrid: '',
        grids: gridsFromList(
          map['components'],
        ),
        backgroundHex: bc != null && bc.isNotEmpty ? bc : null,
        borderColorHex: brc != null && brc.isNotEmpty ? brc : null,
        allMapEntries: allMapEntries,
        map: map,
      );
    } catch (e) {
      return null;
    }
  }

  SmartWidgetContainer copyWith({
    String? backgroundHex,
    String? borderColorHex,
    Map<String, SmartWidgetGrid>? grids,
    String? highlightedGrid,
    String? highlightedComponent,
  }) {
    return SmartWidgetContainer(
      id: this.id,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      borderColorHex: borderColorHex ?? this.borderColorHex,
      grids: grids ?? this.grids,
      highlightedGrid: highlightedGrid ?? this.highlightedGrid,
      highlightedComponent: highlightedComponent ?? this.highlightedComponent,
    );
  }
}

Map<String, SmartWidgetGrid> gridsFromList(List list) {
  Map<String, SmartWidgetGrid> grids = {};

  for (final item in list) {
    final e = SmartWidgetGrid.fromMap(item);

    if (e != null) {
      grids[e.id] = e;
    }
  }

  return grids;
}

class SmartWidgetGrid extends SmartWidgetComponent {
  Map<String, SmartWidgetComponent> leftSide;
  Map<String, SmartWidgetComponent> rightSide;
  String division;
  int layout;
  List<MapEntry<String, dynamic>> allMapEntries = [];
  List<List<MapEntry<String, dynamic>>> leftMapEntries = [];
  List<List<MapEntry<String, dynamic>>> rightMapEntries = [];

  SmartWidgetGrid({
    required super.id,
    required this.leftSide,
    required this.rightSide,
    this.division = '1:1',
    this.layout = 1,
    this.allMapEntries = const [],
    this.leftMapEntries = const [],
    this.rightMapEntries = const [],
  });

  int getDivision(bool isFirst) {
    if (layout == 1 && isFirst) {
      return 1;
    } else {
      final splits = division.split(':');
      return int.tryParse(isFirst ? splits.first : splits.last) ?? 1;
    }
  }

  SmartWidgetGrid copyWith({
    Map<String, SmartWidgetComponent>? leftSide,
    Map<String, SmartWidgetComponent>? rightSide,
    String? division,
    int? layout,
  }) {
    return SmartWidgetGrid(
      id: this.id,
      leftSide: leftSide ?? this.leftSide,
      rightSide: rightSide ?? this.rightSide,
      division: division ?? this.division,
      layout: layout ?? this.layout,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'division': division,
      'layout': layout,
      'left_side': leftSide.values.map((e) => e.toMap()).toList(),
      'right_side': rightSide.values.map((e) => e.toMap()).toList(),
    };
  }

  static SmartWidgetComponent? getComponentFromMap(Map<String, dynamic> map) {
    try {
      if (map['type'] == 'button') {
        return SmartWidgetButton.fromMap(map['metadata']);
      } else if (map['type'] == 'text') {
        return SmartWidgetText.fromMap(map['metadata']);
      } else if (map['type'] == 'image') {
        return SmartWidgetImage.fromMap(map['metadata']);
      } else if (map['type'] == 'video') {
        return SmartWidgetVideo.fromMap(map['metadata']);
      } else if (map['type'] == 'zap-poll') {
        return SmartWidgetZapPoll.fromMap(map['metadata']);
      } else {
        return null;
      }
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  static SmartWidgetGrid? fromMap(Map<String, dynamic> map) {
    try {
      Map<String, SmartWidgetComponent> left = {};
      Map<String, SmartWidgetComponent> right = {};
      final ls = map['left_side'];
      if (ls != null) {
        for (final item in ls) {
          final e = getComponentFromMap(item);
          if (e != null) {
            left[e.id] = e;
          }
        }
      }

      final rs = map['right_side'];

      if (rs != null) {
        for (final item in rs) {
          final e = getComponentFromMap(item);
          if (e != null) {
            right[e.id] = e;
          }
        }
      }

      List<List<MapEntry<String, dynamic>>> leftEntries = [];
      List<List<MapEntry<String, dynamic>>> rightEntries = [];

      final leftList = map['left_side'];
      final rightList = map['right_side'];

      if (leftList is List) {
        for (final item in leftList) {
          if (item is Map<String, dynamic>) {
            leftEntries.add(item.entries.toList());
          }
        }
      }

      if (rightList is List) {
        for (final item in rightList) {
          if (item is Map<String, dynamic>) {
            rightEntries.add(item.entries.toList());
          }
        }
      }

      return SmartWidgetGrid(
        id: uuid.v4(),
        division: map['division'],
        layout: map['layout'],
        leftSide: left,
        rightSide: right,
        allMapEntries: map.entries.toList(),
        leftMapEntries: leftEntries,
        rightMapEntries: rightEntries,
      );
    } catch (e) {
      lg.i(e);
      return null;
    }
  }
}

class SmartWidgetButton extends SmartWidgetComponent {
  String text;
  SmartWidgetButtonType type;
  String url;
  String pubkey;
  String textColor;
  String buttonColor;

  SmartWidgetButton({
    required super.id,
    required this.text,
    required this.type,
    required this.url,
    required this.pubkey,
    required this.textColor,
    required this.buttonColor,
  });

  static SmartWidgetButton? fromMap(Map<String, dynamic> map) {
    try {
      final bc = map['background_color'] as String?;
      final tc = map['text_color'] as String?;

      return SmartWidgetButton(
        id: uuid.v4(),
        buttonColor: bc == null || bc.isEmpty ? kPurple.toHex() : bc,
        url: map['url'],
        text: map['content'],
        pubkey: map['pubkey'] ?? '',
        type: SmartWidgetButtonType.values.firstWhere(
          (element) => element.name.toLowerCase() == map['type'],
          orElse: () => SmartWidgetButtonType.Regular,
        ),
        textColor: tc == null || tc.isEmpty ? kWhite.toHex() : tc,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'button',
      'metadata': {
        'background_color': buttonColor,
        'content': text,
        'url': url,
        'type': type.name.toLowerCase(),
        'text_color': textColor,
        if (pubkey.isNotEmpty) 'pubkey': pubkey,
      },
    };
  }

  SmartWidgetButton copyWith({
    String? text,
    String? url,
    String? pubkey,
    String? textColor,
    String? buttonColor,
    SmartWidgetButtonType? type,
  }) {
    return SmartWidgetButton(
      id: this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      url: url ?? this.url,
      pubkey: pubkey ?? this.pubkey,
      textColor: textColor ?? this.textColor,
      buttonColor: buttonColor ?? this.buttonColor,
    );
  }
}

class SmartWidgetText extends SmartWidgetComponent {
  String text;
  TextSize? textSize;
  TextWeight? textWeight;
  String? textColor;

  SmartWidgetText({
    required super.id,
    required this.text,
    this.textSize,
    this.textColor,
    this.textWeight,
  });

  SmartWidgetText copyWith({
    String? text,
    TextSize? textSize,
    TextWeight? textWeight,
    String? textColor,
  }) {
    return SmartWidgetText(
      id: this.id,
      text: text ?? this.text,
      textSize: textSize ?? this.textSize,
      textWeight: textWeight ?? this.textWeight,
      textColor: textColor ?? this.textColor,
    );
  }

  static SmartWidgetText? fromMap(Map<String, dynamic> map) {
    try {
      final textSize = TextSize.values.firstWhere(
        (element) => element.name.toLowerCase() == map['size'],
        orElse: () => TextSize.Regular,
      );

      return SmartWidgetText(
        id: uuid.v4(),
        textWeight: textSize == TextSize.H1 || textSize == TextSize.H2
            ? TextWeight.Bold
            : TextWeight.values.firstWhere(
                (element) => element.name.toLowerCase() == map['weight'],
                orElse: () => TextWeight.Regular,
              ),
        textSize: textSize,
        text: map['content'],
        textColor: map['text_color'] ?? kWhite.toHex(),
      );
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'text',
      'metadata': {
        'weight': textWeight!.name.toLowerCase(),
        'size': textSize!.name.toLowerCase(),
        'content': text,
        'text_color': textColor,
      },
    };
  }
}

class SmartWidgetImage extends SmartWidgetComponent {
  String url;
  String aspectRatio;

  SmartWidgetImage({
    required super.id,
    required this.url,
    required this.aspectRatio,
  });

  SmartWidgetImage copyWith({
    String? image,
    String? aspectRatio,
  }) {
    return SmartWidgetImage(
      id: id,
      url: image ?? this.url,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  static SmartWidgetImage? fromMap(Map<String, dynamic> map) {
    try {
      return SmartWidgetImage(
        id: uuid.v4(),
        url: map['url'] ?? '',
        aspectRatio: map['aspect_ratio'] ?? '16:9',
      );
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': 'image',
      'metadata': {
        'url': url,
        'aspect_ratio': aspectRatio,
      },
    };
  }
}

class SmartWidgetVideo extends SmartWidgetComponent {
  String url;

  SmartWidgetVideo({
    required super.id,
    required this.url,
  });

  SmartWidgetVideo copyWith({
    String? url,
  }) {
    return SmartWidgetVideo(
      id: this.id,
      url: url ?? this.url,
    );
  }

  static SmartWidgetVideo? fromMap(Map<String, dynamic> map) {
    try {
      return SmartWidgetVideo(
        id: uuid.v4(),
        url: map['url'],
      );
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': 'video',
      'metadata': {
        'url': url,
      }
    };
  }
}

class SmartWidgetZapPoll extends SmartWidgetComponent {
  String content;
  String optionTextColor;
  String contentTextColor;
  String optionBackgroundColor;
  String optionForegroundColor;

  SmartWidgetZapPoll({
    required super.id,
    required this.optionTextColor,
    required this.contentTextColor,
    required this.optionBackgroundColor,
    required this.optionForegroundColor,
    required this.content,
  });

  String? getNevent() {
    final ev = Event.fromString(content);
    return ev?.id != null
        ? Nip19.encodeShareableEntity(
            'nevent',
            ev!.id,
            mandatoryRelays,
            ev.pubkey,
            ev.kind,
          )
        : null;
  }

  PollModel? getPollModel() {
    final event = Event.fromString(content);

    if (event != null) {
      return PollModel.fromEvent(event);
    }

    return null;
  }

  Future<Event?> getPollEvent(String value) async {
    final _cancel = BotToast.showLoading();
    try {
      Event? ev;
      if (value.isNotEmpty && value.startsWith('nevent')) {
        final d = Nip19.decodeShareableEntity(value);

        ev = await singleEventCubit.getEvenById(
          id: d['special'],
          isIdentifier: d['special'],
        );

        if (ev != null) {
          BotToastUtils.showSuccess('Zap poll was selected');
        } else {
          BotToastUtils.showError('Zap poll was not found');
        }
      } else {
        BotToastUtils.showError('Make sure you add nevent');
      }

      _cancel.call();
      return ev;
    } catch (_) {
      BotToastUtils.showError('Error occured while fetching event');
      _cancel.call();
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'type': 'zap-poll',
      'metadata': {
        'content': content,
        'content_text_color': contentTextColor,
        'options_text_color': optionTextColor,
        'options_background_color': optionBackgroundColor,
        'options_foreground_color': optionForegroundColor,
      }
    };

    return m;
  }

  static SmartWidgetZapPoll? fromMap(Map<String, dynamic> map) {
    try {
      return SmartWidgetZapPoll(
        id: uuid.v4(),
        optionTextColor: map['options_text_color'],
        contentTextColor: map['content_text_color'],
        optionBackgroundColor: map['options_background_color'],
        optionForegroundColor: map['options_foreground_color'],
        content: map['content'],
      );
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  SmartWidgetZapPoll copyWith({
    String? content,
    String? optionTextColor,
    String? contentTextColor,
    String? optionBackgroundColor,
    String? optionForegroundColor,
  }) {
    return SmartWidgetZapPoll(
      id: this.id,
      content: content ?? this.content,
      optionTextColor: optionTextColor ?? this.optionTextColor,
      contentTextColor: contentTextColor ?? this.contentTextColor,
      optionBackgroundColor:
          optionBackgroundColor ?? this.optionBackgroundColor,
      optionForegroundColor:
          optionForegroundColor ?? this.optionForegroundColor,
    );
  }
}
