import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/services/update_service.dart';

void main() {
  group('UpdateService Semantic Versioning', () {
    test('compares versions correctly', () {
      expect(UpdateService.isVersionNewer('1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isVersionNewer('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isVersionNewer('2.0.0', '1.9.9'), isTrue);
      expect(UpdateService.isVersionNewer('v1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
      expect(UpdateService.isVersionNewer('0.9.9', '1.0.0'), isFalse);
      expect(UpdateService.isVersionNewer('1.0.0', '1.0.1'), isFalse);
    });

    test('handles tags with v prefix and extra characters', () {
      expect(UpdateService.isVersionNewer('v1.2.0', 'v1.1.5'), isTrue);
      expect(UpdateService.isVersionNewer('v1.0.0+2', '1.0.0'), isFalse);
      expect(UpdateService.isVersionNewer('v1.0.1+3', '1.0.0'), isTrue);
    });
  });
}
