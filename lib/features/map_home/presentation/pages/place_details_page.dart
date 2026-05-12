import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/checklist/domain/entities/checklist_destination_snapshot.dart';
import '../../../../features/checklist/presentation/controllers/checklist_controller.dart';
import '../../../community/domain/entities/post.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/place_detail_controller.dart';
import '../models/place_detail_ui_model.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/community_card.dart';
import '../widgets/experience_card.dart';
import '../widgets/flavor_list_item.dart';
import '../widgets/gallery_grid.dart';
import '../widgets/info_chips_row.dart';
import '../widgets/place_hero_section.dart';
import '../widgets/place_section_header.dart';
import '../widgets/stay_card.dart';

class PlaceDetailsPage extends StatefulWidget {
  const PlaceDetailsPage({super.key, required this.placeId, this.initialModel});

  final String placeId;
  final PlaceDetailUiModel? initialModel;

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  static const double _screenHorizontalPadding = 16;
  static const double _sectionSpacing = 28;
  static const double _bottomActionReservedSpace = 116;
  static const int _descriptionCollapsedMaxLines = 5;
  static const TextStyle _descriptionTextStyle = TextStyle(
    fontSize: 15,
    height: 1.75,
    color: Color(0xFF374151),
    fontWeight: FontWeight.w500,
  );

  late final ChecklistController _checklistController =
      ServiceLocator.checklistController;
  late final PlaceDetailController _placeDetailController =
      PlaceDetailController(
        repository: ServiceLocator.mapHomeRepository,
        communityRepository: ServiceLocator.communityRepository,
      );
  bool _isDescriptionExpanded = false;
  bool _isCreatingChecklist = false;

  PlaceDetailUiModel get _model =>
      _placeDetailController.detailModel ??
      widget.initialModel ??
      PlaceDetailUiModel(placeId: widget.placeId);

  @override
  void initState() {
    super.initState();
    _placeDetailController.loadPlaceDetail(widget.placeId, forceRefresh: true);
  }

  @override
  void didUpdateWidget(covariant PlaceDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeId != widget.placeId) {
      _isDescriptionExpanded = false;
      _placeDetailController.loadPlaceDetail(
        widget.placeId,
        forceRefresh: true,
      );
    }
  }

  @override
  void dispose() {
    _placeDetailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: _placeDetailController,
      builder: (context, _) {
        final languageCode = Localizations.localeOf(context).languageCode;
        final model = _model;
        final resolvedName = model.resolvePlaceName(languageCode);
        final resolvedQuote = model.resolveQuote(languageCode);
        final description = model.resolveDescription(languageCode) ?? '';
        final hasDescription = description.isNotEmpty;
        final communityPosts = _placeDetailController.communityPosts;
        final shouldShowCommunitySection =
            _placeDetailController.isCommunityLoading ||
            communityPosts.isNotEmpty;

        if (_placeDetailController.isLoading &&
            _placeDetailController.detailModel == null &&
            widget.initialModel == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: <Widget>[
              // 可滚动内容区预留底部空间，避免被固定操作栏遮挡。
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: _bottomActionReservedSpace,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    PlaceHeroSection(
                      onBack: _handleBackPressed,
                      backTooltip: t.activityBack,
                      imageUrl: model.heroImageUrl,
                      country: model.country,
                      placeName: resolvedName,
                      showLocationLine:
                          model.placeType == PlaceDetailsType.attraction,
                      locationLine: model.locationLine,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _screenHorizontalPadding,
                        18,
                        _screenHorizontalPadding,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          InfoChipsRow(
                            tagline: resolvedQuote,
                            chips: _buildInfoChips(model),
                          ),
                          const SizedBox(height: 24),
                          if (hasDescription) ...<Widget>[
                            _buildDescriptionSection(
                              description: description,
                              expandLabel: t.placeDetailsDescriptionExpand,
                              collapseLabel: t.placeDetailsDescriptionCollapse,
                            ),
                            const SizedBox(height: _sectionSpacing),
                          ],
                          PlaceSectionHeader(
                            title: t.placeDetailsUniqueExperiences,
                          ),
                          const SizedBox(height: 12),
                          _buildExperiencesSection(
                            model.experiences,
                            languageCode,
                            t,
                          ),
                          const SizedBox(height: _sectionSpacing),
                          PlaceSectionHeader(
                            title: t.placeDetailsNativeFlavors,
                            actionText: t.placeDetailsViewMore,
                            onActionTap: _noop,
                          ),
                          // 本地风味区收紧标题与内容间距，减少视觉断层。
                          const SizedBox(height: 2),
                          _buildFlavorsSection(model.flavors, languageCode),
                          const SizedBox(height: _sectionSpacing),
                          PlaceSectionHeader(
                            title: t.placeDetailsCuratedStays,
                            actionText: t.placeDetailsViewMore,
                            onActionTap: _noop,
                          ),
                          const SizedBox(height: 12),
                          _buildStaysSection(model.stays, languageCode),
                          const SizedBox(height: _sectionSpacing),
                          if (shouldShowCommunitySection) ...<Widget>[
                            PlaceSectionHeader(
                              title: t.placeDetailsCommunityMoments,
                              actionText: t.placeDetailsViewFeed,
                              onActionTap: _openCommunityFeed,
                            ),
                            const SizedBox(height: 12),
                            _buildCommunitySection(communityPosts),
                            const SizedBox(height: _sectionSpacing),
                          ],
                          PlaceSectionHeader(
                            title: t.placeDetailsGallery,
                            actionText: t.placeDetailsViewAll,
                            onActionTap: _noop,
                          ),
                          // 图库区同样缩小标题与网格间距，保持上下节奏一致。
                          const SizedBox(height: 6),
                          GalleryGrid(
                            imageUrls: model.galleryImageUrls,
                            overflowCount: model.galleryOverflowCount,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: BottomActionBar(
                    startJourneyLabel: t.placeDetailsStartJourney,
                    isStartJourneyLoading: _isCreatingChecklist,
                    onStartJourney: _handleStartJourney,
                    onFavorite: _noop,
                    onShare: _noop,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionSection({
    required String description,
    required String expandLabel,
    required String collapseLabel,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 通过真实排版宽度判断是否溢出，避免仅按字符数导致“明明被省略却无法展开”。
        final hasOverflow = _hasDescriptionOverflow(
          context: context,
          description: description,
          maxWidth: constraints.maxWidth,
        );
        final showToggleAction = hasOverflow || _isDescriptionExpanded;
        final actionLabel = _isDescriptionExpanded
            ? collapseLabel
            : expandLabel;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              description,
              maxLines: _isDescriptionExpanded
                  ? null
                  : _descriptionCollapsedMaxLines,
              overflow: _isDescriptionExpanded
                  ? TextOverflow.visible
                  : TextOverflow.fade,
              style: _descriptionTextStyle,
            ),
            if (showToggleAction)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.only(top: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _hasDescriptionOverflow({
    required BuildContext context,
    required String description,
    required double maxWidth,
  }) {
    if (_isDescriptionExpanded || maxWidth <= 0) {
      return false;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: description, style: _descriptionTextStyle),
      textDirection: Directionality.of(context),
      maxLines: _descriptionCollapsedMaxLines,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  Widget _buildExperiencesSection(
    List<PlaceExperienceUiModel> items,
    String languageCode,
    AppLocalizations t,
  ) {
    final hasItems = items.isNotEmpty;
    final itemCount = hasItems ? items.length : 2;

    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (!hasItems) {
            return const ExperienceCard();
          }
          final item = items[index];
          final title = item.resolveTitle(languageCode);
          final description = item.resolveDescription(languageCode);
          final featureName = item.resolveFeatureName(languageCode);
          return ExperienceCard(
            badge: _experienceBadgeLabel(item, languageCode, t),
            featureName: featureName,
            title: title,
            description: description,
            onTap: () => _showExperienceDetails(
              badge: _experienceBadgeLabel(item, languageCode, t),
              featureName: featureName,
              title: title,
              description: description,
            ),
          );
        },
      ),
    );
  }

  String _experienceBadgeLabel(
    PlaceExperienceUiModel item,
    String languageCode,
    AppLocalizations t,
  ) {
    switch (item.normalizedBadgeCode) {
      case 'explore':
        return t.experienceBadgeExplore;
      case 'culture':
        return t.experienceBadgeCulture;
      case 'local':
        return t.experienceBadgeLocal;
      case 'scenic':
        return t.experienceBadgeScenic;
      case 'photo':
        return t.experienceBadgePhoto;
      case 'nature':
        return t.experienceBadgeNature;
      case 'night':
        return t.experienceBadgeNight;
      case 'guided':
        return t.experienceBadgeGuided;
    }
    return item.resolveBadge(languageCode)?.trim() ?? '';
  }

  Future<void> _showExperienceDetails({
    required String badge,
    required String? featureName,
    required String? title,
    required String? description,
  }) {
    final featureNameText = featureName?.trim() ?? '';
    final titleText = title?.trim() ?? '';
    final descriptionText = description?.trim() ?? '';
    if (featureNameText.isEmpty &&
        titleText.isEmpty &&
        descriptionText.isEmpty) {
      return Future<void>.value();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (badge.trim().isNotEmpty)
                        Text(
                          badge.trim().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (featureNameText.isNotEmpty)
                            Text(
                              featureNameText,
                              style: const TextStyle(
                                fontSize: 22,
                                height: 1.18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          if (titleText.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            Text(
                              titleText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                          if (descriptionText.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 14),
                            Text(
                              descriptionText,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.48,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlavorsSection(
    List<PlaceFlavorUiModel> items,
    String languageCode,
  ) {
    final hasItems = items.isNotEmpty;
    final itemCount = hasItems ? items.length : 2;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 禁用 ListView 默认媒体内边距，避免首项被意外下推。
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
      itemBuilder: (context, index) {
        if (!hasItems) {
          return const FlavorListItem();
        }
        final item = items[index];
        return FlavorListItem(
          imageUrl: item.imageUrl,
          name: item.resolveName(languageCode),
          subtitle: item.resolveSubtitle(languageCode),
        );
      },
    );
  }

  Widget _buildStaysSection(List<PlaceStayUiModel> items, String languageCode) {
    final hasItems = items.isNotEmpty;
    final itemCount = hasItems ? items.length : 1;

    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (!hasItems) {
            return const StayCard();
          }
          final item = items[index];
          return StayCard(
            imageUrl: item.imageUrl,
            badge: item.resolveBadge(languageCode),
            name: item.resolveName(languageCode),
            priceRange: item.formattedPriceRange,
          );
        },
      ),
    );
  }

  Widget _buildCommunitySection(List<Post> posts) {
    if (_placeDetailController.isCommunityLoading) {
      return const SizedBox(
        height: 236,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          return CommunityCard(
            imageUrl: post.coverImageUrl,
            avatarUrl: post.authorAvatarUrl,
            userName: _displayUserName(post),
            caption: _communityCaption(post),
            likeCount: post.likeCount,
            onTap: post.id.trim().isEmpty
                ? null
                : () => _openCommunityPost(post.id),
          );
        },
      ),
    );
  }

  List<String> _buildInfoChips(PlaceDetailUiModel model) {
    final chips = <String>[
      model.bestSeason ?? '',
      model.recommendedDuration ?? '',
      model.category ?? '',
      ...model.tags,
    ];
    return chips
        .map((chip) => chip.trim())
        .where((chip) => chip.isNotEmpty)
        .toList();
  }

  void _handleBackPressed() {
    if (context.canPop()) {
      context.pop();
    }
  }

  void _openCommunityFeed() {
    context.go(AppRouter.community);
  }

  void _openCommunityPost(String postId) {
    final trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) {
      return;
    }
    context.push(AppRouter.communityPostDetail(trimmedPostId));
  }

  Future<void> _handleStartJourney() async {
    if (_isCreatingChecklist) {
      return;
    }

    final t = AppLocalizations.of(context);
    if (t == null) {
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final destination =
        _model.resolvePlaceName(languageCode)?.trim() ?? widget.placeId;

    setState(() {
      _isCreatingChecklist = true;
    });

    try {
      // 创建成功后直接跳转到 checklist 详情，避免用户还要再点一次列表项。
      final checklistId = await _checklistController.createChecklistFromPlace(
        placeId: widget.placeId,
        destination: destination,
        coverImageUrl: _model.heroImageUrl,
        destinationNames: _buildDestinationNamesFromModel(destination),
        destinationSnapshot: _model.latitude != null && _model.longitude != null
            ? ChecklistDestinationSnapshot(
                name: destination,
                latitude: _model.latitude!,
                longitude: _model.longitude!,
                coverImageUrl: _model.heroImageUrl,
                provider: ChecklistDestinationSourceType.official,
                providerPlaceId: widget.placeId,
                placeLevel: 'city',
                country: _model.country,
                region: _model.region,
              )
            : null,
      );
      if (!mounted) {
        return;
      }

      if (checklistId == null || checklistId.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.checklistCreateFailed)));
        return;
      }

      context.go(AppRouter.checklistDetail(checklistId));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChecklist = false;
        });
      }
    }
  }

  static void _noop() {}

  String _communityCaption(Post post) {
    final title = post.title?.trim() ?? '';
    if (title.isNotEmpty) {
      return title;
    }
    return post.content.replaceAll('\n', ' ').trim();
  }

  String _displayUserName(Post post) {
    final authorName = post.authorName.trim();
    if (authorName.isNotEmpty) {
      return authorName;
    }
    return post.authorId.trim();
  }

  Map<String, String> _buildDestinationNamesFromModel(String fallbackName) {
    final result = <String, String>{};
    final zh = _model.placeNameByLanguage['zh']?.trim() ?? '';
    final en = _model.placeNameByLanguage['en']?.trim() ?? '';
    if (zh.isNotEmpty) {
      result['zh'] = zh;
    }
    if (en.isNotEmpty) {
      result['en'] = en;
    }

    if (result.isEmpty && fallbackName.trim().isNotEmpty) {
      result['en'] = fallbackName.trim();
    }
    return result;
  }
}
