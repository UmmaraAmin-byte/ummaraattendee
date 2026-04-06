class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}

enum PasswordStrength { weak, fair, strong, veryStrong }

class PasswordRequirement {
  final String label;
  final bool met;
  const PasswordRequirement({required this.label, required this.met});
}

class PasswordValidator {
  static const int _minLength = 8;

  static bool _hasUppercase(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool _hasLowercase(String v) => v.contains(RegExp(r'[a-z]'));
  static bool _hasDigit(String v) => v.contains(RegExp(r'[0-9]'));
  static bool _hasSpecial(String v) =>
      v.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:''",.<>?/\\`~]'));

  static List<PasswordRequirement> getRequirements(String value) {
    return [
      PasswordRequirement(
        label: 'At least $_minLength characters',
        met: value.length >= _minLength,
      ),
      PasswordRequirement(
        label: 'One uppercase letter (A–Z)',
        met: _hasUppercase(value),
      ),
      PasswordRequirement(
        label: 'One lowercase letter (a–z)',
        met: _hasLowercase(value),
      ),
      PasswordRequirement(
        label: 'One number (0–9)',
        met: _hasDigit(value),
      ),
      PasswordRequirement(
        label: 'One special character (!@#\$%^&*…)',
        met: _hasSpecial(value),
      ),
    ];
  }

  static PasswordStrength getStrength(String value) {
    if (value.isEmpty) return PasswordStrength.weak;
    final reqs = getRequirements(value);
    final metCount = reqs.where((r) => r.met).length;
    if (metCount <= 1) return PasswordStrength.weak;
    if (metCount == 2) return PasswordStrength.fair;
    if (metCount <= 4) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    final reqs = getRequirements(value);
    final unmet = reqs.where((r) => !r.met).map((r) => r.label).toList();
    if (unmet.isEmpty) return null;
    return 'Password must include: ${unmet.join(', ')}.';
  }

  static bool isValid(String value) => validate(value) == null;
}
