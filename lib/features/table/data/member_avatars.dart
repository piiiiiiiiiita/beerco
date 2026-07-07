import 'dart:math';

/// Character avatar set (memoji-style) shipped in assets.
const List<String> memberAvatarAssets = [
  'assets/images/avatars/Avatar=1.png',
  'assets/images/avatars/Avatar=2.png',
  'assets/images/avatars/Avatar=4.png',
  'assets/images/avatars/Avatar=7.png',
  'assets/images/avatars/Avatar=11.png',
  'assets/images/avatars/Avatar=12.png',
  'assets/images/avatars/Avatar=23.png',
  'assets/images/avatars/Avatar=26.png',
  'assets/images/avatars/Avatar=28.png',
  'assets/images/avatars/Avatar=32.png',
  'assets/images/avatars/Avatar=36.png',
  'assets/images/avatars/Avatar=37.png',
];

/// Deterministic fallback so a member without a chosen avatar still keeps the
/// same face across rebuilds.
String avatarAssetForMember(String memberId) =>
    memberAvatarAssets[memberId.hashCode.abs() % memberAvatarAssets.length];

/// Effective avatar for a member: their chosen one, or the deterministic fallback.
String resolvedAvatarAsset(String memberId, String? chosen) =>
    chosen ?? avatarAssetForMember(memberId);

final _random = Random();

String randomAvatarAsset() =>
    memberAvatarAssets[_random.nextInt(memberAvatarAssets.length)];
