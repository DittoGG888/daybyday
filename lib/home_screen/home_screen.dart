// lib/home_screen/home_screen.dart (UPDATED)
import 'package:daybyday/assessments/asssessments.dart';
import 'package:daybyday/check_in/checkin_screen.dart';
import 'package:daybyday/goal_setting/goal_setting_screen.dart';
import 'package:daybyday/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daybyday/services/checkin_service.dart';
import 'package:daybyday/services/goal_service.dart';
import 'package:daybyday/services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userService = UserService();
  final _checkInService = CheckInService();
  final _goalService = GoalService();
  final _analyticsService = AnalyticsService();
  
  // Onboarding status
  bool hasCompletedPsychologicalAssessment = false;
  bool hasSetGoals = false;
  
  // Check-in status
  bool hasMorningCheckIn = false;
  bool hasEveningCheckIn = false;
  bool hasNightCheckIn = false;
  
  // Progress data
  List<double> weeklyMoodData = [];
  double averageMood = 0.0;
  Map<String, int> goalStats = {};
  
  bool _isLoading = true;
  String selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user profile
      final userProfile = await _userService.getUserProfile(userId);
      
      // Load today's check-in status
      final checkInStatus = await _checkInService.getTodayCheckInStatus(userId);
      
      // Load progress data
      final moodTrend = await _analyticsService.getWeeklyMoodTrend(userId);
      final stats = await _goalService.getGoalStats(userId, 'daily');
      
      // Calculate average mood
      final avg = moodTrend.where((m) => m > 0).isEmpty 
          ? 0.0 
          : moodTrend.where((m) => m > 0).reduce((a, b) => a + b) / 
            moodTrend.where((m) => m > 0).length;

      setState(() {
        hasCompletedPsychologicalAssessment = 
            userProfile?['hasCompletedAssessment'] ?? false;
        hasSetGoals = userProfile?['hasSetGoals'] ?? false;
        hasMorningCheckIn = checkInStatus['morning'] ?? false;
        hasEveningCheckIn = checkInStatus['evening'] ?? false;
        hasNightCheckIn = checkInStatus['night'] ?? false;
        weeklyMoodData = moodTrend;
        averageMood = avg;
        goalStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  bool get isOnboardingComplete => 
      hasCompletedPsychologicalAssessment && hasSetGoals;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Alex';

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF61FF8F),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF61FF8F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting and notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF61FF8F),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Home title
                const Text(
                  'Home',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Get Started Section (Only show if onboarding NOT complete)
                if (!isOnboardingComplete) ...[
                  const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Onboarding Cards Row
                  Row(
                    children: [
                      if (!hasCompletedPsychologicalAssessment)
                        Expanded(
                          child: _CompactOnboardingCard(
                            icon: Icons.psychology_outlined,
                            title: 'Psychological\nAssessment',
                            subtitle: 'Understand yourself',
                            isCompleted: hasCompletedPsychologicalAssessment,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PsychologicalAssessmentScreen(),
                                ),
                              );
                              // Reload data after returning from assessment
                              if (mounted) {
                                await _loadUserData();
                              }
                            },
                          ),
                        ),
                      if (!hasCompletedPsychologicalAssessment && !hasSetGoals)
                        const SizedBox(width: 12),
                      if (!hasSetGoals)
                        Expanded(
                          child: _CompactOnboardingCard(
                            icon: Icons.flag_outlined,
                            title: 'Goal Setting',
                            subtitle: 'Plan your growth journey',
                            isCompleted: hasSetGoals,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GoalSettingScreen(),
                                ),
                              );
                              // Reload data after returning from goal setting
                              if (mounted) {
                                await _loadUserData();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Daily Check-ins Section
                const Text(
                  'Daily Check-ins',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                _CheckInCard(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: Colors.orange,
                  title: 'Morning Check-in',
                  subtitle: 'Start the day strong',
                  isCompleted: hasMorningCheckIn,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckInScreen(timeOfDay: 'morning'),
                      ),
                    );
                    if (result == true) {
                      setState(() => hasMorningCheckIn = true);
                    }
                  },
                ),
                const SizedBox(height: 10),

                _CheckInCard(
                  icon: Icons.wb_twilight_outlined,
                  iconColor: Colors.deepOrange,
                  title: 'Evening Check-in',
                  subtitle: 'Reflect on your day',
                  isCompleted: hasEveningCheckIn,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckInScreen(timeOfDay: 'evening'),
                      ),
                    );
                    if (result == true) {
                      setState(() => hasEveningCheckIn = true);
                    }
                  },
                ),
                const SizedBox(height: 10),

                _CheckInCard(
                  icon: Icons.nightlight_outlined,
                  iconColor: Colors.indigo,
                  title: 'Night Check-in',
                  subtitle: 'Wind down for sleep',
                  isCompleted: hasNightCheckIn,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckInScreen(timeOfDay: 'night'),
                      ),
                    );
                    if (result == true) {
                      setState(() => hasNightCheckIn = true);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Progress Overview Section (Only show if onboarding complete)
                if (isOnboardingComplete) ...[
                  const Text(
                    'Progress Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time Period Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _TabButton(
                          label: 'Week',
                          isSelected: selectedPeriod == 'Week',
                          onTap: () => setState(() => selectedPeriod = 'Week'),
                        ),
                        _TabButton(
                          label: 'Month',
                          isSelected: selectedPeriod == 'Month',
                          onTap: () => setState(() => selectedPeriod = 'Month'),
                        ),
                        _TabButton(
                          label: 'Year',
                          isSelected: selectedPeriod == 'Year',
                          onTap: () => setState(() => selectedPeriod = 'Year'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mood Chart Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Mood This Week',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _getMoodLabel(averageMood),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF61FF8F).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'vs Last Week +5%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF61FF8F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Placeholder for chart
                        SizedBox(
                          height: 120,
                          child: CustomPaint(
                            painter: MoodChartPainter(weeklyMoodData),
                            child: Container(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Days labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((day) => Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daily Patterns Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Patterns',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PatternRow(
                          label: 'Sleep',
                          value: 'Avg 7h10m',
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _PatternRow(
                          label: 'Screen Time',
                          value: 'Avg 3h40m',
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        _PatternRow(
                          label: 'Activity',
                          value: 'Goal: 8,000 steps',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Goal Progress Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Goal Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _GoalProgressRow(
                          goal: 'Daily Goals',
                          progress: '${goalStats['completed']}/${goalStats['total']}',
                          percentage: goalStats['total'] == 0 
                              ? 0.0 
                              : (goalStats['completed']! / goalStats['total']!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Insight Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF61FF8F).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF61FF8F),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Week\'s Insight',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Great job on your sleep! You went to bed\nconsistently early. Let\'s build on this success.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMoodLabel(double avg) {
    if (avg >= 4) return 'Great';
    if (avg >= 3) return 'Good';
    if (avg >= 2) return 'Okay';
    return 'Low';
  }
}

// Compact Onboarding Card
class _CompactOnboardingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _CompactOnboardingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isCompleted ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(color: const Color(0xFF61FF8F), width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : icon,
              color: isCompleted ? const Color(0xFF61FF8F) : Colors.black87,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                decoration:
                    isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Check-in Card
class _CheckInCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _CheckInCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isCompleted ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFF61FF8F))
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// Tab Button
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF61FF8F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// Pattern Row
class _PatternRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PatternRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Goal Progress Row
class _GoalProgressRow extends StatelessWidget {
  final String goal;
  final String progress;
  final double percentage;

  const _GoalProgressRow({
    required this.goal,
    required this.progress,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              goal,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            Text(
              progress,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF61FF8F)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// Simple Mood Chart Painter
class MoodChartPainter extends CustomPainter {
  final List<double> data;

  MoodChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.every((d) => d == 0)) {
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFF61FF8F).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF61FF8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final points = data.isNotEmpty ? data : [0.6, 0.4, 0.7, 0.3, 0.8, 0.2, 0.5];

    // Normalize to 0-1 range
    final maxValue = points.where((p) => p > 0).isEmpty 
        ? 5.0 
        : points.reduce((a, b) => a > b ? a : b);
    final normalizedPoints = points.map((p) => 1 - (p / maxValue)).toList();

    final path = Path();
    path.moveTo(0, size.height * normalizedPoints[0]);

    for (int i = 0; i < normalizedPoints.length; i++) {
      final x = (size.width / (normalizedPoints.length - 1)) * i;
      final y = size.height * normalizedPoints[i];
      if (i == 0) {
        path.lineTo(x, y);
      } else {
        final prevX = (size.width / (normalizedPoints.length - 1)) * (i - 1);
        final prevY = size.height * normalizedPoints[i - 1];
        final cpX = (prevX + x) / 2;
        path.quadraticBezierTo(cpX, prevY, x, y);
      }
    }

    // Fill area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, paint);

    // Draw line
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}