import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/checklist_item.dart';

class ChecklistCard extends StatelessWidget {
  const ChecklistCard({super.key, required this.item, required this.onTap});

  final ChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCoverImage = item.coverImageUrl.trim().isNotEmpty;
    final hasStatusText = item.statusText?.trim().isNotEmpty ?? false;
    final dateRange = _buildDateRange(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: EdgeInsets.fromLTRB(12, 12, hasStatusText ? 88 : 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (hasCoverImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.coverImageUrl.trim(),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          item.destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (dateRange != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateRange,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (hasStatusText)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text(
                    item.statusText!.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _buildDateRange(BuildContext context) {
    final startDate = item.startDate;
    final endDate = item.endDate;
    if (startDate == null && endDate == null) {
      return null;
    }

    final localeName = Localizations.localeOf(context).toLanguageTag();
    final formatter = DateFormat.yMMMd(localeName);

    if (startDate != null && endDate != null) {
      return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
    }

    if (startDate != null) {
      return formatter.format(startDate);
    }

    return formatter.format(endDate!);
  }
}
