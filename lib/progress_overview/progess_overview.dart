import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daybyday/services/checkin_service.dart';
import 'package:daybyday/services/goal_service.dart';
import 'package:daybyday/services/analytics_service.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _checkInService = CheckInService();
  final _goalService = GoalService();
  final _analyticsService = AnalyticsService();
  
  String selectedPeriod = 'Week';
  bool _isLoading = true;
  
  // Data
  List<double> weeklyMoodData = [];
  double averageMood = 0.0;
  double moodChange = 0.0;
  Map<String, String> dailyPatterns = {};
  List<Map<String, dynamic>> goalProgress = [];
  String? weeklyInsight;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load weekly mood trend
      final moodTrend = await _analyticsService.getWeeklyMoodTrend(userId);
      
      // Calculate average mood
      final avg = moodTrend.where((m) => m > 0).isEmpty 
          ? 0.0 
          : moodTrend.where((m) => m > 0).reduce((a, b) => a + b) / 
            moodTrend.where((m) => m > 0).length;

      // Load goals for progress
      final goals = await _goalService.getGoalsByDuration(userId, 'weekly');
      final goalsProgress = goals.take(2).map((goal) {
        return {
          'description': goal['description'],
          'progress': goal['isCompleted'] ? 1.0 : 0.5, // Simplified
          'label': goal['isCompleted'] ? '3/3' : '2/3',
        };
      }).toList();

      setState(() {
        weeklyMoodData = moodTrend;
        averageMood = avg;
        moodChange = 5.0; // Calculate from previous week
        goalProgress = goalsProgress;
        dailyPatterns = {
          'Sleep': 'Avg: 7h15m',
          'Screen Time': 'Avg: 3h45m',
          'Activity': 'Goal: 8,000 steps',
        };
        weeklyInsight = 'Great job on your sleep this week! Getting consistent rest is linked to a more stable mood.';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Alex';

    return Scaffold(
      backgroundColor: const Color(0xFF61FF8F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF61FF8F),
        elevation: 0,
        title: const Text(
          'Progress Overview Dashboard',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with profile
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 24,
                          child: Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF61FF8F),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
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

                    // Title
                    const Text(
                      'Progress Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                              onTap: () => setState(() => selectedPeriod = period),
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
                                    fontWeight:
                                        isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Good',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF61FF8F).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'vs. Last Week +${moodChange.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF61FF8F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Mood Chart
                          SizedBox(
                            height: 140,
                            child: CustomPaint(
                              painter: MoodChartPainter(weeklyMoodData),
                              child: Container(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Days labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                .map((day) => Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Daily Patterns Section
                    const Text(
                      'Daily Patterns',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _PatternRow(
                            label: 'Sleep',
                            value: dailyPatterns['Sleep'] ?? 'N/A',
                            progress: 0.85,
                            color: const Color(0xFF61FF8F),
                          ),
                          const SizedBox(height: 16),
                          _PatternRow(
                            label: 'Screen Time',
                            value: dailyPatterns['Screen Time'] ?? 'N/A',
                            progress: 0.65,
                            color: const Color(0xFF61FF8F),
                          ),
                          const SizedBox(height: 16),
                          _PatternRow(
                            label: 'Activity',
                            value: dailyPatterns['Activity'] ?? 'N/A',
                            progress: 0.92,
                            color: const Color(0xFF61FF8F),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Goal Progress Section
                    const Text(
                      'Goal Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: goalProgress.isEmpty
                            ? [
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No goals set yet',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              ]
                            : goalProgress.map((goal) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _GoalProgressRow(
                                    goal: goal['description'],
                                    progress: goal['label'],
                                    percentage: goal['progress'],
                                  ),
                                );
                              }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Weekly Insight Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'This Week\'s Insight',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  weeklyInsight ?? 'Keep up the great work!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.5,
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
                ),
              ),
            ),
    );
  }
}

// Pattern Row Widget
class _PatternRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _PatternRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
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
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// Goal Progress Row Widget
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
            Expanded(
              child: Text(
                goal,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// Mood Chart Painter
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
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = data.isNotEmpty ? data : [0.6, 0.4, 0.7, 0.3, 0.8, 0.5, 0.7];

    // Normalize data to 0-1 range
    final maxValue = points.where((p) => p > 0).isEmpty 
        ? 5.0 
        : points.reduce((a, b) => a > b ? a : b);
    final normalizedPoints = points.map((p) => 1 - (p / maxValue)).toList();

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
  bool shouldRepaint(MoodChartPainter oldDelegate) => true;
}