import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';

part 'article_image_selector_state.dart';

class ArticleImageSelectorCubit extends Cubit<ArticleImageSelectorState> {
  ArticleImageSelectorCubit({
    required this.localDatabaseRepository,
    required this.nostrRepository,
  }) : super(
          ArticleImageSelectorState(
            imageLink: '',
            isLocalImage: false,
            isImageSelected: false,
            localImage: null,
            imagesLinks: [],
          ),
        ) {
    setImageLinks();
  }

  final LocalDatabaseRepository localDatabaseRepository;
  final NostrDataRepository nostrRepository;

  void setImageLinks() async {
    final links = await localDatabaseRepository
        .getImagesLinks(nostrRepository.usm!.pubKey);
    if (!isClosed)
      emit(
        state.copyWith(
          imagesLinks: links,
        ),
      );
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
    } else {
      if (!isClosed)
        emit(
          state.copyWith(
            localImage: null,
            isLocalImage: false,
            isImageSelected: false,
          ),
        );

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

  Future<void> addImage({
    required Function(String) onSuccess,
    required Function(String) onFailure,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      final link = await uploadImage();

      final newLinks = List<String>.from(state.imagesLinks)..add(link);

      localDatabaseRepository.setImagesLinks(
        nostrRepository.usm!.pubKey,
        newLinks,
      );

      if (!isClosed)
        emit(
          state.copyWith(
            imagesLinks: newLinks,
          ),
        );

      _cancel.call();
      onSuccess.call(link);
    } catch (_) {
      _cancel.call();
      onFailure.call('An error occured while uploading the image');
    }
  }
}
