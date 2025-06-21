import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Global instance of the plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Schedules a task notification at a time before the task's due date
Future<void> scheduleTaskNotification({
  required int id,
  required String title,
  required DateTime scheduledTime,
  Duration offset = const Duration(hours: 0),
}) async {
  try {
    final tzTime = tz.TZDateTime.from(scheduledTime.subtract(offset), tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Task Due: $title',
      'Don\'t forget to complete this task!',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'effora_tasks_channel',
          'Effora Task Reminders',
          channelDescription: 'Notifications for upcoming task deadlines',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // ✅ No exact alarm needed
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  } catch (e) {
    print('❌ Notification scheduling failed: $e');
  }
}
