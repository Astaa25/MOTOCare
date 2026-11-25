import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Enum status permintaan bantuan montir sesuai PRD Bagian 5.1 & 6.6
enum RequestStatus {
  pending('pending', 'Menunggu Konfirmasi', Icons.hourglass_top_rounded),
  accepted('accepted', 'Mekanik Ditemukan', Icons.check_circle_outline_rounded),
  rejected('rejected', 'Permintaan Ditolak', Icons.cancel_outlined),
  onTheWay('on_the_way', 'Dalam Perjalanan', Icons.directions_bike_rounded),
  inProgress('in_progress', 'Sedang Dikerjakan', Icons.build_circle_outlined),
  completed('completed', 'Servis Selesai', Icons.verified_rounded),
  cancelled('cancelled', 'Dibatalkan', Icons.close_rounded),
  expired('expired', 'Waktu Habis / Kedaluwarsa', Icons.timer_off_outlined);

  final String dbValue;
  final String label;
  final IconData icon;

  const RequestStatus(this.dbValue, this.label, this.icon);

  /// Status aktif yang mencegah pengguna membuat permintaan baru (unique constraint)
  bool get isActive {
    return this == RequestStatus.pending ||
        this == RequestStatus.accepted ||
        this == RequestStatus.onTheWay ||
        this == RequestStatus.inProgress;
  }

  /// Status yang diizinkan untuk dibatalkan oleh pengguna (PRD 6.6)
  bool get canCancel {
    return this == RequestStatus.pending ||
        this == RequestStatus.accepted ||
        this == RequestStatus.onTheWay;
  }

  /// Membutuhkan konfirmasi peringatan khusus saat dibatalkan (PRD 6.6: on_the_way)
  bool get requiresCancelWarning => this == RequestStatus.onTheWay;

  Color get textColor {
    switch (this) {
      case RequestStatus.pending:
        return AppColors.warning;
      case RequestStatus.accepted:
      case RequestStatus.onTheWay:
        return AppColors.primaryText;
      case RequestStatus.inProgress:
        return const Color(0xFF0284C7);
      case RequestStatus.completed:
        return AppColors.success;
      case RequestStatus.rejected:
      case RequestStatus.cancelled:
      case RequestStatus.expired:
        return AppColors.error;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RequestStatus.pending:
        return const Color(0xFFFFF4E5);
      case RequestStatus.accepted:
      case RequestStatus.onTheWay:
        return AppColors.cream;
      case RequestStatus.inProgress:
        return const Color(0xFFE0F2FE);
      case RequestStatus.completed:
        return const Color(0xFFE8F5E9);
      case RequestStatus.rejected:
      case RequestStatus.cancelled:
      case RequestStatus.expired:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get borderColor {
    switch (this) {
      case RequestStatus.pending:
        return AppColors.warning;
      case RequestStatus.accepted:
      case RequestStatus.onTheWay:
        return AppColors.peach;
      case RequestStatus.inProgress:
        return const Color(0xFF7DD3FC);
      case RequestStatus.completed:
        return AppColors.success;
      case RequestStatus.rejected:
      case RequestStatus.cancelled:
      case RequestStatus.expired:
        return AppColors.error;
    }
  }

  /// Konversi ke nilai enum PostgreSQL pada tabel assistance_requests Supabase live
  String get toLiveDbValue {
    switch (this) {
      case RequestStatus.pending:
        return 'MENUNGGU';
      case RequestStatus.accepted:
      case RequestStatus.onTheWay:
        return 'DITERIMA';
      case RequestStatus.inProgress:
        return 'SEDANG_DITANGANI';
      case RequestStatus.completed:
        return 'SELESAI';
      case RequestStatus.rejected:
        return 'DITOLAK';
      case RequestStatus.cancelled:
      case RequestStatus.expired:
        return 'DIBATALKAN';
    }
  }

  static RequestStatus fromString(String value) {
    final clean = value.toUpperCase().trim();
    switch (clean) {
      case 'MENUNGGU':
      case 'PENDING':
        return RequestStatus.pending;
      case 'DITERIMA':
      case 'ACCEPTED':
        return RequestStatus.accepted;
      case 'ON_THE_WAY':
      case 'DALAM_PERJALANAN':
      case 'BERANGKAT':
        return RequestStatus.onTheWay;
      case 'SEDANG_DITANGANI':
      case 'IN_PROGRESS':
        return RequestStatus.inProgress;
      case 'SELESAI':
      case 'COMPLETED':
        return RequestStatus.completed;
      case 'DIBATALKAN':
      case 'CANCELLED':
      case 'CANCELED':
        return RequestStatus.cancelled;
      case 'DITOLAK':
      case 'REJECTED':
        return RequestStatus.rejected;
      case 'EXPIRED':
      case 'KEDALUWARSA':
      case 'KADALUARSA':
        return RequestStatus.expired;
      default:
        for (final status in RequestStatus.values) {
          if (status.dbValue.toUpperCase() == clean ||
              status.name.toUpperCase() == clean) {
            return status;
          }
        }
        return RequestStatus.pending;
    }
  }
}
