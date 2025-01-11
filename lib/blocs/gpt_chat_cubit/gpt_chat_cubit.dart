import 'package:bloc/bloc.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/chat_message.dart';
import 'package:yakihonne/utils/utils.dart';

part 'gpt_chat_state.dart';

class GptChatCubit extends Cubit<GptChatState> {
  GptChatCubit()
      : super(
          GptChatState(
            chatMessage: nostrRepository.gptMessages,
          ),
        );

  final _openAi = OpenAI.instance.build(
    token: dotenv.env['GPT_KEY'],
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 5),
    ),
    enableLog: true,
  );

  Future<void> getChatResponse(String message) async {
    final m = ChatMessage.fromDirectData(
      message: message,
      user: nostrRepository.user,
      isCurrentUser: true,
    );

    emit(
      state.copyWith(
        chatMessage: [
          ...state.chatMessage,
          m,
        ],
      ),
    );

    final messagesHistory = state.chatMessage.map((m) {
      if (m.user == nostrRepository.user) {
        return Messages(
          role: Role.user,
          content: m.text,
        );
      } else {
        return Messages(role: Role.assistant, content: m.text);
      }
    }).toList();

    final request = ChatCompleteText(
      model: GptTurbo0301ChatModel(),
      messages: messagesHistory,
      maxToken: 200,
    );

    final response = await _openAi.onChatCompletion(request: request);

    for (var element in response!.choices) {
      if (element.message != null) {
        final newMessages = [
          ...state.chatMessage,
          ChatMessage.fromDirectData(
            user: emptyUserModel.copyWith(pubKey: 'GPT'),
            message: element.message!.content,
            isCurrentUser: false,
          ),
        ];

        nostrRepository.gptMessages = newMessages;

        emit(
          state.copyWith(
            chatMessage: newMessages,
          ),
        );
      }
    }
  }

  void clearMessages() {
    emit(
      state.copyWith(
        chatMessage: [],
      ),
    );

    nostrRepository.gptMessages = [];
  }
}
