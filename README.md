# What is YakiHonne mobile app?

YakiHonne mobile app is a cross-platform mobile application built with Flutter. It aims to provide users with an intuitive and seamless experience with full Nostr integration.

YakiHonne also runs its own relays under [nostr-01.yakihonne.com](https://nostr-01.yakihonne.com) and [nostr-02.yakihonne.com](https://nostr-02.yakihonne.com) for creators to publish their content, it is free of charge (atm). The relay is based on [strfry](https://github.com/hoytech/strfry) and written in cpp if you would like to check it out.

# 1. Features

## 1.1 Mobile client

- [x] Login options support: keys, wallet, on-the-go account creation (NIP-01, NIP-07)
- [x] Bech32 encoding support (NIP-19)
- [x] Global Feed based on user all relays
- [x] Custom Feed based on user following
- [x] Top creators list based on all relays/selected relay
- [x] Top curators list based on nostr-01.yaihonne.com relay
- [x] Latest discussed topics based on hashtags
- [x] Home carousel containing latest published curations
- [x] Curations: topic-related curated articles (NIP-51)
- [x] My curations, My articles sections as a space for creators to manage and organize their content
- [x] Rich markdown editor to write and preview long-form content (NIP-23)
- [x] The ability to draft/edit/delete articles (NIP-09, NIP-23)
- [x] Topic-related search using hashtags (NIP-12)
- [x] Users search using pubkeys
- [x] Built-in upload for user profile images and banners within nostr-01.yakikhonne.com
- [x] User profile page: following/followers/zapping/published articles
- [x] URI scheme support (currenly only naddr) (NIP-21)
- [x] Users follow/unfollow (NIP-02)
- [x] Lightning zaps: via QR codes or dedicted wallet (NIP-57)
- [x] Customizable user settings: Keypair, Lightning Addres, relay list
- [x] Relay list metadata support (NIP-65)

## 1.2 Relay

[nostr-01.yakihonne.com](https://nostr-01.yakihonne.com) and [nostr-02.yakihonne.com](https://nostr-02.yakihonne.com) relay is fully based on [strfry](https://github.com/hoytech/strfry) implementation and writted in Typescript.

# Run YakiHonne locally

## Prerequisites

Before you begin, ensure you have met the following requirements:
• Flutter SDK installed. You can download it here.
• Dart SDK (included with Flutter).
• An IDE with Flutter and Dart plugins installed (e.g., Visual Studio Code, Android Studio).
• Xcode command line tools.

## Development

- Clone the repository: `https://github.com/YakiHonne/yakihonne-mobile-app.git`
- Navigate to the folder: `cd yakihonne-mobile-app`
- Install dependencies: `flutter pub get`
- Run the app: `flutter run`
