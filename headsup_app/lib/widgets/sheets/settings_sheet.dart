/// Settings bottom sheet
library;

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../utils/constants.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});
  
  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  double _postureThreshold = 45;
  bool _alertsEnabled = true;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _autoPauseEnabled = true;
  
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
                min: 30,
                max: 60,
                divisions: 30,
                label: '${_postureThreshold.round()}°',
                onChanged: (value) {
                  setState(() {
                    _postureThreshold = value;
                  });
                },
              ),
              
              const Divider(height: AppSpacing.xl),
              
              // Alerts
              _buildSectionTitle('Alerts'),
              SwitchListTile(
                title: const Text('Haptic Alerts'),
                subtitle: const Text('Vibrate after 30 min of poor posture'),
                value: _alertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _alertsEnabled = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              const Divider(height: AppSpacing.xl),
              
              // Reminder
              _buildSectionTitle('Daily Reminder'),
              SwitchListTile(
                title: const Text('Reminder Notification'),
                subtitle: const Text('Reminds you to start tracking'),
                value: _reminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _reminderEnabled = value;
                  });
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
  
  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }
}
