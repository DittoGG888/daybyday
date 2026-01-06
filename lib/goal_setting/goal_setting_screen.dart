import 'package:daybyday/services/user_service.dart';
import 'package:daybyday/services/goal_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Goal Model
class Goal {
  final String id;
  final String description;
  final String category;
  final String duration; // 'daily', 'weekly', 'monthly', 'yearly', 'specific'
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String? time;
  final DateTime? specificDate; // For specific date goals

  Goal({
    required this.id,
    required this.description,
    required this.category,
    required this.duration,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.time,
    this.specificDate,
  });

  Goal copyWith({bool? isCompleted, DateTime? completedAt}) {
    return Goal(
      id: id,
      description: description,
      category: category,
      duration: duration,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      time: time,
      specificDate: specificDate,
    );
  }

  factory Goal.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return Goal(
      id: m['id']?.toString() ?? '',
      description: (m['description'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      duration: (m['duration'] ?? '') as String,
      isCompleted: (m['isCompleted'] ?? false) as bool,
      completedAt: parseDate(m['completedAt']),
      createdAt: parseDate(m['createdAt']) ?? DateTime.now(),
      time: m['time'] as String?,
      specificDate: parseDate(m['specificDate']),
    );
  }
}

// My Goals Screen
class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({Key? key}) : super(key: key);

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _goalService = GoalService();
  String selectedTab = 'Daily';
  List<Goal> goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }
  Future<void> _loadGoals() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final loadedGoals = await _goalService.getGoals(userId);
      setState(() {
        goals = loadedGoals
            .map((g) => Goal.fromMap(g as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Goal> get filteredGoals {
    return goals.where((goal) {
      return goal.duration.toLowerCase() == selectedTab.toLowerCase();
    }).toList();
  }

  void _toggleGoalCompletion(Goal goal) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final goalId = goal.id;
    final newCompletionState = !goal.isCompleted;

    // Optimistic update
    setState(() {
      final index = goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        goals[index] = goals[index].copyWith(
          isCompleted: newCompletionState,
          completedAt: newCompletionState ? DateTime.now() : null,
        );
      }
    });

    try {
      await _goalService.toggleGoalCompletion(
        userId,
        goalId,
        newCompletionState,
      );
    } catch (e) {
      // Revert on error
      setState(() {
        final index = goals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          goals[index] = goals[index].copyWith(
            isCompleted: !newCompletionState,
            completedAt: null,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Goal> get activeGoals {
    return filteredGoals.where((goal) => !goal.isCompleted).toList();
  }

  List<Goal> get completedGoals {
    return filteredGoals.where((goal) => goal.isCompleted).toList();
  }

  int get totalGoals => filteredGoals.length;
  int get completedCount => completedGoals.length;
  double get progressPercentage =>
      totalGoals > 0 ? (completedCount / totalGoals * 100) : 0;


  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'mindfulness':
        return Colors.purple;
      case 'career':
        return Colors.blue;
      case 'health':
        return const Color(0xFF61FF8F);
      case 'education':
        return Colors.orange;
      case 'finance':
        return Colors.teal;
      case 'relationships':
        return Colors.pink;
      default:
        return Colors.grey;
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
          'My Goals',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              // Settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                // Tab Bar
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['Daily', 'Weekly', 'Monthly'].map((tab) {
                      final isSelected = selectedTab == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedTab = tab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF61FF8F)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tab,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Progress Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
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
                          const Text(
                            'Daily Progress',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${progressPercentage.round()}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF61FF8F),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedCount of $totalGoals completed',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${totalGoals - completedCount} remaining',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Today's Focus Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Today\'s Focus',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // See all
                                },
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    color: Color(0xFF2D5A45),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Active Goals
                        ...activeGoals.map(
                          (goal) => _GoalCard(
                            goal: goal,
                            categoryColor: _getCategoryColor(goal.category),
                            onToggle: () => _toggleGoalCompletion(goal),
                          ),
                        ),

                        // Completed Section
                        if (completedGoals.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Text(
                              'COMPLETED',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          ...completedGoals.map(
                            (goal) => _GoalCard(
                              goal: goal,
                              categoryColor: _getCategoryColor(goal.category),
                              onToggle: () => _toggleGoalCompletion(goal),
                            ),
                          ),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final newGoal = await Navigator.push<Goal>(
              context,
              MaterialPageRoute(builder: (context) => const SetNewGoalScreen()),
            );
            if (newGoal != null) {
              setState(() {
                goals.add(newGoal);
              });
            }
          },
          backgroundColor: const Color(0xFF1A2F26),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Goal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Goal Card Widget
class _GoalCard extends StatelessWidget {
  final Goal goal;
  final Color categoryColor;
  final VoidCallback onToggle;

  const _GoalCard({
    required this.goal,
    required this.categoryColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: goal.isCompleted
                      ? const Color(0xFF61FF8F)
                      : Colors.grey[400]!,
                  width: 2,
                ),
                color: goal.isCompleted
                    ? const Color(0xFF61FF8F)
                    : Colors.transparent,
              ),
              child: goal.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.black87)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.description,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: goal.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (goal.time != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        goal.time!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              goal.category.toUpperCase(),
              style: TextStyle(
                color: categoryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Set New Goal Screen
class SetNewGoalScreen extends StatefulWidget {
  const SetNewGoalScreen({Key? key}) : super(key: key);

  @override
  State<SetNewGoalScreen> createState() => _SetNewGoalScreenState();
}

class _SetNewGoalScreenState extends State<SetNewGoalScreen> {
  final _goalService = GoalService();
  final _userService = UserService();
  String selectedDuration = 'Daily';
  String? selectedCategory;
  DateTime? selectedDate;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  bool useCustomCategory = false;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Health', 'icon': Icons.favorite},
    {'name': 'Career', 'icon': Icons.work},
    {'name': 'Mindfulness', 'icon': Icons.self_improvement},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Finance', 'icon': Icons.account_balance_wallet},
    {'name': 'Relationships', 'icon': Icons.people},
  ];

  bool get canSave =>
      _descriptionController.text.isNotEmpty &&
      (selectedCategory != null || _customCategoryController.text.isNotEmpty) &&
      (selectedDuration != 'Specific Date' || selectedDate != null);

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF61FF8F),
              onPrimary: Colors.black87,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

   void _saveGoal() async {
    if (!canSave) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Save to Firestore
      final goalId = await _goalService.createGoal(
        userId: userId,
        description: _descriptionController.text,
        category: useCustomCategory 
            ? _customCategoryController.text 
            : selectedCategory!,
        duration: selectedDuration == 'Specific Date' 
            ? 'specific' 
            : selectedDuration.toLowerCase(),
        specificDate: selectedDuration == 'Specific Date' ? selectedDate : null,
      );

      // Mark goals as set (for first-time users)
      await _userService.markGoalsSet(userId);

      // Create Goal object to return
      final newGoal = Goal(
        id: goalId,
        description: _descriptionController.text,
        category: useCustomCategory
            ? _customCategoryController.text
            : selectedCategory!,
        duration: selectedDuration == 'Specific Date'
            ? 'specific'
            : selectedDuration.toLowerCase(),
        specificDate: selectedDuration == 'Specific Date' ? selectedDate : null,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context, newGoal);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Set New Goal',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration Selection
            const Text(
              'Duration',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  [
                    'Daily',
                    'Weekly',
                    'Monthly',
                    'Yearly',
                    'Specific Date',
                  ].map((duration) {
                    final isSelected = selectedDuration == duration;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedDuration = duration);
                        if (duration == 'Specific Date') {
                          _selectDate();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF2D5A45),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (duration == 'Specific Date' &&
                                selectedDate != null) ...[
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF2D5A45)
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              duration == 'Specific Date' &&
                                      selectedDate != null
                                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                  : duration,
                              style: TextStyle(
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
            if (selectedDuration == 'Specific Date' && selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF2D5A45),
                  ),
                  label: const Text(
                    'Change date',
                    style: TextStyle(color: Color(0xFF2D5A45)),
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Goal Description
            const Text(
              'Goal Description',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'What do you want to achieve?',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  suffixIcon: Icon(
                    Icons.edit,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 32),

            // Category Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          useCustomCategory = !useCustomCategory;
                          if (useCustomCategory) {
                            selectedCategory = null;
                          } else {
                            _customCategoryController.clear();
                          }
                        });
                      },
                      child: Text(
                        useCustomCategory ? 'Use Preset' : 'Custom',
                        style: const TextStyle(
                          color: Color(0xFF2D5A45),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'REQUIRED',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Custom Category Input
            if (useCustomCategory) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF61FF8F), width: 2),
                ),
                child: TextField(
                  controller: _customCategoryController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Enter custom category...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.category,
                      color: Color(0xFF61FF8F),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your own category for this goal',
                style: TextStyle(
                  color: Colors.black87.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ] else ...[
              // Preset Categories Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => selectedCategory = category['name']),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF61FF8F)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            color: isSelected
                                ? const Color(0xFF61FF8F)
                                : Colors.black87,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF61FF8F)
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
                },
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: canSave ? _saveGoal : null,
          backgroundColor: canSave ? const Color(0xFF1A2F26) : Colors.grey[400],
          label: Text(
            'Save Goal',
            style: TextStyle(
              color: canSave ? Colors.white : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }
}
