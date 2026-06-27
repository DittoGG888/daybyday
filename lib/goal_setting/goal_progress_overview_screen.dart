// File: lib/goal_setting/goal_progress_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daybyday/services/goal_service.dart';

class GoalProgressOverviewScreen extends StatefulWidget {
  const GoalProgressOverviewScreen({Key? key}) : super(key: key);

  @override
  State<GoalProgressOverviewScreen> createState() =>
      _GoalProgressOverviewScreenState();
}

class _GoalProgressOverviewScreenState
    extends State<GoalProgressOverviewScreen> {
  final _goalService = GoalService();
  String selectedDuration = 'daily';
  bool _isLoading = true;

  Map<String, dynamic> dailyHistory = {};
  Map<String, dynamic> weeklyHistory = {};
  Map<String, dynamic> monthlyHistory = {};

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final daily = await _goalService.getGoalCompletionHistory(
        userId,
        'daily',
        periodsBack: 7,
      );
      final weekly = await _goalService.getGoalCompletionHistory(
        userId,
        'weekly',
        periodsBack: 4,
      );
      final monthly = await _goalService.getGoalCompletionHistory(
        userId,
        'monthly',
        periodsBack: 6,
      );

      setState(() {
        dailyHistory = daily;
        weeklyHistory = weekly;
        monthlyHistory = monthly;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get currentHistory {
    switch (selectedDuration) {
      case 'daily':
        return dailyHistory;
      case 'weekly':
        return weeklyHistory;
      case 'monthly':
        return monthlyHistory;
      default:
        return dailyHistory;
    }
  }

  List<Map<String, dynamic>> get periods {
    return (currentHistory['periods'] ?? []) as List<Map<String, dynamic>>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF61FF8F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF61FF8F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Goal Progress Overview',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: ['daily', 'weekly', 'monthly'].map((duration) {
                        final isSelected = selectedDuration == duration;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => selectedDuration = duration),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF61FF8F)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                duration.capitalize(),
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

                  // Overall Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedDuration.capitalize()} Goals Overview',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _OverallStatsRow(
                          label: 'Average Completion',
                          value:
                              '${_calculateAverageCompletion(periods).toStringAsFixed(0)}%',
                          icon: Icons.trending_up,
                          color: const Color(0xFF61FF8F),
                        ),
                        const SizedBox(height: 16),
                        _OverallStatsRow(
                          label: 'Best Period',
                          value: _getBestPeriod(periods),
                          icon: Icons.emoji_events,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        _OverallStatsRow(
                          label: 'Current Streak',
                          value: '${_getCurrentStreak(periods)} ${_getStreakUnit()}',
                          icon: Icons.local_fire_department,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress History
                  const Text(
                    'Completion History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Chart
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: periods.isEmpty
                        ? const Center(
                            child: Text(
                              'No data available yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : CustomPaint(
                            painter: ProgressBarChartPainter(periods),
                            child: Container(),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Period Details List
                  ...periods.map((period) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  period['period'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${period['completed']} of ${period['total']} completed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getPercentageColor(period['percentage'])
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${period['percentage']}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getPercentageColor(period['percentage']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // Insights Card
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
                                'Insight',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getInsight(periods),
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
    );
  }

  double _calculateAverageCompletion(List<Map<String, dynamic>> periods) {
    if (periods.isEmpty) return 0.0;
    final total = periods.fold<int>(
      0,
      (sum, period) => sum + (period['percentage'] as int),
    );
    return total / periods.length;
  }

  String _getBestPeriod(List<Map<String, dynamic>> periods) {
    if (periods.isEmpty) return 'N/A';
    final best = periods.reduce((a, b) =>
        (a['percentage'] as int) > (b['percentage'] as int) ? a : b);
    return '${best['period']} (${best['percentage']}%)';
  }

  int _getCurrentStreak(List<Map<String, dynamic>> periods) {
    if (periods.isEmpty) return 0;
    int streak = 0;
    // Count from most recent period backwards
    for (int i = periods.length - 1; i >= 0; i--) {
      if (periods[i]['percentage'] == 100) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _getStreakUnit() {
    switch (selectedDuration) {
      case 'daily':
        return 'days';
      case 'weekly':
        return 'weeks';
      case 'monthly':
        return 'months';
      default:
        return 'periods';
    }
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 80) return const Color(0xFF61FF8F);
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getInsight(List<Map<String, dynamic>> periods) {
    if (periods.isEmpty) {
      return 'Start completing your goals to see insights here!';
    }

    final avg = _calculateAverageCompletion(periods);
    final streak = _getCurrentStreak(periods);

    if (streak >= 3) {
      return 'Amazing! You\'re on a ${streak} ${_getStreakUnit()} streak! Keep up the excellent work.';
    } else if (avg >= 80) {
      return 'You\'re doing great! Your completion rate is ${avg.toStringAsFixed(0)}%. Stay consistent!';
    } else if (avg >= 60) {
      return 'Good progress! Try to complete more goals to reach your full potential.';
    } else {
      return 'Every journey starts with small steps. Focus on completing one goal at a time.';
    }
  }
}

// Overall Stats Row Widget
class _OverallStatsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverallStatsRow({
    required this.label,
    required this.value,
    required this.icon,
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
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
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
          ),
        ),
      ],
    );
  }
}

// Progress Bar Chart Painter
class ProgressBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> periods;

  ProgressBarChartPainter(this.periods);

  @override
  void paint(Canvas canvas, Size size) {
    if (periods.isEmpty) return;

    final barWidth = size.width / periods.length - 8;
    final maxHeight = size.height - 30;

    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];
      final percentage = period['percentage'] as int;
      final barHeight = (percentage / 100) * maxHeight;

      final x = i * (barWidth + 8);
      final y = size.height - barHeight - 20;

      // Draw bar
      final barPaint = Paint()
        ..color = _getBarColor(percentage)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, barPaint);

      // Draw percentage text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$percentage%',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, size.height - 15),
      );
    }
  }

  Color _getBarColor(int percentage) {
    if (percentage >= 80) return const Color(0xFF61FF8F);
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(ProgressBarChartPainter oldDelegate) => true;
}

// String extension
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}