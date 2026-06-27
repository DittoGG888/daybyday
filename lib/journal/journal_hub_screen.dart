// File: lib/journal/journal_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:daybyday/journal/general_journal_screen.dart';
import 'package:daybyday/journal/reflection_journal_screen.dart';
import 'package:daybyday/journal/gratitude_journal_screen.dart';
import 'package:daybyday/services/journal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalHubScreen extends StatefulWidget {
  const JournalHubScreen({Key? key}) : super(key: key);

  @override
  State<JournalHubScreen> createState() => _JournalHubScreenState();
}

class _JournalHubScreenState extends State<JournalHubScreen> {
  final _journalService = JournalService();
  
  int totalEntries = 0;
  int generalCount = 0;
  int reflectionCount = 0;
  int gratitudeCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournalStats();
  }

  Future<void> _loadJournalStats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _journalService.getJournalStats(userId);
      
      setState(() {
        generalCount = stats['general'] ?? 0;
        reflectionCount = stats['reflection'] ?? 0;
        gratitudeCount = stats['gratitude'] ?? 0;
        totalEntries = generalCount + reflectionCount + gratitudeCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading journal stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF61FF8F),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Journal',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reflect, grow, and express yourself',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.book,
                              value: '$totalEntries',
                              label: 'Total Entries',
                              color: const Color(0xFF61FF8F),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            _StatItem(
                              icon: Icons.calendar_today,
                              value: '${DateTime.now().difference(DateTime(2024, 1, 1)).inDays}',
                              label: 'Days Active',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Journal Types
                      const Text(
                        'Your Journals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // General Journal Card
                      _JournalTypeCard(
                        icon: Icons.edit_note,
                        iconColor: const Color(0xFF61FF8F),
                        title: 'General Journal',
                        description: 'Free-form writing for anything on your mind',
                        entryCount: generalCount,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF61FF8F), Color(0xFF4DE87A)],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GeneralJournalScreen(),
                            ),
                          );
                          _loadJournalStats();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Reflection Journal Card
                      _JournalTypeCard(
                        icon: Icons.psychology,
                        iconColor: Colors.purple,
                        title: 'Reflection Journal',
                        description: 'Guided prompts for deeper self-discovery',
                        entryCount: reflectionCount,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB794F6), Color(0xFF9F7AEA)],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReflectionJournalScreen(),
                            ),
                          );
                          _loadJournalStats();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Gratitude Journal Card
                      _JournalTypeCard(
                        icon: Icons.favorite,
                        iconColor: Colors.pink,
                        title: 'Gratitude Journal',
                        description: 'Daily practice of appreciation and positivity',
                        entryCount: gratitudeCount,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFD8B9A), Color(0xFFFC6C85)],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GratitudeJournalScreen(),
                            ),
                          );
                          _loadJournalStats();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Writing Tips Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Journaling Tips',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _TipItem(text: 'Write without judgment - there\'s no wrong way'),
                            const SizedBox(height: 8),
                            _TipItem(text: 'Be honest with yourself'),
                            const SizedBox(height: 8),
                            _TipItem(text: 'Focus on progress, not perfection'),
                            const SizedBox(height: 8),
                            _TipItem(text: 'Review past entries to see your growth'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Journal Type Card Widget
class _JournalTypeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final int entryCount;
  final Gradient gradient;
  final VoidCallback onTap;

  const _JournalTypeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.entryCount,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$entryCount entries',
                        style: TextStyle(
                          fontSize: 11,
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tip Item Widget
class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}