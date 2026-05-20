import 'package:flutter/material.dart';
import '../data/local_json_data.dart';
import '../models/quiz_model.dart';

class QuizProvider with ChangeNotifier {
  List<QuizQuestion> _allQuestions = [];
  List<QuizQuestion> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  int _score = 0;
  List<Map<String, dynamic>> _history = []; // Holds list of { 'question': QuizQuestion, 'selectedIndex': int, 'isCorrect': bool }

  bool _isQuizActive = false;

  QuizProvider() {
    _loadQuestions();
  }

  bool get isQuizActive => _isQuizActive;
  List<QuizQuestion> get currentQuestions => _currentQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswered => _isAnswered;
  int get score => _score;
  List<Map<String, dynamic>> get history => _history;

  void _loadQuestions() {
    _allQuestions = LocalJsonData.quizQuestions
        .map((q) => QuizQuestion.fromJson(q))
        .toList();
  }

  void startQuiz(String? countryId, int totalQuestions) {
    // Note: We can filter questions by countryId if specific questions exist,
    // or shuffle and slice the global questions.
    final listCopy = List<QuizQuestion>.from(_allQuestions)..shuffle();
    _currentQuestions = listCopy.take(totalQuestions).toList();
    _currentQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _isAnswered = false;
    _score = 0;
    _history = [];
    _isQuizActive = true;
    notifyListeners();
  }

  void answerQuestion(int index) {
    if (_isAnswered) return;
    _selectedAnswerIndex = index;
    _isAnswered = true;

    final question = _currentQuestions[_currentQuestionIndex];
    final isCorrect = index == question.correctIndex;
    if (isCorrect) {
      _score++;
    }

    _history.add({
      'question': question,
      'selectedIndex': index,
      'isCorrect': isCorrect,
    });

    notifyListeners();
  }

  bool nextQuestion() {
    if (!_isAnswered) return false;

    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      _currentQuestionIndex++;
      _selectedAnswerIndex = null;
      _isAnswered = false;
      notifyListeners();
      return true; // Has next question
    } else {
      _isQuizActive = false;
      notifyListeners();
      return false; // Quiz completed
    }
  }

  void resetQuiz() {
    _isQuizActive = false;
    _currentQuestions = [];
    _currentQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _isAnswered = false;
    _score = 0;
    _history = [];
    notifyListeners();
  }
}
