import 'package:flutter/material.dart';

class CommunityUser {
  const CommunityUser({
    required this.id,
    required this.name,
    required this.uid,
    required this.avatarColor,
  });

  final String id;
  final String name;
  final String uid;
  final Color avatarColor;
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.timeLabel,
  });

  final String id;
  final String authorName;
  final String content;
  final String timeLabel;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.imageAssetPath,
    required this.timeLabel,
    required this.locationLabel,
    required this.likeCount,
    required this.commentCount,
    required this.comments,
  });

  final String id;
  final CommunityUser author;
  final String title;
  final String excerpt;
  final String content;
  final String imageAssetPath;
  final String timeLabel;
  final String locationLabel;
  final int likeCount;
  final int commentCount;
  final List<CommunityComment> comments;
}
