import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_service.dart';
import '../../../models/notification.dart';

class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Container(
      decoration: BoxDecoration(
        color: GodfatherTheme.backgroundBlack,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: GodfatherTheme.primaryGold, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: GodfatherTheme.primaryGold,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NOTIFICACIONES',
                style: GoogleFonts.cinzel(
                  color: GodfatherTheme.primaryGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(notificationProvider.notifier).markAllAsRead();
                },
                icon: Icon(RemixIcons.chat_check_line, color: GodfatherTheme.primaryGold, size: 18),
                label: Text(
                  'LEER TODAS',
                  style: TextStyle(color: GodfatherTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notifications List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: notificationsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: GodfatherTheme.alertRed),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(RemixIcons.notification_off_line, size: 60, color: GodfatherTheme.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Sin notificaciones familiares.',
                            style: TextStyle(color: GodfatherTheme.textMuted, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (context, index) => Divider(color: GodfatherTheme.borderColor),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildNotificationItem(context, ref, item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, FamilyNotification item) {
    IconData getIcon() {
      switch (item.type) {
        case 'transaction_created':
          return RemixIcons.add_circle_fill;
        case 'transaction_updated':
          return RemixIcons.edit_circle_fill;
        case 'transaction_deleted':
          return RemixIcons.indeterminate_circle_fill;
        default:
          return RemixIcons.notification_4_fill;
      }
    }

    Color getIconColor() {
      switch (item.type) {
        case 'transaction_created':
          return GodfatherTheme.successGreen;
        case 'transaction_updated':
          return GodfatherTheme.secondaryGold;
        case 'transaction_deleted':
          return GodfatherTheme.alertRed;
        default:
          return GodfatherTheme.primaryGold;
      }
    }

    final formattedDate = DateFormat('dd MMM, hh:mm a').format(item.createdAt);

    return InkWell(
      onTap: () {
        if (!item.read) {
          ref.read(notificationProvider.notifier).markAsRead(item.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: item.read ? Colors.transparent : GodfatherTheme.primaryGold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: getIconColor().withValues(alpha: 0.15),
                border: Border.all(color: getIconColor().withValues(alpha: 0.45), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(getIcon(), color: getIconColor(), size: 24),
            ),
            const SizedBox(width: 14),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title.toUpperCase(),
                          style: TextStyle(
                            color: getIconColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(color: GodfatherTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      color: item.read ? GodfatherTheme.textLight.withValues(alpha: 0.8) : GodfatherTheme.textLight,
                      fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Red dot indicating unread
            if (!item.read)
              Container(
                margin: const EdgeInsets.only(left: 10, top: 18),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GodfatherTheme.primaryGold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
