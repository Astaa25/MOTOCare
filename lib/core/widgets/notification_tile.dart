import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Item notifikasi in-app MotoCare sesuai PRD 4.3 & M5
class NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String type; // 'reminder', 'request_status', 'system'
  final bool isRead;
  final DateTime createdAt;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
  });

  IconData _getTypeIcon() {
    switch (type) {
      case 'reminder':
        return Icons.alarm_rounded;
      case 'request_status':
        return Icons.two_wheeler_rounded;
      case 'system':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getTypeColor() {
    switch (type) {
      case 'reminder':
        return AppColors.warning;
      case 'request_status':
        return AppColors.primary;
      case 'system':
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.background : AppColors.cream.withValues(alpha: 0.35),
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Ikon tipe notifikasi
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(),
                size: 20,
                color: _getTypeColor(),
              ),
            ),
            const SizedBox(width: 12),

            // Teks judul dan isi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.dateTime(createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
