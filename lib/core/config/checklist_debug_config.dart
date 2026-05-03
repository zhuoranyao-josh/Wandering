import 'package:flutter/foundation.dart';

/// Checklist 计划链路日志开关：
/// - summary: 默认开启（仅 Debug 模式）
/// - verbose: 默认关闭，按需手动打开查看大段细节
const bool kChecklistSummaryLogs = kDebugMode;
const bool kChecklistVerboseLogs = false;
