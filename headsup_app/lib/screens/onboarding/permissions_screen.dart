/// Permissions request screen
library;

import 'package:flutter/material.dart';
import 'package:health/health.dart';

import '../../config/theme.dart';
import '../../widgets/common/widgets.dart';
import 'calibration_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isLoading = false;
  bool _permissionGranted = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              const Spacer(),
              
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Title
              Text(
                'HealthKit Permission',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Explanation
              Text(
                'HeadsUp needs HealthKit access to track continuously while you use other apps.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Info card
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.cardRadius,
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'This appears as an "Other" workout in your Health app, but it\'s just posture tracking.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Granted indicator
              if (_permissionGranted) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.postureGood,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Permission granted!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.postureGood,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              
              // Request button
              PrimaryButton(
                text: _permissionGranted ? 'Continue' : 'Grant Permission',
                isLoading: _isLoading,
                onPressed: _permissionGranted ? _continue : _requestPermission,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Skip button
              if (!_permissionGranted)
                TextButton(
                  onPressed: _continue,
                  child: Text(
                    'Skip for now',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final health = Health();
      
      // Request authorization for workout types
      final granted = await health.requestAuthorization(
        [HealthDataType.WORKOUT],
        permissions: [HealthDataAccess.READ_WRITE],
      );
      
      setState(() {
        _permissionGranted = granted;
        _isLoading = false;
      });
      
      if (granted) {
        // Short delay to show success
        await Future.delayed(const Duration(milliseconds: 500));
        _continue();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
          ),
        );
      }
    }
  }
  
  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CalibrationScreen(),
      ),
    );
  }
}
