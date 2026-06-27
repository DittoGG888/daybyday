// File: lib/insights/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daybyday/services/insights_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _insightsService = InsightsService();
  List<Insight> _insights = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final insights = await _insightsService.generateInsights(userId);
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading insights: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshInsights() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isGenerating = true);

    try {
      final insights = await _insightsService.generateInsights(userId);
      
      // Save insights to history
      for (var insight in insights) {
        await _insightsService.saveInsightToHistory(userId, insight);
      }

      setState(() {
        _insights = insights;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insights refreshed!'),
            backgroundColor: Color(0xFF61FF8F),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing insights: $e');
      setState(() => _isGenerating = false);
    }
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
          'Your Insights',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isGenerating ? null : _refreshInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _insights.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            size: 64,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Insights Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Keep tracking your mood, goals, and patterns.\nInsights will appear as we learn more about you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _insights.length,
                  itemBuilder: (context, index) {
                    final insight = _insights[index];
                    return _InsightCard(insight: insight);
                  },
                ),
    );
  }
}

// Insight Card Widget
class _InsightCard extends StatelessWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getIconColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    insight.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _getCategoryLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTypeLabel(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getTypeColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
            if (insight.actionable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(insight.actionText ?? 'Action')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getIconColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    insight.actionText ?? 'Take Action',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (insight.type) {
      case InsightType.positive:
        return const Color(0xFF61FF8F);
      case InsightType.warning:
        return Colors.orange;
      case InsightType.info:
        return Colors.blue;
    }
  }

  Color _getIconColor() {
    switch (insight.type) {
      case InsightType.positive:
        return const Color(0xFF61FF8F);
      case InsightType.warning:
        return Colors.orange;
      case InsightType.info:
        return Colors.blue;
    }
  }

  Color _getTypeColor() {
    switch (insight.type) {
      case InsightType.positive:
        return const Color(0xFF61FF8F);
      case InsightType.warning:
        return Colors.orange;
      case InsightType.info:
        return Colors.blue;
    }
  }

  String _getTypeLabel() {
    switch (insight.type) {
      case InsightType.positive:
        return 'POSITIVE';
      case InsightType.warning:
        return 'ALERT';
      case InsightType.info:
        return 'INFO';
    }
  }

  String _getCategoryLabel() {
    switch (insight.category) {
      case InsightCategory.mood:
        return 'Mood';
      case InsightCategory.sleep:
        return 'Sleep';
      case InsightCategory.goals:
        return 'Goals';
      case InsightCategory.habits:
        return 'Habits';
      case InsightCategory.engagement:
        return 'Engagement';
    }
  }
}