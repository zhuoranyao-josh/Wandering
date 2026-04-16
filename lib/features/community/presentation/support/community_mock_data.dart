import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../models/community_models.dart';

const String _mockImageAssetPath = 'assets/images/tokyo_preview.png';

Map<String, CommunityUser> _buildUsers(AppLocalizations t) {
  return <String, CommunityUser>{
    'user-luna': CommunityUser(
      id: 'user-luna',
      name: t.communityMockUserLuna,
      uid: 'UID-2048',
      avatarColor: const Color(0xFFF97316),
    ),
    'user-noah': CommunityUser(
      id: 'user-noah',
      name: t.communityMockUserNoah,
      uid: 'UID-3157',
      avatarColor: const Color(0xFF2563EB),
    ),
    'user-iris': CommunityUser(
      id: 'user-iris',
      name: t.communityMockUserIris,
      uid: 'UID-7821',
      avatarColor: const Color(0xFF059669),
    ),
  };
}

List<CommunityPost> buildCommunityPosts(AppLocalizations t) {
  final users = _buildUsers(t);

  return <CommunityPost>[
    CommunityPost(
      id: 'post-night-market',
      author: users['user-luna']!,
      title: t.communityMockPostOneTitle,
      excerpt: t.communityMockPostOneSummary,
      content: t.communityMockPostOneContent,
      imageAssetPath: _mockImageAssetPath,
      timeLabel: t.communityMockPostOneTime,
      locationLabel: t.communityMockPostOneLocation,
      likeCount: 128,
      commentCount: 24,
      comments: const <CommunityComment>[],
    ),
    CommunityPost(
      id: 'post-riverside',
      author: users['user-noah']!,
      title: t.communityMockPostTwoTitle,
      excerpt: t.communityMockPostTwoSummary,
      content: t.communityMockPostTwoContent,
      imageAssetPath: _mockImageAssetPath,
      timeLabel: t.communityMockPostTwoTime,
      locationLabel: t.communityMockPostTwoLocation,
      likeCount: 86,
      commentCount: 16,
      comments: const <CommunityComment>[],
    ),
    CommunityPost(
      id: 'post-cafe',
      author: users['user-iris']!,
      title: t.communityMockPostThreeTitle,
      excerpt: t.communityMockPostThreeSummary,
      content: t.communityMockPostThreeContent,
      imageAssetPath: _mockImageAssetPath,
      timeLabel: t.communityMockPostThreeTime,
      locationLabel: t.communityMockPostThreeLocation,
      likeCount: 203,
      commentCount: 39,
      comments: const <CommunityComment>[],
    ),
  ];
}

CommunityUser? findCommunityUserById({
  required String userId,
  required AppLocalizations t,
}) {
  return _buildUsers(t)[userId];
}

List<CommunityPost> buildCommunityPostsByUser({
  required String userId,
  required AppLocalizations t,
}) {
  return buildCommunityPosts(
    t,
  ).where((post) => post.author.id == userId).toList();
}
