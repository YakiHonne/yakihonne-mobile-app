import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'property_thumbnail_picture_state.dart';

class PropertyThumbnailPictureCubit
    extends Cubit<PropertyThumbnailPictureState> {
  PropertyThumbnailPictureCubit({
    required this.nostrRepository,
  }) : super(PropertyThumbnailPictureState(
          imageLink: nostrRepository.user.banner,
          isLocalImage: false,
          isImageSelected: nostrRepository.user.banner.isNotEmpty,
          localImage: null,
        ));

  final NostrDataRepository nostrRepository;

  Future<void> updateMetadata({
    required Function(String) onFailure,
    required Function(String) onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      String imageLink = '';

      if (state.isLocalImage) {
        try {
          imageLink = await uploadImage();
        } catch (e) {
          onFailure.call('Error occured while uploading the image');
          _cancel.call();
          return;
        }
      } else {
        if (state.imageLink.trim().isNotEmpty &&
            state.imageLink.trim().startsWith('https')) {
          imageLink = state.imageLink;
        } else {
          onFailure.call(
            'Select a valid url image.',
          );
          _cancel.call();
          return;
        }
      }

      final userModel = nostrRepository.user.copyWith(
        banner: imageLink,
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
          event: kind0Event, setProgress: true);

      if (isSuccessful) {
        HttpFunctionsRepository.sendAction(PointsActions.COVER);
        nostrRepository.setUserModel(userModel);
        authorsCubit.addAuthor(
          UserModel.fromJson(
            kind0Event.content,
            kind0Event.pubkey,
            kind0Event.tags,
            kind0Event.createdAt,
          ),
        );
        onSuccess.call('Update has been done successfuly!');
      } else {
        onFailure.call('An error occured while updating data');
      }

      _cancel.call();
    } catch (e) {
      _cancel.call();
      onFailure.call('An error occured while updating data');
    }
  }

  Future<void> selectProfileImage({
    required Function() onFailed,
  }) async {
    if (Platform.isIOS) {
      try {
        final XFile? image;
        image = await ImagePicker().pickImage(source: ImageSource.gallery);

        if (image != null) {
          final file = File(image.path);
          if (!isClosed)
            emit(
              state.copyWith(
                localImage: null,
              ),
            );
          if (!isClosed)
            emit(
              state.copyWith(
                localImage: file,
                isLocalImage: true,
                imageLink: '',
                isImageSelected: true,
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
                isLocalImage: true,
                imageLink: '',
                isImageSelected: true,
              ),
            );
        }
      } else {
        onFailed.call();
      }
    }
  }

  Future<void> selectUrlImage({
    required String url,
  }) async {
    if (!isClosed)
      emit(
        state.copyWith(
          localImage: null,
          isLocalImage: false,
          isImageSelected: true,
          imageLink: url,
        ),
      );
  }

  void removeImage() {
    if (!isClosed)
      emit(
        state.copyWith(
          localImage: null,
          isLocalImage: false,
          isImageSelected: false,
          imageLink: '',
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
        pubKey: nostrRepository.usm!.pubKey,
      );
    } catch (e) {
      Logger().i(e);
      rethrow;
    }
  }
}
