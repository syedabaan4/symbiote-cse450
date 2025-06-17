import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/thoughts/services/encryption_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockUser implements User {
  @override
  String get uid => 'test_uid';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.toString();
}

void main() {
  group('EncryptionService', () {
    late EncryptionService encryptionService;

    setUp(() async {
      dotenv.testLoad(fileInput: 'ENCRYPTION_KEY=test_encryption_key_32_bytes!!');
      encryptionService = EncryptionService();
      final user = MockUser();
      await encryptionService.initialize(user);
    });

    test('encryptText and decryptText work correctly', () {
      const originalText = 'This is a secret message.';
      final encrypted = encryptionService.encryptText(originalText);
      final decrypted = encryptionService.decryptText(encrypted['encrypted']!, encrypted['iv']!);

      expect(decrypted, equals(originalText));
      expect(encrypted['encrypted'], isNot(equals(originalText)));
    });
  });
} 