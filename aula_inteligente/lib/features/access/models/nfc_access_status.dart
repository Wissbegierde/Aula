enum NfcAccessStatus {
  granted,
  denied,
  badRead,
}

class NfcAccessOutcome {
  final NfcAccessStatus status;
  final String title;
  final String message;
  final String? tagId;
  final String? userName;

  const NfcAccessOutcome({
    required this.status,
    required this.title,
    required this.message,
    this.tagId,
    this.userName,
  });
}
