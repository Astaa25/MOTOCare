import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Status penyimpanan pada database Supabase (enum `reminder_status`)
enum StoredReminderStatus {
  active,
  completed;

  static StoredReminderStatus fromString(String val) {
    if (val.toLowerCase() == 'completed') {
      return StoredReminderStatus.completed;
    }
    return StoredReminderStatus.active;
  }

  String get dbValue => name;
}

/// Status dinamis hasil kalkulasi sesuai PRD Bagian 6.3
enum ReminderStatus {
  scheduled,
  near,
  overdue,
  completed;

  /// Label Bahasa Indonesia sesuai PRD 6.3
  String get label {
    switch (this) {
      case ReminderStatus.scheduled:
        return 'Terjadwal';
      case ReminderStatus.near:
        return 'Segera servis';
      case ReminderStatus.overdue:
        return 'Terlambat';
      case ReminderStatus.completed:
        return 'Selesai';
    }
  }

  /// Warna teks & ikon sesuai token tema
  Color get color {
    switch (this) {
      case ReminderStatus.scheduled:
        return AppColors.textSecondary;
      case ReminderStatus.near:
        return AppColors.warning;
      case ReminderStatus.overdue:
        return AppColors.error;
      case ReminderStatus.completed:
        return AppColors.success;
    }
  }

  /// Warna latar chip
  Color get backgroundColor {
    switch (this) {
      case ReminderStatus.scheduled:
        return const Color(0xFFF1F3F5);
      case ReminderStatus.near:
        return const Color(0xFFFFF4E5);
      case ReminderStatus.overdue:
        return const Color(0xFFFFEBEE);
      case ReminderStatus.completed:
        return const Color(0xFFE8F5E9);
    }
  }

  /// Warna garis batas chip
  Color get borderColor {
    switch (this) {
      case ReminderStatus.scheduled:
        return AppColors.border;
      case ReminderStatus.near:
        return AppColors.peach;
      case ReminderStatus.overdue:
        return const Color(0xFFFFCDD2);
      case ReminderStatus.completed:
        return const Color(0xFFA5D6A7);
    }
  }

  /// Ikon representasi status
  IconData get icon {
    switch (this) {
      case ReminderStatus.scheduled:
        return Icons.calendar_today_rounded;
      case ReminderStatus.near:
        return Icons.warning_amber_rounded;
      case ReminderStatus.overdue:
        return Icons.error_outline_rounded;
      case ReminderStatus.completed:
        return Icons.check_circle_rounded;
    }
  }

  /// Urutan prioritas keparahan untuk pengurutan daftar:
  /// overdue (0, paling mendesak) -> near (1) -> scheduled (2) -> completed (3)
  int get severityOrder {
    switch (this) {
      case ReminderStatus.overdue:
        return 0;
      case ReminderStatus.near:
        return 1;
      case ReminderStatus.scheduled:
        return 2;
      case ReminderStatus.completed:
        return 3;
    }
  }
}
