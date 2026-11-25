import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/config/env.dart';
import 'package:motocare/features/workshops/data/mock_workshop_repository.dart';

void main() {
  group('Finishing Mode Tests (Matikan Semua Fitur Demo untuk Finishing)', () {
    tearDown(() {
      AppEnv.isFinishingMode = false;
    });

    test('Mode Finishing non-aktif secara default untuk backward compatibility test suite', () async {
      AppEnv.isFinishingMode = false;
      expect(AppEnv.isFinishingMode, isFalse);
      expect(AppEnv.showDemoFeatures, isTrue);

      final repo = MockWorkshopRepository();
      final workshops = await repo.getWorkshops();
      expect(workshops.first.isDemo, isTrue);
      expect(workshops.first.name, startsWith('[Demo]'));
    });

    test('Mode Finishing aktif menyembunyikan prefix [Demo] dan menonaktifkan isDemo', () async {
      AppEnv.isFinishingMode = true;
      expect(AppEnv.isFinishingMode, isTrue);
      expect(AppEnv.showDemoFeatures, isFalse);

      final repo = MockWorkshopRepository();
      final workshops = await repo.getWorkshops();

      expect(workshops.length, greaterThanOrEqualTo(32));
      for (final ws in workshops) {
        expect(ws.isDemo, isFalse);
        expect(ws.name.startsWith('[Demo]'), isFalse);
      }
    });
  });
}
