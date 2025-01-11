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

part 'property_profile_picture_state.dart';

class PropertyProfilePictureCubit extends Cubit<PropertyProfilePictureState> {
  PropertyProfilePictureCubit({
    required this.nostrRepository,
  }) : super(PropertyProfilePictureState(
          imageLink: nostrRepository.user.picture,
          picturesType: PicturesType.linkPicture,
          selectedProfileImage: -1,
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

      if (state.picturesType == PicturesType.localPicture) {
        try {
          imageLink = await uploadImage();
        } catch (e) {
          onFailure.call('Error occured while uploading the image');
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
          onFailure.call(
            'Select a valid url image.',
          );
          _cancel.call();
          return;
        }
      }

      final userModel = nostrRepository.user.copyWith(picture: imageLink);

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
        HttpFunctionsRepository.sendAction(PointsActions.PROFILE_PICTURE);
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
                imageLink: '',
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
                imageLink: '',
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
        pubKey: nostrRepository.usm!.pubKey,
      );
    } catch (e) {
      Logger().i(e);
      rethrow;
    }
  }
}
