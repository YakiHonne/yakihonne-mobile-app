import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/nostr/zaps/zap.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit({
    required this.nostrRepository,
    required this.localDatabaseRepository,
  }) : super(
          PropertiesState(
            imageLink: nostrRepository.user.picture,
            userStatus: getUserStatus(),
            placeHolder: nostrRepository.user.bannerPlaceholder,
            propertiesViews: PropertiesViews.main,
            propertiesToggle: PropertiesToggle.none,
            bannerLink: nostrRepository.user.banner,
            lud16: nostrRepository.user.lud16,
            random: nostrRepository.user.picturePlaceholder,
            lud6: Zap.getLnurlFromLud16(nostrRepository.user.lud16) ?? '',
            nip05: nostrRepository.user.nip05,
            relays: nostrRepository.relays.toList(),
            activeRelays: NostrConnect.sharedInstance.activeRelays(),
            description: nostrRepository.user.about,
            name: nostrRepository.user.name,
            displayName: nostrRepository.user.displayName,
            website: nostrRepository.user.website,
            authPrivKey: '',
            isUsingSigner: nostrRepository.isUsingExternalSigner,
            isUsingNip44: nostrRepository.isUsingNip44,
            authPubKey: '',
            onlineRelays: [],
            isSameRelays: true,
            isSameLud16: true,
            isPrefixUsed: false,
            uploadServer: nostrRepository.usedUploadServer,
          ),
        ) {
    setKeys();
    setRelaysStatus();
    initYakihonnePrefix();

    currentRelays = nostrRepository.relays.toList();
    lud16 = nostrRepository.user.lud16;
    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: user.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
                bannerLink: nostrRepository.user.banner,
                lud16: nostrRepository.user.lud16,
                nip05: nostrRepository.user.nip05,
                relays: nostrRepository.relays.toList(),
                description: nostrRepository.user.about,
                name: nostrRepository.user.name,
                displayName: nostrRepository.user.displayName,
                website: nostrRepository.user.website,
                imageLink: nostrRepository.user.picture,
              ),
            );
        }
      },
    );
  }

  final NostrDataRepository nostrRepository;
  final LocalDatabaseRepository localDatabaseRepository;

  late StreamSubscription userSubcription;
  List<String> currentRelays = [];
  late String lud16;
  late Timer timer;

  void initYakihonnePrefix() async {
    final prefix = await localDatabaseRepository.getPrefix();

    if (!isClosed)
      emit(
        state.copyWith(isPrefixUsed: prefix ?? false),
      );
  }

  void setYakihonnePrefix(bool newPrefix) async {
    if (!isClosed)
      emit(
        state.copyWith(isPrefixUsed: newPrefix),
      );

    localDatabaseRepository.setPrefix(newPrefix);
  }

  void setUsedMessagingNip(bool isUsingNip44) async {
    if (!isClosed)
      emit(
        state.copyWith(isUsingNip44: isUsingNip44),
      );

    dmsCubit.setUsedMessagingNip(isUsingNip44);
  }

  void setKeys() {
    if (getUserStatus() == UserStatus.UsingPrivKey) {
      if (!isClosed)
        emit(
          state.copyWith(
            authPrivKey: nostrRepository.usm!.privKey,
            authPubKey: nostrRepository.usm!.pubKey,
          ),
        );
    }
  }

  void setRelaysStatus() {
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        final activeRelays = NostrConnect.sharedInstance.activeRelays();
        final relays = NostrConnect.sharedInstance.relays();

        if (!isClosed)
          emit(
            state.copyWith(
              activeRelays: activeRelays,
              relays: relays,
            ),
          );
      },
    );
  }

  void setPropertyToggle(PropertiesToggle propertiesToggle) {
    if (!isClosed)
      emit(
        state.copyWith(
          propertiesToggle: propertiesToggle,
        ),
      );
  }

  Future<void> updateMetadata({
    required Map<String, String> data,
    required Function(String) onFailure,
    required Function(String) onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      final userModel = nostrRepository.user.copyWith(
        nip05: data['nip05'],
        name: data['name'],
        displayName: data['displayName'],
        about: data['about'],
        lud16: data['lud16'],
        lud06: data['lud06'],
        banner: data['banner'],
        website: data['website'],
      );

      final kind0Event = await Event.genEvent(
        content: userModel.toJson(),
        kind: 0,
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
        tags: [],
      );

      if (kind0Event == null) {
        _cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: kind0Event,
        setProgress: true,
      );

      if (isSuccessful) {
        onSuccess.call('Update has been done successfuly!');
        final namePoints =
            data['name'] != null && data['name'] != nostrRepository.user.name;
        final displayPoints = data['displayName'] != null &&
            data['displayName'] != nostrRepository.user.displayName;
        final aboutPoints = data['about'] != null &&
            data['about'] != nostrRepository.user.about;

        if (data['nip05'] != null) {
          HttpFunctionsRepository.sendAction(PointsActions.NIP05);
        } else if (data['lud16'] != null) {
          HttpFunctionsRepository.sendAction(PointsActions.LUDS);
        } else if (namePoints || displayPoints) {
          await HttpFunctionsRepository.sendAction(PointsActions.USERNAME);

          if (aboutPoints) {
            HttpFunctionsRepository.sendAction(PointsActions.BIO);
          }
        } else if (aboutPoints) {
          HttpFunctionsRepository.sendAction(PointsActions.BIO);
        }

        nostrRepository.setUserModel(userModel);
        authorsCubit.addAuthor(
          UserModel.fromJson(
            kind0Event.content,
            kind0Event.pubkey,
            kind0Event.tags,
            kind0Event.createdAt,
          ),
        );

        this.lud16 = state.lud16;
      } else {
        this.lud16 = state.lud16;
        onFailure.call('An error occured while updating data');
      }

      if (!isClosed) emit(state.copyWith(isSameLud16: true));
      _cancel.call();
    } catch (e) {
      _cancel.call();

      onFailure.call('An error occured while updating data');
    }
  }

  Future<void> setLud16(String lud16, Function(String lud06) onLud06) async {
    final lud06 = Zap.getLnurlFromLud16(lud16);

    if (!isClosed)
      emit(
        state.copyWith(
          lud16: lud16,
          lud6: lud06 ?? '',
          isSameLud16: this.lud16 == lud16,
        ),
      );

    onLud06.call(lud06 ?? '');
  }

  Future<void> updateLud16({
    required Function(String) onFailed,
    required Function(String) onSuccess,
  }) async {
    if (state.lud16.isEmpty) {
      onFailed.call('Empty lud 16');
      return;
    }

    updateMetadata(
      data: {
        'lud16': state.lud16,
        'lud06': state.lud6,
      },
      onFailure: onFailed,
      onSuccess: onSuccess,
    );
  }

  Future<void> deleteUserAccount({
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final userModel = nostrRepository.user;

    final kind0Event = await Event.genEvent(
      content: userModel.toEmptyJson(),
      kind: 0,
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
      tags: [],
    );

    if (kind0Event == null) {
      _cancel.call();
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: kind0Event,
      setProgress: true,
    );

    if (isSuccessful) {
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  Future<void> deleteBanner(String bannerLink) async {
    try {
      if (bannerLink.isNotEmpty && bannerLink.contains('yakihonne.s3')) {
        await yakiDioFormData.delete(
          uploadUrl,
          queryParameters: {
            'image_path': bannerLink,
          },
        );
      }
    } catch (_) {
      return;
    }
  }

  void updateUploadServer(String uploadServer) {
    emit(
      state.copyWith(
        uploadServer: uploadServer,
      ),
    );

    nostrRepository.usedUploadServer = uploadServer;
    localDatabaseRepository.setUploadServer(uploadServer);
  }

  @override
  Future<void> close() {
    userSubcription.cancel();
    timer.cancel();
    return super.close();
  }
}
