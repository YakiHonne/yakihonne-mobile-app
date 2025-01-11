import 'dart:convert';

import 'package:equatable/equatable.dart';

class UserStatusModel extends Equatable {
  final bool isUsingPrivKey;
  final String pubKey;
  final String privKey;

  UserStatusModel({
    required this.isUsingPrivKey,
    required this.pubKey,
    required this.privKey,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isUsingPrivKey': isUsingPrivKey,
      'pubKey': pubKey,
      'privKey': privKey,
    };
  }

  factory UserStatusModel.fromMap(Map<String, dynamic> map) {
    return UserStatusModel(
      isUsingPrivKey: map['isUsingPrivKey'] as bool,
      pubKey: map['pubKey'] as String,
      privKey: map['privKey'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserStatusModel.fromJson(String source) =>
      UserStatusModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        isUsingPrivKey,
        pubKey,
        privKey,
      ];
}
