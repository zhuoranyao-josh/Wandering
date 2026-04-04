import 'package:flutter/material.dart';

/// 按钮样式枚举
/// 用来控制按钮外观
enum AppButtonStyleType {
  blackFilled, // 黑底白字
  whiteOutlined, // 白底黑边黑字
}

class AppButton extends StatelessWidget {
  // 按钮显示文字
  final String text;

  // 点击事件
  final VoidCallback? onPressed;

  // 是否正在加载
  final bool isLoading;

  // 按钮样式
  final AppButtonStyleType styleType;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.styleType = AppButtonStyleType.blackFilled,
  });

  @override
  Widget build(BuildContext context) {
    // 统一按钮高度
    const double buttonHeight = 50;

    // 根据不同样式，返回不同按钮
    switch (styleType) {
      case AppButtonStyleType.blackFilled:
        return SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(text),
          ),
        );

      case AppButtonStyleType.whiteOutlined:
        return SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(text),
          ),
        );
    }
  }
}
