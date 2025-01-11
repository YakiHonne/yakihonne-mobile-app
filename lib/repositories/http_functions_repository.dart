import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart' as dioInstance;
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nip_044.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

Dio? _dio;

final yakiDioFormData = Dio(
  BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'yakihonne-api-key': dotenv.env['API_KEY'],
    },
    contentType: 'multipart/form-data',
  ),
);

class HttpFunctionsRepository {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Dio> getDio() async {
    if (_dio == null) {
      PersistCookieJar? cookieJar;
      Directory appDocDir;
      appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      cookieJar = PersistCookieJar(
        storage: FileStorage('$appDocPath/cookies'),
      );

      _dio = Dio();

      _dio!.options.headers['user-agent'] = 'Yakihonne';
      _dio!.options.headers['accept-encoding'] = 'gzip';
      _dio!.interceptors.add(CookieManager(cookieJar));
    }

    return _dio!;
  }

  static Dio getDio2() {
    final dio = Dio();
    dio.options.headers['accept-encoding'] = 'gzip, deflate, br';
    dio.options.headers['accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7';
    return dio;
  }

  static Future<UrlType> getUrlType(String link) async {
    try {
      var dio = await getDio();

      Response resp = await dio.get(link);
      if (resp.statusCode == 200) {
        final contentType = (resp.headers.map['content-Type']?.first ?? '');

        if (contentType.toLowerCase().startsWith('image')) {
          return UrlType.image;
        } else if (contentType.startsWith('video')) {
          return UrlType.video;
        } else if (contentType.startsWith('audio')) {
          return UrlType.audio;
        } else {
          return UrlType.text;
        }
      } else {
        return UrlType.text;
      }
    } catch (_) {
      return UrlType.text;
    }
  }

  static Future<Map<String, dynamic>?> get(
    String link, [
    Map<String, dynamic>? queryParameters,
    Map<String, String>? header,
  ]) async {
    var dio = await getDio();

    if (header != null) {
      dio.options.headers.addAll(header);
    }

    try {
      Response resp = await dio.get(link, queryParameters: queryParameters);

      if (resp.statusCode == 200) {
        if (resp.data is String) {
          final data = json.decode(resp.data);

          return data;
        }

        return resp.data is Map ? resp.data : {'data': resp.data};
      } else {
        return null;
      }
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
    }

    return null;
  }

  static Future<double> getUserReceivedZaps(String pubkey) async {
    try {
      final response = await HttpFunctionsRepository.get(
          '$nostrBandURl${'stats/profile/'}$pubkey');

      return (response?['stats']?[pubkey]?['zaps_sent']?['msats'] ?? 0) / 1000;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<Event>> getTrendingNotes() async {
    try {
      final response =
          await HttpFunctionsRepository.get('$nostrBandURl${'trending/notes'}');

      if (response?['notes'] != null) {
        final notesMap = (response!['notes'] as List);
        List<Event> events = [];

        for (final note in notesMap) {
          final evMap = note['event'];

          if (evMap != null) {
            final ev = Event.fromJson(evMap);
            if (!nostrRepository.mutes.contains(ev.pubkey)) {
              events.add(ev);
            }
          }
        }

        return events;
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<dynamic> getSpecified(
    String link, [
    Map<String, dynamic>? queryParameters,
    Map<String, String>? header,
  ]) async {
    var dio = await getDio();

    if (header != null) {
      dio.options.headers.addAll(header);
    }

    try {
      Response resp = await dio.get(
        link,
        queryParameters: queryParameters,
      );

      if (resp.statusCode == 200) {
        return resp.data;
      } else {
        return null;
      }
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
    }

    return null;
  }

  static Future<Map<String, String>> uploadVideo({
    required File file,
  }) async {
    try {
      Map<String, dynamic> userMap = {};

      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last;
      userMap['file'] = await dioInstance.MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      if (nostrRepository.usedUploadServer == UploadServers.YAKIHONNE) {
        userMap['pubkey'] = nostrRepository.usm!.pubKey;

        final data = dioInstance.FormData.fromMap(
          userMap,
        );

        final response = await yakiDioFormData.post(
          uploadUrl,
          data: data,
        );

        return {
          'url': response.data['image_path'],
          'm': 'video/$extension',
        };
      } else {
        final data = dioInstance.FormData.fromMap(
          userMap,
        );

        final event = await Event.genEvent(
          kind: EventKind.HTTP_AUTH,
          tags: [
            ['u', 'https://nostr.build/api/v2/nip96/upload'],
            ['method', 'POST'],
          ],
          content: '',
          pubkey: nostrRepository.usm!.pubKey,
          privkey: nostrRepository.usm!.privKey,
        );

        if (event == null) {
          BotToastUtils.showError(
            'Error occured while signing the authentication event.',
          );

          return {};
        }

        final bytes = utf8.encode(event.toJsonString());
        final base64Str = base64.encode(bytes);

        final diverseDioFormData = Dio(
          BaseOptions(
            contentType: 'multipart/form-data',
            baseUrl: 'https://nostr.build',
            headers: {
              'Authorization': 'Nostr $base64Str',
            },
          ),
        );

        final response = await diverseDioFormData.post(
          '/api/v2/nip96/upload',
          data: data,
        );

        if (response.data['status'] == 'success') {
          final tags = response.data['nip94_event']['tags'] as List?;
          if (tags != null && tags.isNotEmpty) {
            String url = '';
            String mimeType = '';

            for (final tag in tags) {
              final firstElement = (tag as List).first;

              if (firstElement == 'url') {
                url = tag[1];
              } else if (firstElement == 'm') {
                mimeType = tag[1];
              }
            }

            if (url.isNotEmpty) {
              return {
                'm': mimeType,
                'url': url,
              };
            }

            BotToastUtils.showError('Video could not be uploaded');
            return {};
          } else {
            BotToastUtils.showError('Video could not be uploaded');
            return {};
          }
        } else {
          BotToastUtils.showError('Video could not be uploaded');
          return {};
        }
      }
    } on DioException catch (e) {
      lg.i(e.response);
      BotToastUtils.showError('Error occured while uploading the media');
      return {};
    }
  }

  static Future<String?> uploadMedia({
    required File file,
  }) async {
    try {
      Map<String, dynamic> userMap = {};

      final fileName = file.path.split('/').last;

      userMap['file'] = await dioInstance.MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      if (nostrRepository.usedUploadServer == UploadServers.YAKIHONNE) {
        userMap['pubkey'] = nostrRepository.usm!.pubKey;

        final data = dioInstance.FormData.fromMap(
          userMap,
        );

        final response = await yakiDioFormData.post(
          uploadUrl,
          data: data,
        );

        return response.data['image_path'];
      } else {
        final data = dioInstance.FormData.fromMap(
          userMap,
        );

        final event = await Event.genEvent(
          kind: EventKind.HTTP_AUTH,
          tags: [
            ['u', 'https://nostr.build/api/v2/nip96/upload'],
            ['method', 'POST'],
          ],
          content: '',
          pubkey: nostrRepository.usm!.pubKey,
          privkey: nostrRepository.usm!.privKey,
        );

        if (event == null) {
          BotToastUtils.showError(
            'Error occured while signing the authentication event.',
          );

          return null;
        }

        final bytes = utf8.encode(event.toJsonString());
        final base64Str = base64.encode(bytes);

        final diverseDioFormData = Dio(
          BaseOptions(
            contentType: 'multipart/form-data',
            baseUrl: 'https://nostr.build',
            headers: {
              'Authorization': 'Nostr $base64Str',
            },
          ),
        );

        final response = await diverseDioFormData.post(
          '/api/v2/nip96/upload',
          data: data,
        );

        if (response.data['status'] == 'success') {
          final tags = response.data['nip94_event']['tags'] as List?;
          if (tags != null && tags.isNotEmpty) {
            for (final tag in tags) {
              if ((tag as List).first == 'url') {
                return tag[1];
              }
            }

            BotToastUtils.showError('File could not be uploaded');
            return null;
          } else {
            BotToastUtils.showError('File could not be uploaded');
            return null;
          }
        } else {
          BotToastUtils.showError('File could not be uploaded');
          return null;
        }
      }
    } on DioException catch (e) {
      lg.i(e.response);
      BotToastUtils.showError('Error occured while uploading the media');
      return null;
    }
  }

  static Future<String?> getStr(
    String link, [
    Map<String, dynamic>? queryParameters,
    Map<String, String>? header,
  ]) async {
    var dio = await getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    try {
      Response resp =
          await dio.get<String>(link, queryParameters: queryParameters);
      if (resp.statusCode == 200) {
        return resp.data;
      } else {
        return null;
      }
    } on DioException catch (ex) {
      if (kDebugMode) {
        print(ex.error);
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> post(
    String link,
    Map<String, dynamic> parameters, [
    Map<String, String>? header,
  ]) async {
    try {
      var dio = await getDio();
      if (header != null) {
        dio.options.headers.addAll(header);
      }

      Response resp = await dio.post(link, data: parameters);
      return resp.data;
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      return null;
    }
  }

  //** Alby api */
  static Future<Map<String, dynamic>> handleAlbyApiToken({
    required String code,
    required bool isRefreshing,
  }) async {
    try {
      final dio = await getDio();
      final clientId = dotenv.env['CLIENT_ID']!;
      final clientSecret = dotenv.env['CLIENT_SECRET']!;
      final basicAuth =
          'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret'));

      final data = dioInstance.FormData.fromMap(
        {
          'grant_type': isRefreshing ? 'refresh_token' : 'authorization_code',
          if (!isRefreshing) 'code': code,
          if (!isRefreshing) 'redirect_uri': albyRedirectUri,
          if (isRefreshing) 'refresh_token': code,
        },
      );

      final response = await dio.post(
        'https://api.getalby.com/oauth/token',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
          contentType: Headers.multipartFormDataContentType,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        return {
          'token': response.data['access_token'],
          'refreshToken': response.data['refresh_token'],
          'expiresIn': response.data['expires_in'],
          'createdAt': currentUnixTimestampSeconds(),
        };
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static Future<String> getAlbyLightningAddress({
    required String token,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.get(
        'https://api.getalby.com/user/me',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['lightning_address'];
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  static Future<num> getAlbyBalance({
    required String token,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.get(
        'https://api.getalby.com/balance',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['balance'];
      } else {
        return -1;
      }
    } catch (e) {
      return -1;
    }
  }

  static Future<List<WalletTransactionModel>> getAlbyTransactions({
    required String token,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.get(
        'https://api.getalby.com/invoices',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
      );

      if (response.statusCode == 200) {
        return getAlbyWalletTransactions(response.data);
      } else {
        return <WalletTransactionModel>[];
      }
    } catch (e) {
      return <WalletTransactionModel>[];
    }
  }

  static Future<String?> getAlbyInvoice({
    required String token,
    required int amount,
    required String message,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.post(
        'https://api.getalby.com/invoices',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
        data: {
          'amount': amount,
          if (message.isNotEmpty) 'comment': message,
          if (message.isNotEmpty) 'description': message,
          if (message.isNotEmpty) 'memno': message
        },
      );

      return response.data['payment_request'];
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  static Future<Map<String, dynamic>> sendAlbyPayment({
    required String token,
    required String invoice,
  }) async {
    try {
      final dio = await getDio();
      final basicAuth = 'Bearer $token';

      final response = await dio.post(
        'https://api.getalby.com/payments/bolt11',
        options: Options(
          headers: {
            'Authorization': basicAuth,
          },
        ),
        data: {
          'invoice': invoice,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    } catch (e) {
      lg.i(e);
      return {};
    }
  }

  //** user nip05 validity */
  static Future<bool> checkNip05Validity({
    required String domain,
    required String name,
    required String pubkey,
  }) async {
    try {
      final link = 'https://$domain/.well-known/nostr.json?name=$name';
      final response = await get(link);

      return response != null
          ? ((response['names'] as Map?)?[name] == pubkey)
          : false;
    } catch (e) {
      return false;
    }
  }

  // * important flash news /
  static Future<List<MainFlashNews>> getImportantFlashnews() async {
    try {
      final response = await getSpecified('${cacheUrl}mb/flashnews/important');

      if (response != null) {
        return mainFlashNewsFromJson(response);
      } else {
        return <MainFlashNews>[];
      }
    } catch (e) {
      rethrow;
    }
  }

  // * Ai feed /
  static Future<List<BuzzFeedSource>> getBuzzFeedSources() async {
    try {
      final response = await getSpecified('${cacheUrl}af-sources');

      if (response != null) {
        return aiFeedSourcesFromArray(response);
      } else {
        return <BuzzFeedSource>[];
      }
    } catch (e) {
      lg.i(e);
      rethrow;
    }
  }

  // * Uncensored notes end points /
  static Future<num> getBalance() async {
    try {
      final response = await getSpecified('${cacheUrl}balance');

      if (response != null) {
        return response['balance'];
      } else {
        return 0;
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, num>> getImpacts(String pubkey) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}user-impact',
        {'pubkey': pubkey},
      );

      if (response != null) {
        return {
          'writing': response['writing_impact']['writing_impact'],
          'positiveWriting': response['writing_impact']
              ['positive_writing_impact'],
          'negativeWriting': response['writing_impact']
              ['negative_writing_impact'],
          'ongoingWriting': response['writing_impact']
              ['ongoing_writing_impact'],
          'rating': response['rating_impact']['rating_impact'],
          'positiveRatingH': response['rating_impact']
              ['positive_rating_impact_h'],
          'positiveRatingNh': response['rating_impact']
              ['positive_rating_impact_nh'],
          'negativeRatingNh': response['rating_impact']
              ['negative_rating_impact_nh'],
          'negativeRatingH': response['rating_impact']
              ['negative_rating_impact_h'],
          'ongoingRating': response['rating_impact']
              ['positive_rating_impact_nh'],
        };
      } else {
        return {
          'writing': 0,
          'rating': 0,
        };
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getFlashNews({
    required DateTime date,
    required int page,
  }) async {
    try {
      final searchMap = {
        'from': DateTime(
          date.year,
          date.month,
          date.day,
        ).toSecondsSinceEpoch(),
        'to': DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          59,
        ).toSecondsSinceEpoch(),
        'elPerPage': 6,
        'page': page,
      };

      final response = await getSpecified(
        '${cacheUrl}mb/flashnews-v2',
        searchMap,
      );

      final mains = mainFlashNewsFromJson(response['flashnews']);
      authorsCubit.getAuthors(mains.map((e) => e.flashNews.pubkey).toList());

      return {
        'total': response['total'],
        'flashnews': mains,
      };
    } catch (e) {
      lg.i(e);
      rethrow;
    }
  }

  static Future<List<RewardModel>> getRewards(String pubkey) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}my-rewards',
        {'pubkey': pubkey},
      );

      if (response != null) {
        return rewardFromJson(response);
      } else {
        return <RewardModel>[];
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<UserModel>> getUsers(String search) async {
    try {
      final response = await getSpecified('${cacheUrl}users/search/$search');
      if (response != null) {
        List<UserModel> users = [];

        for (final item in response) {
          try {
            final random = getRandomPlaceholder(
              input: item['pubkey'] ?? 'default',
              isPfp: true,
            );

            final user = UserModel(
              pubKey: item['pubkey'],
              name: item['display_name'] == null ||
                      (item['display_name'] as String).isEmpty
                  ? item['name'] ?? ''
                  : item['display_name'],
              displayName: item['display_name'] ?? '',
              about: item['about'] ?? '',
              picture: item['picture'] ?? '',
              banner: item['banner'] ?? '',
              website: item['website'] ?? '',
              nip05: item['nip05'] ?? '',
              lud16: item['lud16'] ?? '',
              lud06: item['lud06'] ?? '',
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                  item['created_at'] * 1000),
              followings: [],
              isDeleted: item['deleted'] ?? false,
              bannerPlaceholder: random,
              picturePlaceholder: random,
            );

            users.add(
              user,
            );
          } catch (_) {
            lg.i(_);
          }
        }

        return users;
      } else {
        return <UserModel>[];
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> loginPointsSystem() async {
    try {
      final currentUserPubkey = nostrRepository.usm!.pubKey;

      final map = {
        'pubkey': currentUserPubkey,
        'sent_at': DateTime.now().toSecondsSinceEpoch(),
      };

      final encryptedContent = await Nip44.encryptContent(
        json.encode(map),
        'db48fbfb9f89b2870bcfd96cb1d283af6da999dde248b9bed6660f3c1e591380',
        currentUserPubkey,
        nostrRepository.usm!.privKey,
      );

      final response = await post(
        '${pointsUrl}login',
        {
          'pubkey': currentUserPubkey,
          'password': encryptedContent,
        },
      );

      final actions =
          List<PointAction>.from((response?['actions'] as List? ?? []).map(
        (e) => PointAction.fromMap(e),
      ));

      Map<String, PointStandard> standards = {};
      (response?['platform_standards'] as Map? ?? {}).forEach(
        (key, value) => standards[key] =
            PointStandard.fromMap(mapEntry: MapEntry(key, value)),
      );

      final xp = response?['xp'];

      if (response?['is_new'] ?? false) {
        return {
          'isNew': true,
          'actions': actions,
          'standards': standards,
          'xp': xp,
        };
      } else if ((response?['message'] as String?)?.isNotEmpty ?? false) {
        return {};
      } else {
        return null;
      }
    } on DioException catch (e) {
      lg.i(e.response);
      return null;
    }
  }

  static Future<bool> sendActionThroughEvent(Event event) async {
    try {
      String action = '';

      if (event.kind == EventKind.CATEGORIZED_BOOKMARK) {
        action = PointsActions.BOOKMARK;
      } else if (event.kind == EventKind.TEXT_NOTE) {
        if (event.isFlashNews()) {
          action = PointsActions.FLASHNEWS_POST;
        } else if (event.isUncensoredNote()) {
          action = PointsActions.UN_WRITE;
        } else if (event.isReply()) {
          action = PointsActions.COMMENT_POST;
        }
      } else if (event.isVideo()) {
        action = PointsActions.VIDEO_POST;
      } else if (event.isRelaysList()) {
        action = PointsActions.RELAYS_SETUP;
      } else if (event.isFollowingYakihonne()) {
        action = PointsActions.FOLLOW_YAKI;
      } else if (event.isLongForm()) {
        action = PointsActions.ARTICLE_POST;
      } else if (event.isLongFormDraft()) {
        action = PointsActions.ARTICLE_DRAFT;
      } else if (event.isCuration()) {
        action = PointsActions.CURATION_POST;
      } else if (event.isUnRate()) {
        action = PointsActions.UN_RATE;
      } else if (event.isTopicEvent()) {
        action = PointsActions.TOPICS_SETUP;
      } else if (event.kind == EventKind.REACTION) {
        action = PointsActions.reaction;
      }

      if (action.isNotEmpty) {
        return sendAction(action);
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendAction(String action) async {
    try {
      final resp = await post('${pointsUrl}yaki-chest', {
        'action_key': action,
      });

      if (resp != null) {
        final update = resp['is_updated'];

        if (update != null && update is! bool) {
          BotToastUtils.showSuccess(
            'You are rewarded ${update['points']} points',
          );
        }

        final userStats = UserGlobalStats.fromMap(resp);
        pointsManagementCubit.setUserStats(userStats);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> logoutPointsSystem() async {
    try {
      await post('${pointsUrl}logout', {});

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<UserGlobalStats?> getUserStats() async {
    try {
      final response = await get('${pointsUrl}yaki-chest/stats');

      if (response != null) {
        return UserGlobalStats.fromMap(response);
      } else {
        return null;
      }
    } catch (e, s) {
      lg.i(s);
      return null;
    }
  }

  static Future<List<dynamic>> getRewardsPrices() async {
    try {
      final response = await getSpecified(
        '${cacheUrl}pricing',
      );

      if (response != null) {
        return response;
      } else {
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> claimReward({
    required String encodedMessage,
    required String pubkey,
  }) async {
    try {
      final response = await post(
        '${cacheUrl}reward-claiming',
        {
          'pubkey': pubkey,
          '_data': encodedMessage,
        },
      );

      return response != null;
    } catch (e) {
      rethrow;
    }
  }

  static Future<UnFlashNews?> getUnFlashNews(
    String id,
  ) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}flashnews/$id',
      );

      if (response != null) {
        return UnFlashNews.fromMap2(response);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<List<UnFlashNews>> getNewFlashnews(
    String extension,
    int page,
  ) async {
    try {
      final response = await getSpecified(
        '${cacheUrl}flashnews/$extension',
        {
          "page": page,
          "elPerPage": kElPerPage2,
        },
      );

      if (response != null) {
        return newFNListFromJson(response['flashnews']);
      } else {
        return <UnFlashNews>[];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getUncensoredNotes({
    required String flashNewsId,
  }) async {
    try {
      final response = await getSpecified('${cacheUrl}flashnews/$flashNewsId');

      if (response == null) {
        return {
          'notes': <UncensoredNote>[],
          'notHelpful': <SealedNote>[],
        };
      }

      List<SealedNote> notHelpful = [];
      final notHelpfulResponse = response['sealed_not_helpful_notes'];

      if (notHelpfulResponse != null) {
        notHelpful = (notHelpfulResponse as List? ?? <SealedNote>[])
            .map((e) => SealedNote.fromMap(e))
            .toList();
      }

      return {
        'notes': uncensoredNotesFromJson(
          notes: response['uncensored_notes'],
          flashNewsId: flashNewsId,
        ),
        'notHelpful': notHelpful.isEmpty ? <SealedNote>[] : notHelpful,
        if (response['sealed_note'] != null)
          'sealed': SealedNote.fromMap(response['sealed_note']),
      };
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, SealedNote>> getSealedNotesByIds({
    required List<String> flashNewsIds,
  }) async {
    try {
      Map<String, SealedNote> sealedNotes = {};
      final response = await getSpecified(
        '${cacheUrl}flashnews/mb/bundle',
        {
          'flashnews_ids': flashNewsIds,
        },
      );

      if (response == null) {
        return <String, SealedNote>{};
      }

      for (final flashNews in response) {
        if (flashNews['sealed_note'] != null) {
          final sealed = SealedNote.fromMap(flashNews['sealed_note']);

          sealedNotes[sealed.flashNewsId] = sealed;
        }
      }

      return sealedNotes;
    } catch (e) {
      lg.i(e);
      rethrow;
    }
  }

  static Future<String> uploadImage({
    required File file,
    required String? pubKey,
  }) async {
    try {
      Map<String, dynamic> userMap = {};
      final fileName = file.path.split('/').last;

      userMap['file'] = await dioInstance.MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      if (nostrRepository.usedUploadServer == UploadServers.YAKIHONNE) {
        if (pubKey != null) {
          userMap['pubkey'] = pubKey;
        }

        final fileName = file.path.split('/').last;

        userMap['file'] = await dioInstance.MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );

        final data = dioInstance.FormData.fromMap(
          userMap,
        );

        final response = await yakiDioFormData.post(
          uploadUrl,
          data: data,
        );

        return response.data['image_path'];
      } else {
        final data = dioInstance.FormData.fromMap(
          userMap,
        );

        final event = await Event.genEvent(
          kind: EventKind.HTTP_AUTH,
          tags: [
            ['u', 'https://nostr.build/api/v2/nip96/upload'],
            ['method', 'POST'],
          ],
          content: '',
          pubkey: nostrRepository.usm!.pubKey,
          privkey: nostrRepository.usm!.privKey,
        );

        if (event == null) {
          BotToastUtils.showError(
            'Error occured while signing the authentication event.',
          );

          return '';
        }

        final bytes = utf8.encode(event.toJsonString());
        final base64Str = base64.encode(bytes);

        final diverseDioFormData = Dio(
          BaseOptions(
            contentType: 'multipart/form-data',
            baseUrl: 'https://nostr.build',
            headers: {
              'Authorization': 'Nostr $base64Str',
            },
          ),
        );

        final response = await diverseDioFormData.post(
          '/api/v2/nip96/upload',
          data: data,
        );

        if (response.data['status'] == 'success') {
          final tags = response.data['nip94_event']['tags'] as List?;
          if (tags != null && tags.isNotEmpty) {
            String url = '';

            for (final tag in tags) {
              final firstElement = (tag as List).first;

              if (firstElement == 'url') {
                url = tag[1];
              }
            }

            if (url.isNotEmpty) {
              return url;
            }

            BotToastUtils.showError('Image could not be uploaded');
            return '';
          } else {
            BotToastUtils.showError('Image could not be uploaded');
            return '';
          }
        } else {
          BotToastUtils.showError('Image could not be uploaded');
          return '';
        }
      }
    } on dioInstance.DioException catch (e) {
      Logger().i(e.response);
      rethrow;
    }
  }

  static Future<Map<String, List<SmartWidgetTemplate>>>
      getSmartWidgetsTemplates() async {
    final map = <String, List<SmartWidgetTemplate>>{};
    try {
      final templates = _firestore.collection('smart_widgets_templates');

      return await templates.get().then((collection) {
        for (final doc in collection.docs) {
          map.addEntries(
            [
              parseSmartWidgetsTemplates(
                doc.id,
                doc.data(),
              ),
            ],
          );
        }

        return map;
      });
    } catch (e) {
      lg.i(e);
      return map;
    }
  }
}
