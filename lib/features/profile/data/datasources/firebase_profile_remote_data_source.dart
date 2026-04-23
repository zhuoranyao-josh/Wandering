import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/user_profile.dart';
import 'profile_remote_data_source.dart';

class FirebaseProfileRemoteDataSource implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FirebaseProfileRemoteDataSource({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<bool> isProfileCompleted(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();

    if (!doc.exists) return false;

    final data = doc.data();
    if (data == null) return false;

    return data['profileCompleted'] == true;
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    return UserProfile(
      uid: data['uid'] as String,
      email: data['email'] as String?,
      authProvider: (data['authProvider'] as String?) ?? 'unknown',
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      role: (data['role'] as String?)?.trim().toLowerCase() == 'admin'
          ? 'admin'
          : 'user',
      avatarUrl: data['avatarUrl'] as String?,
      nickname: (data['nickname'] as String?) ?? '',
      birthday: data['birthday'] != null
          ? DateTime.tryParse(data['birthday'] as String)
          : null,
      gender: (data['gender'] as String?) ?? 'other',
      countryCode: data['countryCode'] as String?,
      countryName: data['countryName'] as String?,
      bio: (data['bio'] as String?) ?? '',
      profileCompleted: (data['profileCompleted'] as bool?) ?? false,
    );
  }

  @override
  Future<void> saveProfile(
    UserProfile profile, {
    String? avatarLocalPath,
  }) async {
    final userDocRef = firestore.collection('users').doc(profile.uid);

    // 为了保证昵称唯一性，我们把 nickname 转成小写，
    // 然后拿它作为 nicknames 集合中的文档 id。
    final nicknameLower = profile.nickname.trim().toLowerCase();
    final nicknameDocRef = firestore.collection('nicknames').doc(nicknameLower);

    String? finalAvatarUrl = profile.avatarUrl;

    // 如果用户新选了头像，就先上传图片到 Firebase Storage，
    // 上传成功后拿到下载地址，再保存进 users 文档。
    if (avatarLocalPath != null && avatarLocalPath.isNotEmpty) {
      final file = File(avatarLocalPath);

      final storageRef = storage
          .ref()
          .child('avatars')
          .child(profile.uid)
          .child('avatar.jpg');

      await storageRef.putFile(file);
      finalAvatarUrl = await storageRef.getDownloadURL();
    }

    // 使用 Firestore transaction：
    // 1. 先检查昵称文档是否已经存在
    // 2. 如果被别人占用了，就抛出错误
    // 3. 否则同时写入 users/{uid} 和 nicknames/{nicknameLower}
    //
    // 这样即使多人同时提交相同昵称，也更安全。
    await firestore
        .runTransaction((transaction) async {
          final nicknameDoc = await transaction.get(nicknameDocRef);

          if (nicknameDoc.exists) {
            final data = nicknameDoc.data();
            final existingUid = data?['uid'] as String?;

            // 如果昵称已经被别的 uid 占用，就报错
            if (existingUid != null && existingUid != profile.uid) {
              throw AppException('nickname_taken');
            }
          }

          transaction.set(userDocRef, {
            'uid': profile.uid,
            'email': profile.email,
            'authProvider': profile.authProvider,
            'isAnonymous': profile.isAnonymous,
            'avatarUrl': finalAvatarUrl,
            'nickname': profile.nickname.trim(),
            'nicknameLower': nicknameLower,
            'birthday': profile.birthday?.toIso8601String(),
            'gender': profile.gender,
            'countryCode': profile.countryCode,
            'countryName': profile.countryName,
            'bio': profile.bio.trim(),
            'profileCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          transaction.set(nicknameDocRef, {
            'uid': profile.uid,
            'nickname': profile.nickname.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        })
        .catchError((error) {
          if (error is AppException) {
            throw error;
          }
          throw AppException('profile_save_failed');
        });
  }
}
