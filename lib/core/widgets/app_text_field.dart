import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  // 输入框左上方显示的文字，比如“邮箱”“密码”
  final String label;

  // 控制输入框里的内容
  final TextEditingController controller;

  // 是否隐藏输入内容，密码框一般要 true
  final bool obscureText;

  // 键盘类型，比如邮箱输入时用 emailAddress
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,

      // 这里统一定义输入框样式
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
