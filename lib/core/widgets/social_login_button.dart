import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  // 按钮文字，比如“使用 Google 登录”
  final String text;

  // 左侧图标
  final Widget icon;

  // 点击事件
  final VoidCallback? onPressed;

  // 是否正在加载
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [icon, const SizedBox(width: 10), Text(text)],
              ),
      ),
    );
  }
}
