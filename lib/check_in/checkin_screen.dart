// File: lib/check_in/checkin_screen.dart (UPDATED)
import 'package:daybyday/services/checkin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckInScreen extends StatefulWidget {
  final String timeOfDay; // 'morning', 'evening', or 'night'

  const CheckInScreen({
    Key? key,
    required this.timeOfDay,
  }) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _checkInService = CheckInService();
  String? selectedMoodLabel;
  int? selectedMoodScore;
  int? selectedTaskEffectiveness;
  final TextEditingController _customMoodController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  bool useCustomMood = false;
  bool _isSaving = false;

  // Mood options
  final List<String> moodOptions = [
    'Calm',
    'Anxious',
    'Tired',
    'Motivated',
    'Low',
    'Okay',
    'Happy',
    'Stressed'
  ];

  // Mood score labels with emojis
  final List<Map<String, dynamic>> moodScores = [
    {'label': 'Awful', 'emoji': '😞', 'score': 1},
    {'label': 'Bad', 'emoji': '😕', 'score': 2},
    {'label': 'Okay', 'emoji': '😐', 'score': 3},
    {'label': 'Good', 'emoji': '🙂', 'score': 4},
    {'label': 'Great', 'emoji': '😊', 'score': 5},
  ];

  // Get prompts based on time of day
  Map<String, String> get prompts {
    switch (widget.timeOfDay) {
      case 'morning':
        return {
          'mood': 'How do you feel starting your day?',
          'effectiveness': 'How ready do you feel to take on today?',
        };
      case 'night':
        return {
          'mood': 'How do you feel as the day ends?',
          'effectiveness':
              'Looking back, how satisfied are you with your effort today?',
        };
      case 'evening':
      default:
        return {
          'mood': 'How are you feeling this evening?',
          'effectiveness': 'How effective were you with today\'s tasks?',
        };
    }
  }

  String get timeIcon {
    switch (widget.timeOfDay) {
      case 'morning':
        return '🌅';
      case 'night':
        return '🌙';
      case 'evening':
      default:
        return '🌆';
    }
  }

  bool get canSave =>
      (selectedMoodLabel != null || _customMoodController.text.isNotEmpty) &&
      selectedMoodScore != null &&
      selectedTaskEffectiveness != null;

  bool get shouldShowReflectionPrompt =>
      widget.timeOfDay == 'night' && (selectedMoodScore ?? 5) <= 2;

  Future<void> _saveCheckIn() async {
    if (!canSave || _isSaving) return;

    setState(() => _isSaving = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    // Use custom mood if entered, otherwise use selected mood
    final finalMoodLabel = useCustomMood && _customMoodController.text.isNotEmpty
        ? _customMoodController.text.trim().toLowerCase()
        : selectedMoodLabel!;

    try {
      await _checkInService.saveCheckIn(
        userId: userId,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        timeOfDay: widget.timeOfDay,
        moodLabel: finalMoodLabel,
        moodScore: selectedMoodScore!,
        taskEffectiveness: selectedTaskEffectiveness!,
        reflection: _reflectionController.text.isNotEmpty
            ? _reflectionController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.timeOfDay.capitalize()} check-in saved!'),
            backgroundColor: const Color(0xFF61FF8F),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving check-in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
          'Daily Check-in',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                DateFormat('MMM dd').format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time of day indicator
              Row(
                children: [
                  Text(
                    timeIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.timeOfDay.capitalize()} Check-in',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 1. Mood Label Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'In one word, how do you feel right now?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        useCustomMood = !useCustomMood;
                        if (!useCustomMood) {
                          _customMoodController.clear();
                        } else {
                          selectedMoodLabel = null;
                        }
                      });
                    },
                    child: Text(
                      useCustomMood ? 'Use Preset' : 'Custom',
                      style: const TextStyle(
                        color: Color(0xFF2D5A45),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (useCustomMood) ...[
                // Custom mood input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF61FF8F),
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _customMoodController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Enter your own word...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.edit, color: Color(0xFF61FF8F)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ] else ...[
                // Preset mood chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: moodOptions.map((mood) {
                    final isSelected = selectedMoodLabel == mood.toLowerCase();
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedMoodLabel = mood.toLowerCase();
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF2D5A45), width: 2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Color(0xFF2D5A45),
                              ),
                            if (isSelected) const SizedBox(width: 6),
                            Text(
                              mood,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? const Color(0xFF2D5A45)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 40),

              // 2. Mood Score (Feeling Scale)
              Text(
                prompts['mood']!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: moodScores.map((mood) {
                    final isSelected = selectedMoodScore == mood['score'];
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedMoodScore = mood['score'];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF61FF8F)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                mood['emoji'],
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mood['label'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey[700],
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 40),

              // 3. Task Effectiveness
              Text(
                prompts['effectiveness']!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: List.generate(5, (index) {
                    final score = index + 1;
                    final isSelected = selectedTaskEffectiveness == score;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedTaskEffectiveness = score;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF61FF8F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Very ineffective',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Very effective',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Optional reflection prompt for night check-in with low mood
              if (shouldShowReflectionPrompt) ...[
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Would you like to write one sentence about today?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optional - you can skip this',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reflectionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write your thoughts here...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 60),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSave && !_isSaving ? _saveCheckIn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A45),
                    disabledBackgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Check-in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _customMoodController.dispose();
    super.dispose();
  }
}

// Extension to capitalize string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}