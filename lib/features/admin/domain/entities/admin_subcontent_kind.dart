enum AdminSubcontentKind {
  experiences('experiences'),
  flavors('flavors'),
  stays('stays'),
  gallery('gallery');

  const AdminSubcontentKind(this.collectionName);

  final String collectionName;

  static AdminSubcontentKind? fromRaw(String raw) {
    for (final kind in AdminSubcontentKind.values) {
      if (kind.collectionName == raw) {
        return kind;
      }
    }
    return null;
  }
}
