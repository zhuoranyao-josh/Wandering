import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_guide_step_page.dart';

class AppGuideStep {
  const AppGuideStep({
    required this.id,
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final String id;
  final String title;
  final String description;
  final String imageAsset;
}

class AppGuideDialog extends StatefulWidget {
  const AppGuideDialog({
    super.key,
    required this.steps,
    this.onFinish,
    this.onSkip,
  });

  final List<AppGuideStep> steps;
  final Future<void> Function()? onFinish;
  final Future<void> Function()? onSkip;

  @override
  State<AppGuideDialog> createState() => _AppGuideDialogState();
}

class _AppGuideDialogState extends State<AppGuideDialog> {
  late final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isClosing = false;

  bool get _isLastStep => _currentIndex == widget.steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (t == null) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.padding.vertical - 44;
    final maxDialogHeight = availableHeight.clamp(360.0, 650.0).toDouble();
    final dialogHeight = (mediaQuery.size.height * 0.82)
        .clamp(360.0, maxDialogHeight)
        .toDouble();

    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 28,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: dialogHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildHeader(t),
                        const SizedBox(height: 16),
                        // PageView 只承载图片和说明，不驱动真实页面跳转，保证引导可以随时关闭。
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.steps.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final step = widget.steps[index];
                              return AppGuideStepPage(
                                imageAsset: step.imageAsset,
                                title: step.title,
                                description: step.description,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFooter(t),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t) {
    return Row(
      children: [
        Text(
          t.guideProgress(_currentIndex + 1, widget.steps.length),
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isClosing ? null : () => _close(widget.onSkip),
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFF6D28D9),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: Text(t.guideSkip),
        ),
      ],
    );
  }

  Widget _buildFooter(AppLocalizations t) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _currentIndex == 0 || _isClosing ? null : _goBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: const Color(0xFF6D28D9),
                disabledForegroundColor: const Color(0xFFB8AEC8),
                side: BorderSide(
                  color: _currentIndex == 0
                      ? const Color(0xFFE5E0EF)
                      : const Color(0xFFD8C7FF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: Text(t.guideBack),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FilledButton(
              onPressed: _isClosing
                  ? null
                  : _isLastStep
                  ? () => _close(widget.onFinish)
                  : _goNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD8D1E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: Text(_isLastStep ? t.guideGotIt : t.guideNext),
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _close(Future<void> Function()? callback) async {
    if (_isClosing) {
      return;
    }

    setState(() {
      _isClosing = true;
    });

    // 先写入已读状态再关闭弹窗，避免用户下次进入地图页又自动弹出。
    await callback?.call();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}
