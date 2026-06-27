// File: lib/overview/overview_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daybyday/services/analytics_service.dart';
import 'package:daybyday/services/goal_service.dart';
import 'package:daybyday/services/daily_patterns_service.dart';
import 'package:daybyday/services/checkin_service.dart';
import 'package:daybyday/goal_setting/goal_progress_overview_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({Key? key}) : super(key: key);

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final _analyticsService = AnalyticsService();
  final _goalService = GoalService();
  final _dailyPatternsService = DailyPatternsService();
  final _checkInService = CheckInService();

  bool _isLoading = true;
  String selectedPeriod = 'Week';

  // Mood data
  List<double> moodData = [];
  double averageMood = 0.0;
  int totalCheckIns = 0;

  // Goal data
  Map<String, int> dailyGoalStats = {};
  Map<String, int> weeklyGoalStats = {};
  Map<String, int> monthlyGoalStats = {};

  // Daily patterns
  Map<String, dynamic> sleepData = {};
  Map<String, dynamic> screenTimeData = {};
  Map<String, dynamic> activityData = {};
  
  // Quick stats
  int currentStreak = 0;
  int totalGoalsCompleted = 0;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load mood data
      final mood = await _analyticsService.getWeeklyMoodTrend(userId);
      final avg = mood.where((m) => m > 0).isEmpty
          ? 0.0
          : mood.where((m) => m > 0).reduce((a, b) => a + b) /
              mood.where((m) => m > 0).length;

      // Load check-in count
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final checkIns = await _checkInService.getCheckInsInRange(
        userId,
        weekAgo,
        now,
      );

      // Load goal stats
      final dailyGoals = await _goalService.getGoalStats(userId, 'daily');
      final weeklyGoals = await _goalService.getGoalStats(userId, 'weekly');
      final monthlyGoals = await _goalService.getGoalStats(userId, 'monthly');

      // Load daily patterns
      final sleep = await _dailyPatternsService.getAverageSleep(
        userId,
        weekAgo,
        now,
      );
      final screen = await _dailyPatternsService.getAverageScreenTime(
        userId,
        weekAgo,
        now,
      );
      final steps = await _dailyPatternsService.getAverageSteps(
        userId,
        weekAgo,
        now,
      );

      // Calculate streak
      int streak = 0;
      DateTime checkDate = now;
      for (int i = 0; i < 365; i++) {
        final dayCheckIns = await _checkInService.getCheckInsForDate(
          userId,
          _formatDate(checkDate),
        );
        if (dayCheckIns.isEmpty) break;
        if (dayCheckIns.isNotEmpty) {
          streak++;
        }
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      // Calculate total goals completed
      final allGoals = await _goalService.getGoals(userId);
      final completedCount = allGoals.where((g) => g['isCompleted'] == true).length;

      setState(() {
        moodData = mood;
        averageMood = avg;
        totalCheckIns = checkIns.length;
        dailyGoalStats = dailyGoals;
        weeklyGoalStats = weeklyGoals;
        monthlyGoalStats = monthlyGoals;
        sleepData = sleep;
        screenTimeData = screen;
        activityData = steps;
        currentStreak = streak;
        totalGoalsCompleted = completedCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading overview data: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your progress at a glance',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // Period Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['Week', 'Month', 'Year'].map((period) {
                      final isSelected = selectedPeriod == period;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _changePeriod(period),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF61FF8F)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              period,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Mood Overview Card
                _SectionCard(
                  title: 'Mood Tracking',
                  icon: Icons.mood,
                  iconColor: const Color(0xFF61FF8F),
                  children: [
                    _StatRow(
                      label: 'Average Mood',
                      value: _getMoodLabel(averageMood),
                      icon: Icons.trending_up,
                      color: const Color(0xFF61FF8F),
                    ),
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Check-ins This Week',
                      value: '$totalCheckIns',
                      icon: Icons.check_circle_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    // Mini mood chart
                    SizedBox(
                      height: 80,
                      child: CustomPaint(
                        painter: MiniMoodChartPainter(moodData),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Goals Overview Card
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const GoalProgressOverviewScreen(),
                      ),
                    );
                  },
                  child: _SectionCard(
                    title: 'Goal Progress',
                    icon: Icons.flag,
                    iconColor: Colors.orange,
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    children: [
                      _GoalProgressBar(
                        label: 'Daily Goals',
                        completed: dailyGoalStats['completed'] ?? 0,
                        total: dailyGoalStats['total'] ?? 0,
                        color: const Color(0xFF61FF8F),
                      ),
                      const SizedBox(height: 12),
                      _GoalProgressBar(
                        label: 'Weekly Goals',
                        completed: weeklyGoalStats['completed'] ?? 0,
                        total: weeklyGoalStats['total'] ?? 0,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _GoalProgressBar(
                        label: 'Monthly Goals',
                        completed: monthlyGoalStats['completed'] ?? 0,
                        total: monthlyGoalStats['total'] ?? 0,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Daily Patterns Card
                _SectionCard(
                  title: 'Daily Patterns',
                  icon: Icons.calendar_today,
                  iconColor: Colors.purple,
                  children: [
                    _PatternRow(
                      icon: Icons.bedtime,
                      label: 'Sleep',
                      value: sleepData['formatted'] ?? 'No data',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _PatternRow(
                      icon: Icons.phone_android,
                      label: 'Screen Time',
                      value: screenTimeData['formatted'] ?? 'No data',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _PatternRow(
                      icon: Icons.directions_walk,
                      label: 'Activity',
                      value: activityData['formatted'] ?? 'No data',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Stats Grid
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child:                       _QuickStatCard(
                        icon: Icons.local_fire_department,
                        label: 'Current Streak',
                        value: '$currentStreak days',
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStatCard(
                        icon: Icons.emoji_events,
                        label: 'Goals Completed',
                        value: '$totalGoalsCompleted',
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMoodLabel(double avg) {
    if (avg == 0) return 'No data';
    if (avg >= 4) return 'Great';
    if (avg >= 3) return 'Good';
    if (avg >= 2) return 'Okay';
    return 'Low';
  }

  Future<void> _changePeriod(String period) async {
    setState(() => selectedPeriod = period);
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    List<double> mood = [];
    
    if (period == 'Week') {
      mood = await _analyticsService.getWeeklyMoodTrend(userId);
    } else if (period == 'Month') {
      mood = await _analyticsService.getMonthlyMoodTrend(userId);
    } else {
      mood = await _analyticsService.getYearlyMoodTrend(userId);
    }

    final avg = mood.where((m) => m > 0).isEmpty
        ? 0.0
        : mood.where((m) => m > 0).reduce((a, b) => a + b) /
            mood.where((m) => m > 0).length;

    setState(() {
      moodData = mood;
      averageMood = avg;
    });
  }
}

// Section Card Widget
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// Stat Row Widget
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Goal Progress Bar Widget
class _GoalProgressBar extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final Color color;

  const _GoalProgressBar({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : completed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              '$completed/$total',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// Pattern Row Widget
class _PatternRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PatternRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Quick Stat Card Widget
class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Mini Mood Chart Painter
class MiniMoodChartPainter extends CustomPainter {
  final List<double> data;

  MiniMoodChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.every((d) => d == 0)) return;

    final linePaint = Paint()
      ..color = const Color(0xFF61FF8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final points = data;
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

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(MiniMoodChartPainter oldDelegate) => true;
}