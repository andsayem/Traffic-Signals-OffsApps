import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traffic_signal_symbols/ads/adaptive_banner_ad_widget.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/traffic_sign_painter.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? _selectedCountryId;
  int _questionCount = 5;
  bool _showReview = false;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      appBar: AppBar(title: Text(context.tr('quiz_title'))),
      child: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (!provider.isQuizActive && provider.history.isEmpty) {
            return _buildSetupView(context);
          } else if (provider.isQuizActive) {
            return _buildActiveQuizView(context, provider);
          } else {
            return _buildResultsView(context, provider);
          }
        },
      ),
    );
  }

  // 1. Setup Quiz View
  Widget _buildSetupView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trafficProvider = Provider.of<TrafficDataProvider>(context);
    final countries = trafficProvider.allCountries;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SizedBox(height: 16),
        // Decorative quiz icon (stop sign glowing)
        const Center(
          child: TrafficSignWidget(signId: 'stop', size: 110, isGlowing: true),
        ),
        const SizedBox(height: 32),

        GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('quiz_setup'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Country Dropdown Selector
              Text(
                context.tr('select_country'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : ThemeConstants.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _selectedCountryId,
                    dropdownColor: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    hint: Text(context.tr('select_all')),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(context.tr('select_all')),
                      ),
                      ...countries.map((c) {
                        return DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text("${c.flagEmoji} ${c.name}"),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedCountryId = val;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Question Count
              Text(
                context.tr('question_count'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : ThemeConstants.lightTextSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [5, 10].map((count) {
                  final isSel = _questionCount == count;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _questionCount = count;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? ThemeConstants.signalRed.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel
                              ? ThemeConstants.signalRed
                              : Colors.white10,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSel
                              ? ThemeConstants.signalRed
                              : (isDark ? Colors.white70 : ThemeConstants.lightTextSecondary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<QuizProvider>(
                      context,
                      listen: false,
                    ).startQuiz(_selectedCountryId, _questionCount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.signalRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.tr('start_quiz'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdaptiveBannerAdWidget(),
      ],
    );
  }

  // 2. Active Quiz Session View
  Widget _buildActiveQuizView(BuildContext context, QuizProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questions = provider.currentQuestions;
    final currentIndex = provider.currentQuestionIndex;
    final question = questions[currentIndex];

    final double progress = (currentIndex + 1) / questions.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Progress Info & Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${currentIndex + 1} of ${questions.length}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              "Score: ${provider.score}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: ThemeConstants.signalGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(
              ThemeConstants.signalRed,
            ),
            minHeight: 6,
          ),
        ),

        const SizedBox(height: 24),

        // Visual Vector Sign (if associated with the question)
        if (question.signId != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: TrafficSignWidget(signId: question.signId!, size: 130),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Question Title
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Text(
            question.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Options List
        ...List.generate(question.options.length, (index) {
          final option = question.options[index];
          final isAnswered = provider.isAnswered;
          final isSelected = provider.selectedAnswerIndex == index;
          final isCorrectOption = index == question.correctIndex;

          Color cardBorder = Colors.transparent;
          Color cardBackground = (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.04);
          Color textColor =
              isDark ? Colors.white : ThemeConstants.lightTextPrimary;

          if (isAnswered) {
            if (isCorrectOption) {
              cardBackground = ThemeConstants.signalGreen.withValues(
                alpha: 0.15,
              );
              cardBorder = ThemeConstants.signalGreen;
              textColor = ThemeConstants.signalGreen;
            } else if (isSelected) {
              cardBackground = ThemeConstants.signalRed.withValues(alpha: 0.15);
              cardBorder = ThemeConstants.signalRed;
              textColor = ThemeConstants.signalRed;
            } else {
              textColor = isDark ? Colors.white38 : Colors.black38;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              onTap: isAnswered ? null : () => provider.answerQuestion(index),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: 12,
              customColor: cardBackground,
              customBorderColor: cardBorder != Colors.transparent
                  ? cardBorder
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isAnswered && isCorrectOption
                          ? ThemeConstants.signalGreen
                          : (isAnswered && isSelected
                                ? ThemeConstants.signalRed
                                : Colors.white12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAnswered && (isCorrectOption || isSelected)
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Explanation & Next Action
        if (provider.isAnswered) ...[
          const SizedBox(height: 8),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            customColor: ThemeConstants.signalBlue.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: ThemeConstants.signalBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('explanation'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: ThemeConstants.signalBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question.explanation,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? Colors.white70 : ThemeConstants.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => provider.nextQuestion(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.signalRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                currentIndex == questions.length - 1
                    ? "Finish Quiz"
                    : "Next Question",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // 3. Results Summary View
  Widget _buildResultsView(BuildContext context, QuizProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = provider.currentQuestions.length;
    final score = provider.score;
    final pct = total > 0 ? (score / total) : 0.0;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Text(
            context.tr('quiz_results'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 28),

        // Circular Score Progress Ring
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 10,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct >= 0.7
                        ? ThemeConstants.signalGreen
                        : (pct >= 0.4
                              ? ThemeConstants.signalYellow
                              : ThemeConstants.signalRed),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$score / $total",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    context.tr('score'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : ThemeConstants.lightTextSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Grid stats (correct vs wrong)
        Row(
          children: [
            Expanded(
              child: GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 12),
                customColor: ThemeConstants.signalGreen.withValues(alpha: 0.08),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: ThemeConstants.signalGreen,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$score ${context.tr('correct_answers')}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 12),
                customColor: ThemeConstants.signalRed.withValues(alpha: 0.08),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      color: ThemeConstants.signalRed,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${total - score} ${context.tr('wrong_answers')}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showReview = !_showReview;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _showReview ? "Hide Answers" : context.tr('review_answers'),
                  style: TextStyle(
                    color: isDark ? Colors.white : ThemeConstants.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => provider.resetQuiz(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.signalRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.tr('retry'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Review Expandable Cards list
        if (_showReview) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final item = provider.history[index];
              final QuizQuestion question = item['question'];
              final int userIndex = item['selectedIndex'];
              final bool isCorrect = item['isCorrect'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  customBorderColor: isCorrect
                      ? ThemeConstants.signalGreen.withValues(alpha: 0.3)
                      : ThemeConstants.signalRed.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isCorrect
                                ? ThemeConstants.signalGreen
                                : ThemeConstants.signalRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.question,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your Answer: ${question.options[userIndex]}",
                        style: TextStyle(
                          fontSize: 11,
                          color: isCorrect
                              ? ThemeConstants.signalGreen
                              : ThemeConstants.signalRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isCorrect)
                        Text(
                          "Correct Answer: ${question.options[question.correctIndex]}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: ThemeConstants.signalGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 4),
                      Text(
                        question.explanation,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                          height: 1.4,
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
    );
  }
}
