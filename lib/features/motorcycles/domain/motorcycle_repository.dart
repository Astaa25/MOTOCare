import '../../../core/utils/result.dart';
import 'motorcycle.dart';

/// Kontrak interface repositori sepeda motor sesuai PRD bagian 2.1 & 7 (M3)
abstract class MotorcycleRepository {
  /// Mengambil daftar seluruh sepeda motor milik pengguna
  Future<Result<List<Motorcycle>>> getMotorcycles({required String userId});

  /// Mengambil sepeda motor aktif/utama milik pengguna (MVP: motor pertama yang terdaftar)
  Future<Result<Motorcycle?>> getActiveMotorcycle({required String userId});

  /// Mengambil rincian sepeda motor berdasarkan ID
  Future<Result<Motorcycle>> getMotorcycleById(String id);

  /// Menambahkan sepeda motor baru beserta atribut detail & foto
  Future<Result<Motorcycle>> addMotorcycle({
    required String userId,
    required String brand,
    required String model,
    required int productionYear,
    String? licensePlate,
    required int currentMileage,
    String? color,
    String? category,
    int? engineCc,
    String? transmission,
    String? fuelType,
    String? photoUrl,
  });

  /// Memperbarui informasi umum sepeda motor (merek, model, tahun, plat)
  Future<Result<Motorcycle>> updateMotorcycle(Motorcycle motorcycle);

  /// Memperbarui catatan kilometer sepeda motor
  Future<Result<Motorcycle>> updateMileage({
    required String motorcycleId,
    required int newMileage,
  });

  /// Menghapus sepeda motor (CASCADE ke riwayat servis dan pengingat)
  Future<Result<void>> deleteMotorcycle(String id);

  /// Stream reaktif pembaruan daftar sepeda motor pengguna
  Stream<List<Motorcycle>> watchMotorcycles({required String userId});
}
