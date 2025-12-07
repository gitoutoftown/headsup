/// Settings bottom sheet
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';
import '../../services/notification_service.dart';

/// Haptic feedback interval options
enum HapticInterval {
  off(0, 'Off'),
  oneMinute(1, '1 minute'),
  fiveMinutes(5, '5 minutes'),
  fifteenMinutes(15, '15 minutes'),
  thirtyMinutes(30, '30 minutes'),
  oneHour(60, '1 hour');

  final int minutes;
  final String label;
  const HapticInterval(this.minutes, this.label);
  
  static HapticInterval fromMinutes(int minutes) {
    return HapticInterval.values.firstWhere(
      (e) => e.minutes == minutes,
      orElse: () => HapticInterval.thirtyMinutes,
    );
  }
}

/// Haptic feedback pattern options
enum HapticPattern {
  single('Single'),
  double('Double'),
  triple('Triple'),
  continuous('Continuous');

  final String label;
  const HapticPattern(this.label);
  
  static HapticPattern fromString(String? value) {
    return HapticPattern.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HapticPattern.single,
    );
  }
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});
  
  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  double _postureThreshold = 40;
  bool _alertsEnabled = true;
  HapticInterval _badPostureInterval = HapticInterval.thirtyMinutes;
  HapticInterval _poorPostureInterval = HapticInterval.fifteenMinutes;
  HapticPattern _hapticPattern = HapticPattern.single;
  bool _vibrateOnBadPosture = true;
  bool _vibrateOnPoorPosture = true;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _autoPauseEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _postureThreshold = prefs.getDouble('postureThreshold') ?? 40;
      _alertsEnabled = prefs.getBool('alertsEnabled') ?? true;
      _badPostureInterval = HapticInterval.fromMinutes(
        prefs.getInt('badPostureIntervalMinutes') ?? 30,
      );
      _poorPostureInterval = HapticInterval.fromMinutes(
        prefs.getInt('poorPostureIntervalMinutes') ?? 15,
      );
      _hapticPattern = HapticPattern.fromString(
        prefs.getString('hapticPattern'),
      );
      _vibrateOnBadPosture = prefs.getBool('vibrateOnBadPosture') ?? true;
      _vibrateOnPoorPosture = prefs.getBool('vibrateOnPoorPosture') ?? true;
      _reminderEnabled = prefs.getBool('reminderEnabled') ?? true;
      _autoPauseEnabled = prefs.getBool('autoPauseEnabled') ?? true;
      
      final hour = prefs.getInt('reminderHour') ?? 9;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('postureThreshold', _postureThreshold);
    await prefs.setBool('alertsEnabled', _alertsEnabled);
    await prefs.setInt('badPostureIntervalMinutes', _badPostureInterval.minutes);
    await prefs.setInt('poorPostureIntervalMinutes', _poorPostureInterval.minutes);
    await prefs.setString('hapticPattern', _hapticPattern.name);
    await prefs.setBool('vibrateOnBadPosture', _vibrateOnBadPosture);
    await prefs.setBool('vibrateOnPoorPosture', _vibrateOnPoorPosture);
    await prefs.setBool('reminderEnabled', _reminderEnabled);
    await prefs.setBool('autoPauseEnabled', _autoPauseEnabled);
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: AppRadius.sheetRadius,
          ),
          child: ListView(
            controller: scrollController,
            padding: AppSpacing.pagePadding,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Posture threshold
              _buildSectionTitle('Posture Threshold'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Angle below ${_postureThreshold.round()}° is considered good posture',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Slider(
                value: _postureThreshold,
                min: 20,
                max: 60,
                divisions: 40,
                label: '${_postureThreshold.round()}°',
                onChanged: (value) {
                  setState(() {
                    _postureThreshold = value;
                  });
                  _saveSettings();
                },
              ),
              
              const Divider(height: AppSpacing.xl),
              
              // Haptic Alerts
              _buildSectionTitle('Haptic Alerts'),
              SwitchListTile(
                title: const Text('Enable Haptic Feedback'),
                subtitle: const Text('Vibrate when posture needs correction'),
                value: _alertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _alertsEnabled = value;
                  });
                  _saveSettings();
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              if (_alertsEnabled) ...[
                const SizedBox(height: AppSpacing.md),
                
                // Bad posture (41-65°) interval
                _buildSectionTitle('Haptic Feedback'),
                _buildSettingTile(
                  context,
                  title: 'Vibration Pattern',
                  subtitle: _hapticPattern.label,
                  trailing: DropdownButton<HapticPattern>(
                    value: _hapticPattern,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _hapticPattern = value);
                        _saveSettings();
                      }
                    },
                    items: HapticPattern.values.map((pattern) {
                      return DropdownMenuItem(
                        value: pattern,
                        child: Text(pattern.label),
                      );
                    }).toList(),
                  ),
                ),
                _buildSettingTile(
                  context,
                  title: 'Bad Posture Interval',
                  subtitle: 'Vibrate every ${_badPostureInterval.label} in bad posture',
                  trailing: DropdownButton<HapticInterval>(
                    value: _badPostureInterval,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _badPostureInterval = value);
                        _saveSettings();
                      }
                    },
                    items: HapticInterval.values.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text(interval.label),
                      );
                    }).toList(),
                  ),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Vibrate on Bad Posture',
                  subtitle: 'Instant vibration when entering Bad zone',
                  value: _vibrateOnBadPosture,
                  onChanged: (value) {
                    setState(() => _vibrateOnBadPosture = value);
                    _saveSettings();
                  },
                ),
                _buildSettingTile(
                  context,
                  title: 'Poor Posture Interval',
                  subtitle: 'Vibrate every ${_poorPostureInterval.label} in poor posture',
                  trailing: DropdownButton<HapticInterval>(
                    value: _poorPostureInterval,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _poorPostureInterval = value);
                        _saveSettings();
                      }
                    },
                    items: HapticInterval.values.map((interval) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text(interval.label),
                      );
                    }).toList(),
                  ),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Vibrate on Poor Posture',
                  subtitle: 'Instant vibration when entering Poor zone',
                  value: _vibrateOnPoorPosture,
                  onChanged: (value) {
                    setState(() => _vibrateOnPoorPosture = value);
                    _saveSettings();
                  },
                ),
              ],
              
              const Divider(height: AppSpacing.xl),
              
              // Reminder
              _buildSectionTitle('Daily Reminder'),
              SwitchListTile(
                title: const Text('Reminder Notification'),
                subtitle: const Text('Reminds you to start tracking'),
                value: _reminderEnabled,
                onChanged: (value) async {
                  setState(() {
                    _reminderEnabled = value;
                  });
                  _saveSettings();
                  
                  // Schedule or cancel notifications
                  if (value) {
                    await NotificationService().requestPermissions();
                    await NotificationService().scheduleDailyReminder(time: _reminderTime);
                  } else {
                    await NotificationService().cancelAllReminders();
                  }
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_reminderEnabled) ...[
                ListTile(
                  title: const Text('Reminder Time'),
                  trailing: Text(
                    _reminderTime.format(context),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: _selectReminderTime,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              
              const Divider(height: AppSpacing.xl),
              
              // Auto-pause
              _buildSectionTitle('Tracking'),
              SwitchListTile(
                title: const Text('Auto-Pause'),
                subtitle: const Text('Pause when phone is face-down'),
                value: _autoPauseEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoPauseEnabled = value;
                  });
                  _saveSettings();
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              const Divider(height: AppSpacing.xl),
              
              // About section
              _buildSectionTitle('About'),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                title: const Text('Version'),
                trailing: Text(
                  AppConstants.appVersion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
  
  Widget _buildSettingTile(BuildContext context, {
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildSwitchTile(BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
      _saveSettings();
      
      // Reschedule notification with new time
      if (_reminderEnabled) {
        await NotificationService().scheduleDailyReminder(time: time);
      }
    }
  }
}
