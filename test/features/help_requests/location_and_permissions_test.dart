import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/help_requests/domain/help_request_rules.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';
import 'package:motocare/features/help_requests/presentation/location_access_dialogs.dart';

void main() {
  group('HelpRequestRules Cakupan Wilayah Tests (Tahap 2)', () {
    test('isWithinServiceArea menerima Kota Lhokseumawe & Kab. Aceh Utara lewat teks kota', () {
      expect(HelpRequestRules.isWithinServiceArea(cityRegency: 'Kota Lhokseumawe'), isTrue);
      expect(HelpRequestRules.isWithinServiceArea(cityRegency: 'Kabupaten Aceh Utara'), isTrue);
      expect(HelpRequestRules.isWithinServiceArea(cityRegency: 'Aceh Utara'), isTrue);
    });

    test('isWithinServiceArea menerima koordinat dalam bounding box Lhokseumawe', () {
      // Titik di pusat Kota Lhokseumawe
      expect(
        HelpRequestRules.isWithinServiceArea(latitude: 5.1801, longitude: 97.1396),
        isTrue,
      );
      // Titik di Lhoksukon, Aceh Utara
      expect(
        HelpRequestRules.isWithinServiceArea(latitude: 5.0450, longitude: 97.3180),
        isTrue,
      );
    });

    test('isWithinServiceArea menolak koordinat di luar wilayah layanan', () {
      // Jakarta
      expect(
        HelpRequestRules.isWithinServiceArea(latitude: -6.2088, longitude: 106.8456),
        isFalse,
      );
      // Medan
      expect(
        HelpRequestRules.isWithinServiceArea(latitude: 3.5952, longitude: 98.6722),
        isFalse,
      );
    });
  });

  group('ServiceRequest Model Location Fields Tests (Tahap 2)', () {
    test('Serialisasi dan deserialisasi cityRegency serta landmark', () {
      final req = ServiceRequest(
        id: 'req-loc-1',
        userId: 'user-1',
        issueCategory: CommonIssues.banBocor,
        issueDescription: 'Ban belakang bocor kena paku di depan SPBU',
        addressText: 'Jl. Medan - Banda Aceh',
        cityRegency: 'Kabupaten Aceh Utara',
        landmark: 'Depan SPBU Cunda',
        contactPhone: '081234567890',
        latitude: 5.16,
        longitude: 97.14,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      final json = req.toJson();
      expect(json['city_regency'], 'Kabupaten Aceh Utara');
      expect(json['landmark'], 'Depan SPBU Cunda');

      final fromJson = ServiceRequest.fromJson(json);
      expect(fromJson.cityRegency, 'Kabupaten Aceh Utara');
      expect(fromJson.landmark, 'Depan SPBU Cunda');
    });

    test('Fallback nilai default cityRegency jika field kosong di JSON', () {
      final jsonLegacy = <String, dynamic>{
        'id': 'legacy-1',
        'user_id': 'user-1',
        'issue_category': 'Lainnya',
        'issue_description': 'Mesin mogok tidak bisa starter',
        'address_text': 'Jl. Merdeka No. 1',
        'contact_phone': '081234567890',
        'status': 'pending',
      };

      final req = ServiceRequest.fromJson(jsonLegacy);
      expect(req.cityRegency, 'Kota Lhokseumawe');
      expect(req.landmark, isNull);
    });
  });

  group('Widget Tests Dialog Figma 09.06 & 09.07 (Tahap 2)', () {
    testWidgets('09.06: LocationPermissionDialog menampilkan judul dan tombol aksi', (tester) async {
      bool retried = false;
      bool manual = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationPermissionDialog(
              isPermanentlyDenied: false,
              onRetry: () => retried = true,
              onManualInput: () => manual = true,
            ),
          ),
        ),
      );

      expect(find.text('Lokasi belum dapat diakses'), findsOneWidget);
      expect(find.byKey(const Key('btn_retry_location_access')), findsOneWidget);
      expect(find.byKey(const Key('btn_manual_location_input')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_retry_location_access')));
      expect(retried, isTrue);

      await tester.tap(find.byKey(const Key('btn_manual_location_input')));
      expect(manual, isTrue);
    });

    testWidgets('09.07: LocationStaleDialog menampilkan posisi terakhir dan tombol perbarui', (tester) async {
      bool refreshed = false;
      bool useLast = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationStaleDialog(
              lastAddress: 'Banda Sakti, Kota Lhokseumawe',
              lastUpdatedText: 'Terakhir 3 menit lalu',
              onRefresh: () => refreshed = true,
              onUseLastLocation: () => useLast = true,
            ),
          ),
        ),
      );

      expect(find.text('Lokasi belum diperbarui'), findsOneWidget);
      expect(find.text('Banda Sakti, Kota Lhokseumawe'), findsOneWidget);
      expect(find.text('Pembaruan: Terakhir 3 menit lalu'), findsOneWidget);
      expect(find.byKey(const Key('btn_refresh_location')), findsOneWidget);
      expect(find.byKey(const Key('btn_use_last_location')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_refresh_location')));
      expect(refreshed, isTrue);

      await tester.tap(find.byKey(const Key('btn_use_last_location')));
      expect(useLast, isTrue);
    });
  });
}

