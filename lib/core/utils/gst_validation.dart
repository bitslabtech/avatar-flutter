/// Validates if a given string is a valid GSTIN format.
///
/// Returns [Map<String, dynamic>] containing:
/// - 'isValid': boolean
/// - 'error': String? (null if valid)
class GSTValidator {
  
  static final RegExp _formatRegex = RegExp(r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$");

  static Map<String, dynamic> isValidGSTIN(String gstin) {
    if (gstin.isEmpty) {
      return {'isValid': false, 'error': 'GSTIN cannot be empty'};
    }

    if (gstin.length != 15) {
      return {'isValid': false, 'error': 'GSTIN must be 15 characters long'};
    }

    if (!_formatRegex.hasMatch(gstin)) {
      return {'isValid': false, 'error': 'Invalid GSTIN format'};
    }

    // Checksum Validation
    try {
      if (!_validateChecksum(gstin)) {
        return {'isValid': false, 'error': 'Invalid GST Number'};
      }
    } catch (e) {
       return {'isValid': false, 'error': 'Checksum calculation error'};
    }

    return {'isValid': true, 'error': null};
  }

  static bool _validateChecksum(String gstin) {
    const String codePoints = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    int factor = 1;
    int sum = 0;
    int checkDigitPoint;
    int mode = codePoints.length; // 36

    for (int i = 0; i < 14; i++) {
      int codePoint = codePoints.indexOf(gstin[i]);
      if (codePoint == -1) return false;

      int digit = codePoint;
      
      // Multiply by factor (1 or 2 alternate)
      digit = digit * factor;

      // Add quotient and remainder to sum
      sum += (digit ~/ mode) + (digit % mode);
      
      // Update factor
      factor = (factor == 2) ? 1 : 2;
    }

    checkDigitPoint = (mode - (sum % mode)) % mode;
    String calculatedCheckDigit = codePoints[checkDigitPoint];

    return calculatedCheckDigit == gstin[14];
  }
}
