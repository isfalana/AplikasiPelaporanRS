import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';
import '../data/services/notification_service.dart';

// [MODIFIKASI] Widget Lonceng Notifikasi interaktif untuk Web, Desktop, dan Mobile
// Menampilkan badge jumlah notifikasi unread, popover dialog notifikasi real-time, dan klik untuk membuka detail laporan
class NotificationBellWidget extends StatelessWidget {
  const NotificationBellWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationService>()) {
      return const SizedBox.shrink();
    }

    final notifService = Get.find<NotificationService>();

    return Obx(() {
      final unread = notifService.unreadCount.value;

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: unread > 0 ? '$unread notifikasi baru' : 'Notifikasi',
            icon: Icon(
              unread > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              color: unread > 0 ? AppColors.primary : AppColors.textStrong,
              size: 24,
            ),
            onPressed: () {
              // Minta izin notifikasi browser (user gesture) jika belum aktif
              notifService.requestPermission();
              // Muat ulang notifikasi setiap kali popover dibuka
              notifService.fetchNotifications();
              _showNotificationDialog(context, notifService);
            },
          ),
          if (unread > 0)
            Positioned(
              right: 6,
              top: 6,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  /// Menampilkan popup dropdown daftar notifikasi secara responsif
  void _showNotificationDialog(
    BuildContext context,
    NotificationService notifService,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (ctx) {
        return Dialog(
          alignment: isMobile ? Alignment.center : Alignment.topRight,
          insetPadding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
              : const EdgeInsets.only(top: 64, right: 28, bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          child: Container(
            width: isMobile ? double.infinity : 400,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: _NotificationPanel(notifService: notifService),
          ),
        );
      },
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({required this.notifService});

  final NotificationService notifService;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
          child: Row(
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final unread = notifService.unreadCount.value;
                if (unread == 0) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unread Baru',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
              const Spacer(),
              Obx(() {
                if (notifService.unreadCount.value == 0) {
                  return const SizedBox.shrink();
                }
                return TextButton(
                  onPressed: () => notifService.markAllAsRead(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'Tandai dibaca',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),

        // [MODIFIKASI] Kartu toggle notifikasi perangkat latar belakang sesuai rancangan UI
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Obx(() {
            final isEnabled = notifService.isDeviceNotificationEnabled.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  notifService.toggleDeviceNotification(!isEnabled);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFFF0F7FF)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEnabled
                          ? const Color(0xFFBFDBFE)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? const Color(0xFFDBEAFE)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: isEnabled
                              ? const Color(0xFF1D4ED8)
                              : AppColors.textWeak,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notifikasi perangkat',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textStrong,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEnabled
                                  ? 'Aktif di perangkat ini. Matikan untuk berhenti menerima pemberitahuan.'
                                  : 'Nonaktif di perangkat ini. Aktifkan untuk menerima pemberitahuan.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textWeak,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: isEnabled,
                        activeTrackColor: const Color(0xFF0D6EFD),
                        activeThumbColor: Colors.white,
                        onChanged: (val) {
                          notifService.toggleDeviceNotification(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),

        // List Notifikasi
        Flexible(
          child: Obx(() {
            if (notifService.isLoading.value &&
                notifService.notifications.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              );
            }

            final list = notifService.notifications;
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 36,
                        color: AppColors.textWeak,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada notifikasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pemberitahuan laporan baru atau tindak lanjut akan ditampilkan di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textWeak,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: list.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final item = list[index];
                final isRead = item['is_read'] == true;
                final idNotif = item['id_notification']?.toString() ?? '';
                final idLaporan = item['id_laporan']?.toString();
                final type = item['type']?.toString() ?? '';

                return InkWell(
                  onTap: () {
                    // Tandai dibaca
                    if (!isRead && idNotif.isNotEmpty) {
                      notifService.markAsRead(idNotif);
                    }
                    // Tutup dialog
                    Navigator.of(context).pop();
                    // Arahkan ke laporan terkait jika ada
                    if (idLaporan != null && idLaporan.isNotEmpty) {
                      notifService.openLaporanDetail(idLaporan, type: type);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: isRead
                        ? AppColors.white
                        : AppColors.primary.withValues(alpha: 0.04),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTypeIcon(type),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title']?.toString() ?? 'Pemberitahuan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.bold,
                                        color: AppColors.textStrong,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['body']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textWeak,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _formatRelativeTime(item['created_at']),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // Footer
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => notifService.fetchNotifications(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Perbarui', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textWeak,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const Text(
                'Lapor Permata Notifications',
                style: TextStyle(fontSize: 10, color: AppColors.textWeak),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'NEW_LAPORAN':
      case 'LAPORAN_BARU':
        icon = Icons.post_add_rounded;
        iconColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case 'LAPORAN_UPDATED':
      case 'LAPORAN_EDITED':
        icon = Icons.edit_notifications_rounded;
        iconColor = const Color(0xFF7C3AED);
        bgColor = const Color(0xFFEDE9FE);
        break;
      case 'PENDING_APPROVAL':
        icon = Icons.pending_actions_rounded;
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'RETURNED':
        icon = Icons.assignment_return_rounded;
        iconColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'COMPLETED':
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF16A34A);
        bgColor = const Color(0xFFDCFCE7);
        break;
      case 'ASSIGN_PIC':
        icon = Icons.person_pin_rounded;
        iconColor = AppColors.primary;
        bgColor = const Color(0xFFF3E8FF);
        break;
      case 'REPORT_DELETED':
      case 'DELETE_REPORT':
        icon = Icons.delete_forever_rounded;
        iconColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'EVIDENCE_UPLOADED':
        icon = Icons.attach_file_rounded;
        iconColor = const Color(0xFF0D9488);
        bgColor = const Color(0xFFCCFBF1);
        break;
      case 'EVIDENCE_DELETED':
        icon = Icons.file_present_rounded;
        iconColor = const Color(0xFFE11D48);
        bgColor = const Color(0xFFFFE4E6);
        break;
      case 'PIC_NOTIFICATION':
        icon = Icons.notification_important_rounded;
        iconColor = const Color(0xFF0284C7);
        bgColor = const Color(0xFFE0F2FE);
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.surface;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  String _formatRelativeTime(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays < 7) return '${diff.inDays} hr lalu';

      // [MODIFIKASI] Format tanggal notifikasi menjadi DD-MM-YYYY
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
