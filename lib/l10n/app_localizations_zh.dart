// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get goToRegister => '没有账号？去注册';

  @override
  String get backToLogin => '已有账号？返回登录';

  @override
  String get loginWithGoogle => '使用 Google 登录';

  @override
  String get logout => '退出登录';

  @override
  String get homeTitle => '主页';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get uidLabel => 'UID';

  @override
  String get emailLabel => '邮箱';

  @override
  String get nameLabel => '昵称';

  @override
  String get errorEmptyFields => '请填写完整信息。';

  @override
  String get errorPasswordMismatch => '两次输入的密码不一致。';

  @override
  String get errorInvalidEmail => '邮箱格式不正确。';

  @override
  String get errorUserNotFound => '用户不存在。';

  @override
  String get errorInvalidCredential => '邮箱或密码错误。';

  @override
  String get errorEmailAlreadyInUse => '该邮箱已被注册。';

  @override
  String get errorWeakPassword => '密码至少需要 6 位。';

  @override
  String get errorGoogleCancelled => '你已取消 Google 登录。';

  @override
  String get errorGoogleFailed => 'Google 登录失败。';

  @override
  String get errorUnknown => '发生未知错误。';

  @override
  String get loginAsGuest => '游客登录';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get sendResetEmail => '发送重置邮件';

  @override
  String get resetPasswordHint => '请输入你的邮箱，我们会向该邮箱发送重置密码邮件。';

  @override
  String get resetPasswordEmailSent => '重置密码邮件已发送，请检查你的邮箱。';

  @override
  String get cancel => '取消';

  @override
  String get errorMissingEmail => '请输入邮箱地址。';

  @override
  String get errorTooManyRequests => '请求过于频繁，请稍后再试。';

  @override
  String get errorOperationNotAllowed => '该登录方式尚未启用。';

  @override
  String get welcomeSubtitle => '探索世界各地的城市、故事与旅行。';

  @override
  String get enterLoginOrRegister => '注册 / 登录';

  @override
  String get orText => '或';

  @override
  String get profileSetupTitle => '设置个人资料';

  @override
  String get profileNickname => '昵称';

  @override
  String get profileNicknameHint => '昵称不可与其他用户重复哦~';

  @override
  String get profileBirthday => '生日';

  @override
  String get profileGender => '性别';

  @override
  String get profileGenderMale => '男';

  @override
  String get profileGenderFemale => '女';

  @override
  String get profileGenderOther => '其他';

  @override
  String get profileCountryOptional => '地区（国家，可不填）';

  @override
  String get profileBio => '自我介绍';

  @override
  String get profileBioHint => '介绍一下自己吧~（最多100字符）';

  @override
  String get profileContinue => '继续';

  @override
  String get profileErrorNicknameEmpty => '请输入昵称';

  @override
  String get profileErrorNicknameTooLong => '昵称不能超过20个字符';

  @override
  String get profileErrorBioTooLong => '自我介绍不能超过100个字符';

  @override
  String get profileErrorNicknameTaken => '您的昵称与其他用户重复了哦！';

  @override
  String get profileErrorSaveFailed => '资料保存失败，请稍后再试';

  @override
  String get defaultUserName => '用户';

  @override
  String get language => '语言';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get profileEditTitle => '编辑资料';

  @override
  String get save => '保存';

  @override
  String get mapTabTitle => '地图页';

  @override
  String get mapTabPlaceholder => '地图功能占位';

  @override
  String get mapHomeLoadingTitle => '正在加载地球';

  @override
  String get mapHomeLoadingMessage => '地图资源初始化中，请稍候。';

  @override
  String get mapHomeLoadFailedTitle => '地图加载失败';

  @override
  String get mapHomeLoadFailedMessage => '当前无法完成地图初始化，请稍后重试。';

  @override
  String get mapHomeRetry => '重新加载';

  @override
  String get mapHomeMissingTokenTitle => '缺少 Mapbox 配置';

  @override
  String get mapHomeMissingTokenMessage => '请通过 dart-define 注入 Mapbox access token 后再运行应用。';

  @override
  String get mapHomeUnsupportedTitle => '当前平台暂不支持地图';

  @override
  String get mapHomeUnsupportedMessage => 'Mapbox Flutter SDK 目前仅支持 Android 和 iOS。';

  @override
  String get mapHomeSwitchToDay => '切换到白天模式';

  @override
  String get mapHomeSwitchToNight => '切换到夜晚模式';

  @override
  String get mapPlaceTokyoName => '东京';

  @override
  String get mapPlaceTokyoDescription => '这是一座用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceNewYorkName => '纽约';

  @override
  String get mapPlaceNewYorkDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceLosAngelesName => '洛杉矶';

  @override
  String get mapPlaceLosAngelesDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceMoscowName => '莫斯科';

  @override
  String get mapPlaceMoscowDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceSaintPetersburgName => '圣彼得堡';

  @override
  String get mapPlaceSaintPetersburgDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceYokohamaName => '横滨';

  @override
  String get mapPlaceYokohamaDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceOsakaName => '大阪';

  @override
  String get mapPlaceOsakaDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceBeijingName => '北京';

  @override
  String get mapPlaceBeijingDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceShanghaiName => '上海';

  @override
  String get mapPlaceShanghaiDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceGuangzhouName => '广州';

  @override
  String get mapPlaceGuangzhouDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceTianjinName => '天津';

  @override
  String get mapPlaceTianjinDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceLhasaName => '拉萨';

  @override
  String get mapPlaceLhasaDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceSuzhouName => '苏州';

  @override
  String get mapPlaceSuzhouDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceMunichName => '慕尼黑';

  @override
  String get mapPlaceMunichDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceBerlinName => '柏林';

  @override
  String get mapPlaceBerlinDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceFrankfurtName => '法兰克福';

  @override
  String get mapPlaceFrankfurtDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceIstanbulName => '伊斯坦布尔';

  @override
  String get mapPlaceIstanbulDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceTorontoName => '多伦多';

  @override
  String get mapPlaceTorontoDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceBuenosAiresName => '布宜诺斯艾利斯';

  @override
  String get mapPlaceBuenosAiresDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceSaoPauloName => '圣保罗';

  @override
  String get mapPlaceSaoPauloDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceCairoName => '开罗';

  @override
  String get mapPlaceCairoDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceCapeTownName => '开普敦';

  @override
  String get mapPlaceCapeTownDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceSydneyName => '悉尼';

  @override
  String get mapPlaceSydneyDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceMelbourneName => '墨尔本';

  @override
  String get mapPlaceMelbourneDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceWellingtonName => '惠灵顿';

  @override
  String get mapPlaceWellingtonDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceHongKongName => '香港';

  @override
  String get mapPlaceHongKongDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceParisName => '巴黎';

  @override
  String get mapPlaceParisDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get mapPlaceLondonName => '伦敦';

  @override
  String get mapPlaceLondonDescription => '用于验证地球光点、相机飞行动画与底部悬浮卡片的测试城市。';

  @override
  String get activitySearchHint => '搜索活动名称或城市';

  @override
  String get activityUpcomingTitle => '即将开始：';

  @override
  String get activityLoadFailed => '活动加载失败，请稍后再试。';

  @override
  String get activityRetry => '重新加载';

  @override
  String get activityEmptyDefault => '暂时还没有已发布活动。';

  @override
  String get activityEmptyFiltered => '没有找到符合当前筛选条件的活动。';

  @override
  String get activitySelectDateRange => '选择日期或日期范围';

  @override
  String get activityClearDateFilter => '清除日期筛选';

  @override
  String get activityDateFilterLabel => '日期';

  @override
  String get activityCategoryAll => '全部';

  @override
  String get activityCategoryTraditionalFestival => '传统节日';

  @override
  String get activityCategoryMusic => '音乐';

  @override
  String get activityCategoryExhibition => '展览';

  @override
  String get activityCategoryEntertainment => '娱乐';

  @override
  String get activityCategoryNature => '自然';

  @override
  String get activityDetailTitle => '活动详情';

  @override
  String get activityDetailEmpty => '详细内容正在整理中，敬请期待。';

  @override
  String get activityDetailNotFound => '未找到该活动。';

  @override
  String get activityBack => '返回';

  @override
  String get activityAlwaysOpen => '长期开放';

  @override
  String activityLongTermOpenFrom(Object date) {
    return '自 $date 起长期开放';
  }

  @override
  String activityOpenUntil(Object date) {
    return '开放至 $date';
  }

  @override
  String get viewDetails => '查看详情';

  @override
  String get placeDetailsUniqueExperiences => '独特体验';

  @override
  String get placeDetailsNativeFlavors => '本地风味';

  @override
  String get placeDetailsCuratedStays => '精选住宿';

  @override
  String get placeDetailsCommunityMoments => '社区瞬间';

  @override
  String get placeDetailsGallery => '图库';

  @override
  String get placeDetailsFindNearMe => '附近找找';

  @override
  String get placeDetailsViewMap => '查看地图';

  @override
  String get placeDetailsViewMore => '查看更多';

  @override
  String get placeDetailsViewFeed => '查看动态';

  @override
  String get placeDetailsViewAll => '查看全部';

  @override
  String get placeDetailsStartJourney => '开启旅程';

  @override
  String get communityTabFollowing => '关注';

  @override
  String get communityTabLatest => '最新';

  @override
  String get communityTabPopular => '热门';

  @override
  String get communityTabNearby => '附近';

  @override
  String get communitySearchTooltip => '搜索';

  @override
  String get communityCreatePostTitle => '发布帖子';

  @override
  String get communityCreatePostTitleOptional => '标题（可选）';

  @override
  String get communityCreatePostTitleHint => '输入一个简短标题';

  @override
  String get communityCreatePostContentRequired => '内容（必填）';

  @override
  String get communityCreatePostContentHint => '写点今天的见闻吧';

  @override
  String get communityCreatePostAddImage => '添加图片';

  @override
  String get communityCreatePostAddLocation => '添加地点';

  @override
  String get communityCreatePostRemoveLocation => '移除地点';

  @override
  String get communityCreatePostDragToRemove => '拖到这里删除';

  @override
  String communityCreatePostSelectedImages(Object current, Object max) {
    return '已选图片（$current/$max）';
  }

  @override
  String communityCreatePostImageLimitReached(Object max) {
    return '一个帖子最多只能选择 $max 张图片，已为你保留前 $max 张。';
  }

  @override
  String get communityCreatePostRemoveImage => '删除图片';

  @override
  String communityImageMoreCount(Object count) {
    return '+$count';
  }

  @override
  String communityImageMoreHint(Object count) {
    return '到帖子详情中查看另外 $count 张图片';
  }

  @override
  String get commonImageViewerClose => '关闭图片查看器';

  @override
  String commonImageViewerPageLabel(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get communityCreatePostSubmit => '发送';

  @override
  String get communityLocationSearchTitle => '搜索地点';

  @override
  String get communityLocationSearchHint => '输入城市名或地点名';

  @override
  String get communityLocationSearchEmptyHint => '输入关键词后即可搜索地点。';

  @override
  String get communityLocationSearchEmptyResult => '没有找到匹配的地点。';

  @override
  String get communityLocationSearchFailed => '地点搜索失败，请稍后再试。';

  @override
  String get communityRetry => '重试';

  @override
  String get communityLoadFailed => '帖子加载失败，请稍后再试。';

  @override
  String get communityEmptyPosts => '暂时还没有帖子。';

  @override
  String get communityContentEmpty => '请输入帖子内容。';

  @override
  String get communityPublishFailed => '帖子发布失败，请稍后再试。';

  @override
  String get communityCommentsEmpty => '暂时还没有评论。';

  @override
  String get communityCommentHint => '写下你的评论...';

  @override
  String get communityCommentSend => '发送';

  @override
  String get communityReplyAction => '回复';

  @override
  String get communityCancelReply => '取消';

  @override
  String get communityHideReplies => '收起回复';

  @override
  String get communityCommentEmpty => '请输入评论内容。';

  @override
  String get communityCommentSubmitFailed => '评论发送失败，请稍后再试。';

  @override
  String communityReplyingToUser(Object name) {
    return '正在回复 $name';
  }

  @override
  String communityViewAllReplies(Object count) {
    return '查看全部 $count 条回复';
  }

  @override
  String communityReplyPreview(Object userName, Object replyToUserName, Object content) {
    return '$userName 回复 $replyToUserName：$content';
  }

  @override
  String get communityPostDetailTitle => '帖子详情';

  @override
  String get communityCommentsTitle => '评论';

  @override
  String get communityDeleteAction => '删除';

  @override
  String get communityDeletePostAction => '删除帖子';

  @override
  String get communityDeleteCommentAction => '删除评论';

  @override
  String get communityDeletePostTitle => '确认删除这条帖子？';

  @override
  String get communityDeletePostMessage => '删除后将无法恢复。';

  @override
  String get communityDeleteCommentTitle => '确认删除这条评论？';

  @override
  String get communityDeleteCommentMessage => '删除后将无法恢复。';

  @override
  String get communityDeletePostFailed => '删除帖子失败，请稍后再试。';

  @override
  String get communityDeleteCommentFailed => '删除评论失败，请稍后再试。';

  @override
  String get communityUserProfileTitle => '用户主页';

  @override
  String get communityFollowAction => '关注';

  @override
  String get communityUnfollowAction => '取消关注';

  @override
  String get communityFollowFailed => '关注状态更新失败，请稍后再试。';

  @override
  String get communityLikeFailed => '点赞状态更新失败，请稍后再试。';

  @override
  String get communityStatPosts => '帖子';

  @override
  String get communityStatFollowers => '粉丝';

  @override
  String get communityStatFollowing => '关注';

  @override
  String get communityStatLikesReceived => '获赞';

  @override
  String get communityFollowingListTitle => '关注列表';

  @override
  String get communityFollowingListEmpty => 'TA 还没有关注任何人。';

  @override
  String get communityUserPostsTitle => '发布的帖子';

  @override
  String get communityPostNotFound => '未找到该帖子。';

  @override
  String get communityUserNotFound => '未找到该用户。';

  @override
  String get communityMockUserLuna => '露娜';

  @override
  String get communityMockUserNoah => '诺亚';

  @override
  String get communityMockUserIris => '伊里斯';

  @override
  String get communityMockPostOneTitle => '夜市随手拍攻略';

  @override
  String get communityMockPostOneSummary => '小吃、霓虹和一条值得收藏的夜市路线。';

  @override
  String get communityMockPostOneContent => '我从老桥一路走到江边夜市，意外发现这条拍照路线非常顺。入口附近的海鲜摊在天黑后会很快排队，不过手作甜品车反而还没那么多人。如果你喜欢暖色灯光和轻松的街拍氛围，这一角真的值得多停留一会。';

  @override
  String get communityMockPostOneTime => '2 小时前';

  @override
  String get communityMockPostOneLocation => '黄浦江边';

  @override
  String get communityMockPostTwoTitle => '江边晨跑记录';

  @override
  String get communityMockPostTwoSummary => '风很轻，步道很开阔，日出的倒影也很好看。';

  @override
  String get communityMockPostTwoContent => '今天早上 6 点半去滨江跑步，整条路线都很安静，空气也很舒服。沿路有几处可以直接看到城市天际线的长椅，不管是慢跑还是坐下来放空十分钟，体验都很好。';

  @override
  String get communityMockPostTwoTime => '5 小时前';

  @override
  String get communityMockPostTwoLocation => '西岸滨江';

  @override
  String get communityMockPostThreeTitle => '窗边光线最好的咖啡店';

  @override
  String get communityMockPostThreeSummary => '阳光很软，座位安静，很适合慢慢待一个下午。';

  @override
  String get communityMockPostThreeContent => '这家咖啡店我几乎待了一整个下午，因为窗边的光线会缓慢变化，拍人和拍桌面都很好看。如果你想找一个适合看书、发呆或者和朋友轻声聊天的地方，二楼角落的位置最值得先占下来。';

  @override
  String get communityMockPostThreeTime => '昨天';

  @override
  String get communityMockPostThreeLocation => '安福路';
}
