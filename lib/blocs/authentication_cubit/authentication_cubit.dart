// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:amberflutter/amberflutter.dart' as amb;
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit({
    required this.nostrRepository,
    required this.context,
  }) : super(
          AuthenticationState(
            signupView: AuthenticationViews.initial,
            authPrivKey: '',
            authPubKey: '',
            selectedProfileImage: 0,
            imageLink: '',
            picturesType: PicturesType.defaultPicture,
            localImage: null,
          ),
        );

  final NostrDataRepository nostrRepository;
  final BuildContext context;
  String imageLink = '';

  void updateAuthenticationViews(AuthenticationViews view) {
    if (!isClosed)
      emit(
        state.copyWith(
          signupView: view,
        ),
      );
  }

  void generateKeys() {
    final keyChain = Keychain.generate();
    final private = Nip19.encodePrivkey(keyChain.private);
    final public = Nip19.encodePubkey(keyChain.public);

    if (!isClosed)
      emit(
        state.copyWith(
          authPubKey: public,
          authPrivKey: private,
        ),
      );
  }

  Future<void> login({
    required String key,
    required Function(String) onFail,
    required Function() onSuccess,
    required Function() onAccountDeleted,
  }) async {
    String hex = '';
    bool isPrivKey = false;

    if (key.startsWith('nsec')) {
      try {
        hex = Nip19.decodePrivkey(key.trim());

        if (hex.isEmpty) {
          onFail.call('Invalid private key!');
          return;
        }

        isPrivKey = true;
      } catch (_) {
        onFail.call('Invalid private key!');
        return;
      }
    } else if (key.startsWith('npub')) {
      try {
        hex = Nip19.decodePubkey(key.trim());

        if (hex.isEmpty) {
          onFail.call('Invalid public key!');
          return;
        }

        isPrivKey = false;
      } catch (_) {
        onFail.call('Invalid public key!');
        return;
      }
    } else if (key.length == 64) {
      hex = key;
      isPrivKey = true;
    } else {
      onFail.call('Invalid hex key!');
      return;
    }

    if (isPrivKey) {
      final status = await getAccountStatus(Keychain.getPublicKey(hex));

      if (status == AccountStatus.error) {
        onFail.call('Something occured while logging in!');
        return;
      } else if (status == AccountStatus.available) {
        if (nostrRepository.usmList.keys.contains(Keychain.getPublicKey(hex))) {
          BotToastUtils.showWarning('You are already logged in!');
          onSuccess.call();
          return;
        }

        nostrRepository.getUserMetaData(
          hex: hex,
          isPrivKey: isPrivKey,
        );

        onSuccess.call();
        BotToastUtils.showSuccess('You are logged in!');
      } else {
        onAccountDeleted.call();
      }
    } else {
      if (nostrRepository.usmList.keys.contains(hex)) {
        BotToastUtils.showWarning('You are already logged in!');
        onSuccess.call();
        return;
      }

      nostrRepository.getUserMetaData(
        hex: hex,
        isPrivKey: isPrivKey,
      );

      onSuccess.call();
      BotToastUtils.showSuccess('You are a guest!');
    }
  }

  Future<void> loginWithAmber({
    required Function() onSuccess,
  }) async {
    final amber = amb.Amberflutter();

    bool isInstalled = await amber.isAppInstalled();

    if (!isInstalled) {
      BotToastUtils.showError('Amber app is not installed');
      return;
    }

    try {
      Map val = await amber.getPublicKey(
        permissions: [
          amb.Permission(type: 'sign_event'),
          amb.Permission(type: 'sign_event', kind: EventKind.TEXT_NOTE),
          amb.Permission(type: 'nip04_encrypt'),
          amb.Permission(type: 'nip04_decrypt'),
          amb.Permission(type: 'nip44_encrypt'),
          amb.Permission(type: 'nip44_decrypt'),
          amb.Permission(type: 'sign_event', kind: 5),
          amb.Permission(type: 'sign_event', kind: 7),
          amb.Permission(
              type: 'sign_event', kind: EventKind.APPLICATIONS_REFERENCE),
          amb.Permission(
              type: 'sign_event', kind: EventKind.CATEGORIZED_BOOKMARK),
          amb.Permission(type: 'sign_event', kind: EventKind.CURATION_ARTICLES),
          amb.Permission(type: 'sign_event', kind: EventKind.CURATION_VIDEOS),
          amb.Permission(type: 'sign_event', kind: EventKind.LONG_FORM),
          amb.Permission(type: 'sign_event', kind: EventKind.LONG_FORM_DRAFT),
          amb.Permission(type: 'sign_event', kind: EventKind.APP_CUSTOM),
          amb.Permission(type: 'sign_event', kind: EventKind.VIDEO_HORIZONTAL),
          amb.Permission(type: 'sign_event', kind: EventKind.VIDEO_VERTICAL),
          amb.Permission(type: 'sign_event', kind: EventKind.VIDEO_VIEW),
          amb.Permission(type: 'sign_event', kind: EventKind.ZAP_REQUEST),
        ],
      );

      if (val['signature'] != null && (val['signature'] as String).isNotEmpty) {
        if (nostrRepository.usmList.keys.contains(val['signature'])) {
          BotToastUtils.showWarning('You are already logged in!');
          onSuccess.call();
          return;
        }

        nostrRepository.getUserMetaData(
          hex: val['signature'],
          isPrivKey: true,
          isExternalSigner: true,
        );

        BotToastUtils.showSuccess('You are logged in!');
        onSuccess.call();
      } else {
        BotToastUtils.showError(
          'Attempt to connect with Amber has been rejected.',
        );
      }
    } catch (e) {
      lg.i(e);
    }
  }

  Future<AccountStatus> getAccountStatus(String pubkey) async {
    AccountStatus status = AccountStatus.available;
    bool isSuccessful = false;
    final _cancel = BotToast.showLoading();

    NostrConnect.sharedInstance.connect(mandatoryRelays.first);

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [0],
          authors: [pubkey],
        ),
      ],
      [mandatoryRelays.first],
      eventCallBack: (event, relay) {
        if (event.kind == 0) {
          final user = UserModel.fromJson(
            event.content,
            event.pubkey,
            event.tags,
            event.createdAt,
          );

          if (user.isDeleted) {
            status = AccountStatus.deleted;
          } else {
            status = AccountStatus.available;
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        if (ok.status) {
          isSuccessful = true;
        }
      },
    );

    int duration = 0;

    await Future.doWhile(
      () async {
        await Future.delayed(const Duration(milliseconds: 500));

        if (duration == 10 && !isSuccessful) {
          status = AccountStatus.error;
        }

        duration++;

        return !(isSuccessful || duration == 10);
      },
    );

    _cancel.call();
    return status;
  }

  Future<void> signup({
    required Function(String) onFailed,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      if (state.picturesType == PicturesType.localPicture) {
        try {
          imageLink = await uploadImage();
        } catch (e) {
          onFailed.call('Error occured while uploading the image');
          _cancel.call();
          return;
        }
      } else if (state.picturesType == PicturesType.defaultPicture) {
        imageLink = profileImages[state.selectedProfileImage];
      } else {
        if (state.imageLink.trim().isNotEmpty &&
            state.imageLink.trim().startsWith('https')) {
          imageLink = state.imageLink;
        } else {
          onFailed.call(
            'Select a valid url image.',
          );
          _cancel.call();
          return;
        }
      }

      final userModel = emptyUserModel.copyWith(
        picturePlaceholder: getRandomPlaceholder(input: 'default', isPfp: true),
      );

      final event = Nip1.setMetadata(
        userModel
            .copyWith(
              picture: imageLink,
            )
            .toJson(),
        Nip19.decodePrivkey(state.authPrivKey),
      );

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
      );

      if (isSuccessful) {
        nostrRepository.getUserMetaData(
          hex: Nip19.decodePrivkey(state.authPrivKey),
          isPrivKey: true,
        );

        onSuccess.call();
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      _cancel.call();
    } catch (e) {
      lg.i(e);
      _cancel.call();
    }
  }

  Future<void> setName({
    required String name,
    required Function() onFailed,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final userModel = nostrRepository.user;

    final event = Nip1.setMetadata(
      userModel
          .copyWith(
            name: name,
            displayName: name,
          )
          .toJson(),
      Nip19.decodePrivkey(state.authPrivKey),
    );

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: false,
    );

    if (isSuccessful) {
      nostrRepository.getUserMetaData(
        hex: Nip19.decodePrivkey(state.authPrivKey),
        isPrivKey: true,
      );
      onSuccess.call();
      BotToastUtils.showSuccess('You are logged in!');
    } else {
      onFailed.call();
    }

    _cancel.call();
  }

  void selectPicture(int index) {
    if (!isClosed)
      emit(
        state.copyWith(
          selectedProfileImage: index,
          localImage: null,
          picturesType: PicturesType.defaultPicture,
          imageLink: '',
        ),
      );
  }

  void setImageLink(String link) {
    if (!isClosed)
      emit(
        state.copyWith(
          selectedProfileImage: -1,
          localImage: null,
          picturesType: PicturesType.linkPicture,
          imageLink: link,
        ),
      );
  }

  Future<void> selectProfileImage({
    required Function() onFailed,
  }) async {
    if (!isClosed)
      emit(
        state.copyWith(
          localImage: null,
          picturesType: PicturesType.linkPicture,
        ),
      );

    if (Platform.isIOS) {
      try {
        final XFile? image;
        image = await ImagePicker().pickImage(source: ImageSource.gallery);

        if (image != null) {
          final file = File(image.path);

          if (!isClosed)
            emit(
              state.copyWith(
                localImage: file,
                picturesType: PicturesType.localPicture,
                selectedProfileImage: -1,
              ),
            );
        }
      } catch (e) {
        onFailed.call();
      }
    } else if (Platform.isAndroid) {
      bool storage = true;
      bool photos = true;

      final deviceInfo = await DeviceInfoPlugin().androidInfo;

      if (deviceInfo.version.sdkInt >= 33) {
        photos = await _requestPermission(Permission.photos);
      } else {
        storage = await _requestPermission(Permission.storage);
      }

      if (storage && photos) {
        final XFile? image;
        image = await ImagePicker().pickImage(source: ImageSource.gallery);

        if (image != null) {
          final file = File(image.path);

          if (!isClosed)
            emit(
              state.copyWith(
                localImage: file,
                picturesType: PicturesType.localPicture,
                selectedProfileImage: -1,
              ),
            );
        }
      } else {
        onFailed.call();
      }
    }
  }

  void removeLocalImage() {
    if (!isClosed)
      emit(
        state.copyWith(
          selectedProfileImage: 0,
          localImage: null,
          picturesType: PicturesType.defaultPicture,
        ),
      );
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  Future<String> uploadImage() async {
    try {
      return await HttpFunctionsRepository.uploadImage(
        file: state.localImage!,
        pubKey: Nip19.decodePubkey(state.authPubKey),
      );
    } catch (e) {
      Logger().i(e);
      rethrow;
    }
  }
}
