class AdminSettings {
  final bool newConsumerAlert;
  final int lastUserCount;

  const AdminSettings({
    this.newConsumerAlert = true,
    this.lastUserCount = 0,
  });

  AdminSettings copyWith({
    bool? newConsumerAlert,
    int? lastUserCount,
  }) {
    return AdminSettings(
      newConsumerAlert: newConsumerAlert ?? this.newConsumerAlert,
      lastUserCount: lastUserCount ?? this.lastUserCount,
    );
  }
}
