// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'properties_cubit.dart';

class PropertiesState extends Equatable {
  final UserStatus userStatus;
  final PropertiesViews propertiesViews;
  final PropertiesToggle propertiesToggle;
  final String imageLink;
  final String placeHolder;
  final String random;
  final String bannerLink;
  final List<String> relays;
  final List<String> activeRelays;
  final List<String> onlineRelays;
  final String nip05;
  final String lud16;
  final String lud6;
  final String name;
  final String displayName;
  final String description;
  final String website;
  final String authPrivKey;
  final String authPubKey;
  final bool isSameRelays;
  final bool isSameLud16;
  final bool isPrefixUsed;
  final bool isUsingNip44;
  final bool isUsingSigner;
  final String uploadServer;

  PropertiesState({
    required this.userStatus,
    required this.propertiesViews,
    required this.propertiesToggle,
    required this.imageLink,
    required this.placeHolder,
    required this.random,
    required this.bannerLink,
    required this.relays,
    required this.activeRelays,
    required this.onlineRelays,
    required this.nip05,
    required this.lud16,
    required this.lud6,
    required this.name,
    required this.displayName,
    required this.description,
    required this.website,
    required this.authPrivKey,
    required this.authPubKey,
    required this.isSameRelays,
    required this.isSameLud16,
    required this.isPrefixUsed,
    required this.isUsingNip44,
    required this.isUsingSigner,
    required this.uploadServer,
  });

  @override
  List<Object> get props => [
        description,
        name,
        userStatus,
        placeHolder,
        random,
        isUsingSigner,
        isPrefixUsed,
        propertiesViews,
        propertiesToggle,
        imageLink,
        bannerLink,
        relays,
        nip05,
        lud16,
        lud6,
        authPrivKey,
        authPubKey,
        activeRelays,
        onlineRelays,
        isSameRelays,
        isSameLud16,
        onlineRelays,
        isUsingNip44,
        uploadServer,
        displayName,
        website,
      ];

  PropertiesState copyWith({
    UserStatus? userStatus,
    PropertiesViews? propertiesViews,
    PropertiesToggle? propertiesToggle,
    String? imageLink,
    String? placeHolder,
    String? random,
    String? bannerLink,
    List<String>? relays,
    List<String>? activeRelays,
    List<String>? onlineRelays,
    String? nip05,
    String? lud16,
    String? lud6,
    String? name,
    String? displayName,
    String? description,
    String? website,
    String? authPrivKey,
    String? authPubKey,
    bool? isSameRelays,
    bool? isSameLud16,
    bool? isPrefixUsed,
    bool? isUsingNip44,
    bool? isUsingSigner,
    String? uploadServer,
  }) {
    return PropertiesState(
      userStatus: userStatus ?? this.userStatus,
      propertiesViews: propertiesViews ?? this.propertiesViews,
      propertiesToggle: propertiesToggle ?? this.propertiesToggle,
      imageLink: imageLink ?? this.imageLink,
      placeHolder: placeHolder ?? this.placeHolder,
      random: random ?? this.random,
      bannerLink: bannerLink ?? this.bannerLink,
      relays: relays ?? this.relays,
      activeRelays: activeRelays ?? this.activeRelays,
      onlineRelays: onlineRelays ?? this.onlineRelays,
      nip05: nip05 ?? this.nip05,
      lud16: lud16 ?? this.lud16,
      lud6: lud6 ?? this.lud6,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      website: website ?? this.website,
      authPrivKey: authPrivKey ?? this.authPrivKey,
      authPubKey: authPubKey ?? this.authPubKey,
      isSameRelays: isSameRelays ?? this.isSameRelays,
      isSameLud16: isSameLud16 ?? this.isSameLud16,
      isPrefixUsed: isPrefixUsed ?? this.isPrefixUsed,
      isUsingNip44: isUsingNip44 ?? this.isUsingNip44,
      isUsingSigner: isUsingSigner ?? this.isUsingSigner,
      uploadServer: uploadServer ?? this.uploadServer,
    );
  }
}
