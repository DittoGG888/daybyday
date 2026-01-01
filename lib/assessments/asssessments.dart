import 'package:flutter/material.dart';

// Assessment Question Model
class AssessmentQuestion {
  final int id;
  final String question;
  final String module;
  final List<String> scaleLabels;
  final bool isReverse;

  AssessmentQuestion({
    required this.id,
    required this.question,
    required this.module,
    required this.scaleLabels,
    this.isReverse = false,
  });
}

class PsychologicalAssessmentScreen extends StatefulWidget {
  const PsychologicalAssessmentScreen({Key? key}) : super(key: key);

  @override
  State<PsychologicalAssessmentScreen> createState() =>
      _PsychologicalAssessmentScreenState();
}

class _PsychologicalAssessmentScreenState
    extends State<PsychologicalAssessmentScreen> {
  int currentQuestionIndex = 0;
  Map<int, int> answers = {}; // questionId -> response (1-5)

  // Define all 21 questions
  final List<AssessmentQuestion> questions = [
    // MODULE 1: Personality Tendencies (Big Five)
    // Openness
    AssessmentQuestion(
      id: 1,
      question: 'I enjoy thinking about new ideas.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 2,
      question: 'I like exploring different ways of doing things.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    // Conscientiousness
    AssessmentQuestion(
      id: 3,
      question: 'I usually follow through on what I plan.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 4,
      question: 'I like having structure in my day.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    // Extraversion
    AssessmentQuestion(
      id: 5,
      question: 'I feel energized by interacting with others.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 6,
      question: 'I enjoy being around people.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    // Agreeableness
    AssessmentQuestion(
      id: 7,
      question: 'I try to be understanding of others.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 8,
      question: 'I value harmony in relationships.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    // Emotional Sensitivity
    AssessmentQuestion(
      id: 9,
      question: 'I feel emotions strongly.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 10,
      question: 'Stress affects me more than I\'d like.',
      module: 'Understanding You',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),

    // MODULE 2: Emotional Baseline
    AssessmentQuestion(
      id: 11,
      question: 'I generally feel emotionally okay.',
      module: 'Emotional Baseline',
      scaleLabels: [
        'Almost never',
        'Rarely',
        'Sometimes',
        'Often',
        'Almost always'
      ],
    ),
    AssessmentQuestion(
      id: 12,
      question: 'I feel overwhelmed by daily life.',
      module: 'Emotional Baseline',
      scaleLabels: [
        'Almost never',
        'Rarely',
        'Sometimes',
        'Often',
        'Almost always'
      ],
      isReverse: true,
    ),
    AssessmentQuestion(
      id: 13,
      question: 'I\'m able to calm myself when I\'m stressed.',
      module: 'Emotional Baseline',
      scaleLabels: [
        'Almost never',
        'Rarely',
        'Sometimes',
        'Often',
        'Almost always'
      ],
    ),
    AssessmentQuestion(
      id: 14,
      question: 'I feel hopeful about my future.',
      module: 'Emotional Baseline',
      scaleLabels: [
        'Almost never',
        'Rarely',
        'Sometimes',
        'Often',
        'Almost always'
      ],
    ),

    // MODULE 3: Motivation & Self-Regulation
    AssessmentQuestion(
      id: 15,
      question: 'I feel more motivated when I choose my own goals.',
      module: 'Motivation & Self-Regulation',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 16,
      question: 'I do better when tasks are small and manageable.',
      module: 'Motivation & Self-Regulation',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 17,
      question: 'I struggle to start tasks, even when they matter.',
      module: 'Motivation & Self-Regulation',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
      isReverse: true,
    ),
    AssessmentQuestion(
      id: 18,
      question: 'Progress motivates me more than perfection.',
      module: 'Motivation & Self-Regulation',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),

    // MODULE 4: Reflection & Support Style
    AssessmentQuestion(
      id: 19,
      question: 'I like reflecting on my thoughts and feelings.',
      module: 'Reflection & Support Style',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 20,
      question: 'I prefer gentle encouragement over strict reminders.',
      module: 'Reflection & Support Style',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
    AssessmentQuestion(
      id: 21,
      question: 'I find writing helpful when processing emotions.',
      module: 'Reflection & Support Style',
      scaleLabels: [
        'Strongly disagree',
        'Disagree',
        'Neutral',
        'Agree',
        'Strongly agree'
      ],
    ),
  ];

  double get progress => (currentQuestionIndex + 1) / questions.length;

  void _answerQuestion(int value) {
    setState(() {
      answers[questions[currentQuestionIndex].id] = value;
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        _completeAssessment();
      }
    });
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  void _completeAssessment() {
    final results = _calculateScores();
    
    // Navigate to results screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentResultsScreen(results: results),
      ),
    );
  }

  Map<String, dynamic> _calculateScores() {
    // Helper function for reverse scoring
    int reverse(int value) => 6 - value;

    // Helper function to normalize to 0-100
    double normalize(double rawAvg) => ((rawAvg - 1) / 4) * 100;

    // MODULE 1: Personality
    final o_raw = (answers[1]! + answers[2]!) / 2;
    final c_raw = (answers[3]! + answers[4]!) / 2;
    final e_raw = (answers[5]! + answers[6]!) / 2;
    final a_raw = (answers[7]! + answers[8]!) / 2;
    final es_raw = (answers[9]! + answers[10]!) / 2;

    // MODULE 2: Emotional Baseline
    final q12r = reverse(answers[12]!);
    final stability_raw = (answers[11]! + answers[13]!) / 2;
    final stress_raw = q12r.toDouble();
    final optimism_raw = answers[14]!.toDouble();

    // MODULE 3: Motivation
    final q17r = reverse(answers[17]!);
    final autonomy = answers[15]!.toDouble();
    final smallSteps = answers[16]!.toDouble();
    final initiation = q17r.toDouble();
    final progress = answers[18]!.toDouble();

    // MODULE 4: Support Style
    final reflection = answers[19]!.toDouble();
    final gentleTone = answers[20]!.toDouble();
    final writingHelpful = answers[21]!.toDouble();

    return {
      'personality': {
        'openness': normalize(o_raw).round(),
        'conscientiousness': normalize(c_raw).round(),
        'extraversion': normalize(e_raw).round(),
        'agreeableness': normalize(a_raw).round(),
        'emotionalSensitivity': normalize(es_raw).round(),
      },
      'emotionalBaseline': {
        'stability': normalize(stability_raw).round(),
        'stressLoad': normalize(stress_raw).round(),
        'optimism': normalize(optimism_raw).round(),
      },
      'motivation': {
        'autonomy': normalize(autonomy).round(),
        'smallSteps': normalize(smallSteps).round(),
        'initiation': normalize(initiation).round(),
        'progressFocus': normalize(progress).round(),
      },
      'supportStyle': {
        'reflective': normalize(reflection).round(),
        'gentleTone': normalize(gentleTone).round(),
        'writingHelpful': normalize(writingHelpful).round(),
      },
      'completedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex];
    final isAnswered = answers.containsKey(question.id);

    return Scaffold(
      backgroundColor: const Color(0xFF61FF8F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF61FF8F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (currentQuestionIndex > 0) {
              _previousQuestion();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Psychological Assessment',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      question.module,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${currentQuestionIndex + 1}/${questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF2D5A45)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Question Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Question Text
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Answer Options
                    ...List.generate(5, (index) {
                      final value = index + 1;
                      final isSelected = answers[question.id] == value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _answerQuestion(value),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2D5A45)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2D5A45)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF2D5A45),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    question.scaleLabels[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 40),

                    // Disclaimer (show on first question)
                    if (currentQuestionIndex == 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Color(0xFF2D5A45),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'These questions provide self-reflection insights. They are not medical or psychological diagnoses.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation hint
          if (isAnswered)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                currentQuestionIndex < questions.length - 1
                    ? 'Your answer has been recorded. Tap another option to change it.'
                    : 'Processing your results...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Results Screen
class AssessmentResultsScreen extends StatelessWidget {
  final Map<String, dynamic> results;

  const AssessmentResultsScreen({Key? key, required this.results})
      : super(key: key);

  String _getInterpretation(int score) {
    if (score < 40) return 'Low';
    if (score < 70) return 'Moderate';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF61FF8F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF61FF8F),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Your Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Message
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF61FF8F),
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Assessment Complete!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We\'ve created your personalized profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personality Traits
            _ResultSection(
              title: 'Personality Traits',
              items: {
                'Openness':
                    results['personality']['openness'],
                'Conscientiousness':
                    results['personality']['conscientiousness'],
                'Extraversion':
                    results['personality']['extraversion'],
                'Agreeableness':
                    results['personality']['agreeableness'],
                'Emotional Sensitivity':
                    results['personality']['emotionalSensitivity'],
              },
            ),
            const SizedBox(height: 16),

            // Emotional Baseline
            _ResultSection(
              title: 'Emotional Baseline',
              items: {
                'Stability':
                    results['emotionalBaseline']['stability'],
                'Stress Load':
                    results['emotionalBaseline']['stressLoad'],
                'Optimism':
                    results['emotionalBaseline']['optimism'],
              },
            ),
            const SizedBox(height: 16),

            // Motivation
            _ResultSection(
              title: 'Motivation',
              items: {
                'Autonomy':
                    results['motivation']['autonomy'],
                'Small Steps Preference':
                    results['motivation']['smallSteps'],
                'Task Initiation':
                    results['motivation']['initiation'],
                'Progress Focus':
                    results['motivation']['progressFocus'],
              },
            ),
            const SizedBox(height: 16),

            // Support Style
            _ResultSection(
              title: 'Support Style',
              items: {
                'Reflective':
                    results['supportStyle']['reflective'],
                'Gentle Tone':
                    results['supportStyle']['gentleTone'],
                'Writing Helpful':
                    results['supportStyle']['writingHelpful'],
              },
            ),
            const SizedBox(height: 32),

            // Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save to Firestore
                  print('Saving results: $results');
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A45),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Complete Setup',
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
    );
  }
}

// Result Section Widget
class _ResultSection extends StatelessWidget {
  final String title;
  final Map<String, int> items;

  const _ResultSection({
    required this.title,
    required this.items,
  });

  String _getInterpretation(int score) {
    if (score < 40) return 'Low';
    if (score < 70) return 'Moderate';
    return 'High';
  }

  Color _getColor(int score) {
    if (score < 40) return Colors.orange;
    if (score < 70) return Colors.blue;
    return const Color(0xFF61FF8F);
  }

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...items.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 14,
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
                              color: _getColor(entry.value).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getInterpretation(entry.value),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getColor(entry.value),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getColor(entry.value)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}