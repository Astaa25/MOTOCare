import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/services/user_location_service.dart';

void main() {
  group('UserLocationState Tests', () {
    test('State default berada dalam wilayah layanan Kota Lhokseumawe', () {
      const state = UserLocationState(
        latitude: 5.1801,
        longitude: 97.1396,
        cityRegency: 'Kota Lhokseumawe',
      );

      expect(state.hasLocation, isTrue);
      expect(state.isWithinServiceArea, isTrue);
    });

    test('Koordinat di luar batas Lhokseumawe & Aceh Utara terdeteksi false', () {
      const outsideState = UserLocationState(
        latitude: -6.2088, // Jakarta
        longitude: 106.8456,
        cityRegency: 'Jakarta Pusat',
      );

      expect(outsideState.isWithinServiceArea, isFalse);
    });

    test('Kabupaten Aceh Utara terdeteksi dalam wilayah layanan', () {
      const acehUtaraState = UserLocationState(
        latitude: 5.0500,
        longitude: 97.0500,
        cityRegency: 'Kabupaten Aceh Utara',
      );

      expect(acehUtaraState.isWithinServiceArea, isTrue);
    });

    test('copyWith memperbarui nilai dengan benar', () {
      const initial = UserLocationState(
        status: LocationStatus.initial,
        formattedAddress: 'Alamat Awal',
      );

      final updated = initial.copyWith(
        status: LocationStatus.success,
        formattedAddress: 'Alamat Baru',
        latitude: 5.18,
      );

      expect(updated.status, LocationStatus.success);
      expect(updated.formattedAddress, 'Alamat Baru');
      expect(updated.latitude, 5.18);
    });
  });
}

