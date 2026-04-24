class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.destination,
    required this.placeId,
    required this.coverImageUrl,
    this.startDate,
    this.endDate,
    this.statusText,
  });

  final String id;
  final String destination;
  final String placeId;
  final String coverImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? statusText;

  ChecklistItem copyWith({
    String? id,
    String? destination,
    String? placeId,
    String? coverImageUrl,
    DateTime? startDate,
    DateTime? endDate,
    String? statusText,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      placeId: placeId ?? this.placeId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statusText: statusText ?? this.statusText,
    );
  }
}
