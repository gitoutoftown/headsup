/// Calibration tutorial screen
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../widgets/common/widgets.dart';
import '../home_screen.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});
  
  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  StreamSubscription? _accelerometerSubscription;
  double _currentAngle = 0;
  int _step = 0; // 0: good posture, 1: poor posture, 2: done
  double? _goodPostureAngle;
  double? _poorPostureAngle;
  
  @override
  void initState() {
    super.initState();
    _startListening();
  }
  
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
  
  void _startListening() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      
      if (magnitude < 0.1) return;
      
      final normalizedY = event.y / magnitude;
      final angleRadians = math.acos(normalizedY.clamp(-1.0, 1.0));
      final angleDegrees = angleRadians * 180 / math.pi;
      
      setState(() {
        _currentAngle = angleDegrees;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              const Spacer(),
              
              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepDot(0),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStepDot(1),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStepDot(2),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Instructions based on step
              if (_step == 0) ...[
                _buildGoodPostureStep(),
              ] else if (_step == 1) ...[
                _buildPoorPostureStep(),
              ] else ...[
                _buildDoneStep(),
              ],
              
              const Spacer(),
              
              // Current angle display
              if (_step < 2) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.straighten,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Current angle: ${_currentAngle.round()}°',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              
              // Action button
              PrimaryButton(
                text: _getButtonText(),
                onPressed: _handleAction,
              ),
              
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepDot(int step) {
    final isActive = _step >= step;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : Theme.of(context).dividerColor,
      ),
    );
  }
  
  Widget _buildGoodPostureStep() {
    return Column(
      children: [
        Icon(
          Icons.phone_android,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Hold at Eye Level',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Hold your phone at eye level, as if looking straight ahead. This is good posture.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildPoorPostureStep() {
    return Column(
      children: [
        Transform.rotate(
          angle: math.pi / 4,
          child: Icon(
            Icons.phone_android,
            size: 80,
            color: AppColors.alert,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Now Look Down',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tilt your phone down, as if scrolling while hunched. This is poor posture that HeadsUp will help you notice.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_goodPostureAngle != null)
          Text(
            'Good posture captured at ${_goodPostureAngle!.round()}°',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.postureGood,
            ),
          ),
      ],
    );
  }
  
  Widget _buildDoneStep() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.postureGood.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 48,
            color: AppColors.postureGood,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'All Set!',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'HeadsUp is calibrated and ready to help you build better posture habits.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCalibrationResult('Good', _goodPostureAngle, AppColors.postureGood),
            const SizedBox(width: AppSpacing.lg),
            _buildCalibrationResult('Poor', _poorPostureAngle, AppColors.posturePoor),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCalibrationResult(String label, double? angle, Color color) {
    return Column(
      children: [
        Text(
          angle != null ? '${angle.round()}°' : '--',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  String _getButtonText() {
    switch (_step) {
      case 0:
        return 'Capture Good Posture';
      case 1:
        return 'Capture Poor Posture';
      default:
        return 'Get Started';
    }
  }
  
  Future<void> _handleAction() async {
    switch (_step) {
      case 0:
        setState(() {
          _goodPostureAngle = _currentAngle;
          _step = 1;
        });
        break;
      case 1:
        setState(() {
          _poorPostureAngle = _currentAngle;
          _step = 2;
        });
        // Save calibration
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('goodPostureAngle', _goodPostureAngle ?? 35);
        await prefs.setDouble('poorPostureAngle', _poorPostureAngle ?? 75);
        await prefs.setBool('onboardingComplete', true);
        break;
      default:
        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
    }
  }
}
