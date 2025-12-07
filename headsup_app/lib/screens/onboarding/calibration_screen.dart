/// Calibration / Posture Check screen
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../services/posture_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common/widgets.dart';
import '../home_screen.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});
  
  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final PostureService _postureService = PostureService.instance;
  StreamSubscription<double>? _angleSubscription;
  StreamSubscription<PostureState>? _stateSubscription;
  
  double _currentAngle = 0;
  PostureState _currentState = PostureState.good;
  int _step = 0; // 0: Intro/Good, 1: Range/Poor, 2: Done
  
  @override
  void initState() {
    super.initState();
    _startListening();
  }
  
  @override
  void dispose() {
    _angleSubscription?.cancel();
    _stateSubscription?.cancel();
    _postureService.stopListening();
    super.dispose();
  }
  
  Future<void> _startListening() async {
    // Ensure we have permission and start updates
    final available = await _postureService.isDeviceMotionAvailable();
    if (available) {
      await _postureService.startListening();
      
      _angleSubscription = _postureService.angleStream.listen((angle) {
        if (mounted) {
          setState(() {
            _currentAngle = angle;
          });
        }
      });
      
      _stateSubscription = _postureService.stateStream.listen((state) {
        if (mounted) {
          setState(() {
            _currentState = state;
          });
        }
      });
    }
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
              
              const Spacer(),
              
              // Content based on step
              if (_step == 0) ...[
                _buildGoodPostureStep(),
              ] else if (_step == 1) ...[
                _buildRangeStep(),
              ] else ...[
                _buildDoneStep(),
              ],
              
              const Spacer(),
              
              // Live Feedback (always visible in steps 0 and 1)
              if (_step < 2) ...[
                _buildLiveFeedback(),
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
  
  Widget _buildLiveFeedback() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: Color(_currentState.colorCode).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(_currentState.colorCode).withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${_currentAngle.round()}°',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Color(_currentState.colorCode),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _currentState.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Color(_currentState.colorCode),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Mini gauge
          SizedBox(
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    flex: 15,
                    child: Container(color: AppColors.postureExcellent),
                  ),
                  Expanded(
                    flex: 15,
                    child: Container(color: AppColors.postureGood),
                  ),
                  Expanded(
                    flex: 15,
                    child: Container(color: AppColors.postureOkay),
                  ),
                  Expanded(
                    flex: 15,
                    child: Container(color: AppColors.postureBad),
                  ),
                  Expanded(
                    flex: 30,
                    child: Container(color: AppColors.posturePoor),
                  ),
                ],
              ),
            ),
          ),
          // Indicator arrow
          Align(
            alignment: Alignment((_currentAngle / 90.0 * 2) - 1, 0),
            child: const Icon(Icons.arrow_drop_up, size: 24),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoodPostureStep() {
    return Column(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppColors.postureExcellent,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Find Your Center',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Hold your phone at eye level. Aim for the green zone (0-15°). This is where your neck is happiest!',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildRangeStep() {
    return Column(
      children: [
        Icon(
          Icons.swap_vert,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Explore the Range',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tilt your phone down to see how the zones change. HeadsUp tracks these 5 zones to help you improve.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
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
            color: AppColors.postureExcellent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.thumb_up,
            size: 48,
            color: AppColors.postureExcellent,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'You\'re Ready!',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'HeadsUp is calibrated to standard ergonomics. You can start your first session now.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  String _getButtonText() {
    switch (_step) {
      case 0:
        return 'I Found It';
      case 1:
        return 'Got It';
      default:
        return 'Start Using HeadsUp';
    }
  }
  
  Future<void> _handleAction() async {
    switch (_step) {
      case 0:
        setState(() {
          _step = 1;
        });
        break;
      case 1:
        setState(() {
          _step = 2;
        });
        // Mark onboarding as complete
        final prefs = await SharedPreferences.getInstance();
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
