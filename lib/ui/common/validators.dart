class Validators {
  static String? notEmpty(String? v, {String label = 'Field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || !v.contains('@')) return 'Enter a valid email';
    return null;
  }

  static String? minLength(String? v, int length, {String label = 'Field'}) {
    if (v == null || v.length < length) return '$label must be at least $length characters';
    return null;
  }
}