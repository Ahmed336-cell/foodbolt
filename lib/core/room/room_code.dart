/// Room invite codes: 6 uppercase A–Z / 2–9 (no I/O/0/1).
class RoomCode {
  RoomCode._();

  static const length = 6;

  /// Alphabet used when generating codes (avoids ambiguous I/O/0/1).
  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Uppercase + strip spaces/dashes/other junk.
  static String normalize(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static bool isComplete(String raw) => extract(raw).length == length;

  /// Pull a real 6-char room code out of free text / invite paste.
  static String extract(String raw) {
    final upper = raw.toUpperCase();

    final labeled = RegExp(
      r'(?:CODE|كود)\s*[:：]?\s*([A-Z0-9]{6})',
    ).firstMatch(upper);
    if (labeled != null) {
      return normalize(labeled.group(1)!);
    }

    final joinPath = RegExp(
      r'JOIN[/:]([A-Z0-9]{6})',
    ).firstMatch(upper.replaceAll('%2F', '/'));
    if (joinPath != null) {
      return normalize(joinPath.group(1)!);
    }

    final normalized = normalize(raw);
    if (normalized.length == length) return normalized;

    // Prefer tokens that only use the generator alphabet (no I/O/0/1).
    final safe = RegExp('([$alphabet]{$length})').allMatches(normalized);
    if (safe.isNotEmpty) return safe.last.group(1)!;

    final any = RegExp(r'([A-Z0-9]{6})').allMatches(normalized);
    if (any.isNotEmpty) return any.last.group(1)!;

    return normalized.length <= length
        ? normalized
        : normalized.substring(normalized.length - length);
  }
}
