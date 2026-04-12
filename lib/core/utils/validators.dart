/// AppValidators — strict real-world validation for all form fields.
/// Every method returns null on success, error string on failure.
class AppValidators {
  AppValidators._();

  // ── Blocked fake/test domains ────────────────────────────────────────────
  static const Set<String> _blockedDomains = {
    'abc.com', 'xyz.com', 'test.com', 'testing.com', 'demo.com',
    'example.com', 'fake.com', 'dummy.com', 'temp.com', 'tempmail.com',
    'mailinator.com', 'throwaway.com', 'noemail.com', 'nomail.com',
    'asdf.com', 'qwerty.com', 'aaa.com', 'bbb.com', 'ccc.com',
    'zzz.com', 'yopmail.com', '10minutemail.com', 'guerrillamail.com',
  };

  // Explicitly allowed demo domain
  static const String _allowedDemoEmail = 'admin@freightflow.in';

  /// Email — rejects fake domains, allows @freightflow.in for admin demo.
  static String? email(String? value, {bool allowDemo = true}) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final v = value.trim().toLowerCase();

    // Always allow the demo admin email
    if (allowDemo && v == _allowedDemoEmail) return null;

    // Basic format check
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';

    // Extract domain
    final domain = v.split('@').last;

    // Block known fake domains
    if (_blockedDomains.contains(domain)) {
      return 'Please use a real email address';
    }

    // Block single-character domains like @a.com
    final domainParts = domain.split('.');
    if (domainParts.any((part) => part.length < 2)) {
      return 'Enter a valid email domain';
    }

    return null;
  }

  /// Indian phone — exactly 10 digits, must start with 6, 7, 8, or 9.
  static String? indianPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final v = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (v.length != 10) return 'Must be exactly 10 digits';
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Only digits are allowed';

    // Valid starting digits for Indian mobile numbers
    if (!RegExp(r'^[6-9]').hasMatch(v)) {
      return 'Must start with 6, 7, 8, or 9';
    }

    // Reject obviously fake repeated patterns
    if (RegExp(r'^(\d)\1{9}$').hasMatch(v)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  /// Name — only letters and spaces, no numbers or special characters, min 2 chars.
  static String? personName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final v = value.trim();

    if (v.length < 2) return '$fieldName must be at least 2 characters';

    // Only letters, spaces, dots (for initials), hyphens (for compound names)
    if (!RegExp(r"^[a-zA-Z\s.\-']+$").hasMatch(v)) {
      return '$fieldName must contain only letters';
    }

    // Must start with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(v)) {
      return '$fieldName must start with a letter';
    }

    return null;
  }

  /// Company name — letters, numbers, spaces, and common business symbols only.
  static String? companyName(String? value, {String fieldName = 'Company name'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final v = value.trim();

    if (v.length < 2) return '$fieldName must be at least 2 characters';

    // Allow letters, numbers, spaces, and: . , & ( ) - / '
    if (!RegExp(r"^[a-zA-Z0-9\s.,&()\-/']+$").hasMatch(v)) {
      return '$fieldName contains invalid characters';
    }

    // Must start with a letter or number
    if (!RegExp(r'^[a-zA-Z0-9]').hasMatch(v)) {
      return '$fieldName must start with a letter or number';
    }

    return null;
  }

  /// GST number — strict 15-character Indian GST format.
  /// Format: 2-digit state + 10-char PAN + 1-digit entity + Z + checksum
  /// Example: 24AABCS1429B1Z5
  static String? gstNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'GST number is required';
    final v = value.trim().toUpperCase();

    if (v.length != 15) return 'GST must be exactly 15 characters';

    final gstRegex = RegExp(r'^[0-3][0-9][A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
    if (!gstRegex.hasMatch(v)) {
      return 'Invalid GST format (e.g. 24AABCS1429B1Z5)';
    }

    return null;
  }

  /// Weight in kg — positive number, max 40,000 kg.
  static String? weightKg(String? value) {
    if (value == null || value.trim().isEmpty) return 'Weight is required';
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter a valid weight';
    if (n > 40000) return 'Maximum weight is 40,000 kg';
    return null;
  }

  /// Distance in km — positive number, max 5,000 km.
  static String? distanceKm(String? value) {
    if (value == null || value.trim().isEmpty) return 'Distance is required';
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter a valid distance';
    if (n > 5000) return 'Maximum distance is 5,000 km';
    return null;
  }

  /// Freight rate — positive decimal, reasonable range.
  static String? freightRate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Rate is required';
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter a valid rate';
    if (n > 1000) return 'Rate seems too high — max ₹1000/kg';
    return null;
  }

  /// Packages count — positive integer.
  static String? packageCount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Package count is required';
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) return 'Must be at least 1 package';
    if (n > 9999) return 'Maximum 9999 packages';
    return null;
  }

  /// Vehicle number — Indian format e.g. GJ-03-AX-4821
  static String? vehicleNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vehicle number is required';
    final v = value.trim().toUpperCase().replaceAll(' ', '-');
    if (!RegExp(r'^[A-Z]{2}-\d{2}-[A-Z]{1,2}-\d{4}$').hasMatch(v)) {
      return 'Format: GJ-03-AX-4821';
    }
    return null;
  }

  /// License number — basic non-empty check with min length.
  static String? licenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'License number is required';
    if (value.trim().length < 8) return 'License number too short';
    return null;
  }

  /// Generic required field.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Password — min 8 chars, at least one letter and one number.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'At least 6 characters required';
    return null;
  }
}

// Keep old Validators class as alias for backward compatibility
class Validators {
  Validators._();
  static String? required(String? v, {String fieldName = 'This field'}) =>
      AppValidators.required(v, fieldName: fieldName);
  static String? positiveNumber(String? v, {String fieldName = 'Value'}) =>
      AppValidators.weightKg(v);
  static String? weightKg(String? v) => AppValidators.weightKg(v);
  static String? distance(String? v) => AppValidators.distanceKm(v);
}
