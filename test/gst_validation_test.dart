import 'package:flutter_test/flutter_test.dart';
import '../lib/core/utils/gst_validation.dart';

void main() {
  group('GSTIN Validation Tests', () {
    
    test('Valid GSTIN should return true', () {
      // Example Valid GSTIN (verify with online validator if needed, checksum logic implemented)
      // 29AAAAA0000A1Z5 is a standard format test case often used 
      // Let's create one that satisfies checksum: 
      // 27AAPFU0939F1ZV -> Maharashtra
      
      String validGST = "27AAPFU0939F1ZV"; 
      var result = GSTValidator.isValidGSTIN(validGST);
      expect(result['isValid'], isTrue, reason: "Expected $validGST to be valid");
      expect(result['error'], isNull);
    });

    test('Invalid Length should fail', () {
      String invalidLength = "27AAPFU0939F1Z"; // 14 chars
      var result = GSTValidator.isValidGSTIN(invalidLength);
      expect(result['isValid'], isFalse);
      expect(result['error'], equals('GSTIN must be 15 characters long'));
    });

    test('Invalid Format should fail (Wrong Pattern)', () {
      // Wrong format: Numbers where letters should be
      String badFormat = "27A12345678A1Z5";
      var result = GSTValidator.isValidGSTIN(badFormat);
      expect(result['isValid'], isFalse);
      expect(result['error'], equals('Invalid GSTIN format'));
    });

    test('Valid Format but Invalid Checksum should fail', () {
      // 27AAPFU0939F1ZV is valid. Change last char to 'A'
      String wrongChecksum = "27AAPFU0939F1ZA"; 
      var result = GSTValidator.isValidGSTIN(wrongChecksum);
      expect(result['isValid'], isFalse);
      expect(result['error'], equals('Invalid Checksum'));
    });

    test('Empty String should fail', () {
       var result = GSTValidator.isValidGSTIN("");
       expect(result['isValid'], isFalse);
       expect(result['error'], equals('GSTIN cannot be empty'));
    });

  });
}
