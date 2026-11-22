/// Schema validation utilities for QR payload types.
library schema_validator;

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

class SchemaValidator {
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  static final RegExp _vpaRegExp = RegExp(
    r"^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$",
  );

  static final RegExp _ibanRegExp = RegExp(
    r"^[A-Z]{2}[0-9]{2}[A-Z0-9]{4,30}$",
  );

  static ValidationResult validateUrl(String url) {
    if (url.trim().isEmpty) return const ValidationResult.invalid('URL cannot be empty');
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const ValidationResult.invalid('Invalid URL structure');
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return ValidationResult.invalid('Unsupported or unsafe URL scheme: $scheme');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateEmail(String email) {
    if (email.trim().isEmpty) return const ValidationResult.invalid('Email cannot be empty');
    if (!_emailRegExp.hasMatch(email.trim())) {
      return const ValidationResult.invalid('Invalid email address format');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateCoordinates(double lat, double lng) {
    if (lat < -90.0 || lat > 90.0) {
      return const ValidationResult.invalid('Latitude must be between -90 and 90');
    }
    if (lng < -180.0 || lng > 180.0) {
      return const ValidationResult.invalid('Longitude must be between -180 and 180');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateUpiVpa(String vpa) {
    if (vpa.trim().isEmpty) return const ValidationResult.invalid('UPI VPA cannot be empty');
    if (!_vpaRegExp.hasMatch(vpa.trim())) {
      return const ValidationResult.invalid('Invalid UPI VPA format (expected name@bank)');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateIban(String iban) {
    final clean = iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (clean.length < 15 || clean.length > 34) {
      return const ValidationResult.invalid('IBAN length must be between 15 and 34 characters');
    }
    if (!_ibanRegExp.hasMatch(clean)) {
      return const ValidationResult.invalid('Invalid IBAN format');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateBase32Secret(String secret) {
    final clean = secret.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (clean.isEmpty) return const ValidationResult.invalid('Secret cannot be empty');
    final validChars = RegExp(r'^[A-Z2-7=]+$');
    if (!validChars.hasMatch(clean)) {
      return const ValidationResult.invalid('Secret must be valid Base32 characters (A-Z, 2-7)');
    }
    return const ValidationResult.valid();
  }
}
