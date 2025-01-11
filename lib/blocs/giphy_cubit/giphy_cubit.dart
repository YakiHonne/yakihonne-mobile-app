import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:giphy_api_client/giphy_api_client.dart';
import 'package:yakihonne/utils/mixins/later_function.dart';
import 'package:yakihonne/utils/utils.dart';

part 'giphy_state.dart';

class GiphyCubit extends Cubit<GiphyState> with LaterFunction {
  GiphyCubit()
      : super(
          GiphyState(
            gifs: [],
            stickers: [],
            gifsUpdatingState: UpdatingState.progress,
            stickersUpdatingState: UpdatingState.progress,
          ),
        ) {
    initView();
    laterTimeMS = 600;
  }

  final client = GiphyClient(apiKey: dotenv.env['GIPHY_KEY']!);

  void initView() async {
    try {
      emit(
        GiphyState(
          gifs: [],
          stickers: [],
          gifsUpdatingState: UpdatingState.progress,
          stickersUpdatingState: UpdatingState.progress,
        ),
      );

      final res = await Future.wait([
        client.trending(
          limit: 20,
          type: GiphyType.gifs.name,
        ),
        client.trending(
          limit: 20,
          type: GiphyType.stickers.name,
        ),
      ]);

      emit(
        state.copyWith(
          gifs: res[0].data,
          stickers: res[1].data,
          stickersUpdatingState: UpdatingState.success,
          gifsUpdatingState: UpdatingState.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          gifsUpdatingState: UpdatingState.failure,
          stickersUpdatingState: UpdatingState.failure,
        ),
      );
    }
  }

  void startSearch({
    required GiphyType giphyType,
    required String text,
  }) async {
    later(
      () {
        search(giphyType: giphyType, text: text);
      },
      () {},
    );
  }

  void search({required GiphyType giphyType, required String text}) async {
    try {
      emit(
        state.copyWith(
          gifsUpdatingState:
              giphyType == GiphyType.gifs ? UpdatingState.progress : null,
          stickersUpdatingState:
              giphyType == GiphyType.stickers ? UpdatingState.progress : null,
          gifs: giphyType == GiphyType.gifs ? [] : null,
          stickers: giphyType == GiphyType.stickers ? [] : null,
        ),
      );

      if (text.trim().isEmpty) {
        if (giphyType == GiphyType.gifs) {
          final res = await client.trending(
            limit: 20,
            type: GiphyType.gifs.name,
          );

          emit(
            state.copyWith(
              gifs: res.data,
              gifsUpdatingState: UpdatingState.success,
            ),
          );
        } else {
          final res = await client.trending(
            limit: 20,
            type: GiphyType.stickers.name,
          );

          emit(
            state.copyWith(
              stickers: res.data,
              stickersUpdatingState: UpdatingState.success,
            ),
          );
        }
      } else {
        if (giphyType == GiphyType.gifs) {
          final res = await client.search(
            text,
            limit: 20,
            type: GiphyType.gifs.name,
          );

          emit(
            state.copyWith(
              gifs: res.data,
              gifsUpdatingState: UpdatingState.success,
            ),
          );
        } else {
          final res = await client.search(
            text,
            limit: 20,
            type: GiphyType.stickers.name,
          );

          emit(
            state.copyWith(
              stickers: res.data,
              stickersUpdatingState: UpdatingState.success,
            ),
          );
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          gifsUpdatingState:
              giphyType == GiphyType.gifs ? UpdatingState.failure : null,
          stickersUpdatingState:
              giphyType == GiphyType.stickers ? UpdatingState.failure : null,
        ),
      );
    }
  }
}
