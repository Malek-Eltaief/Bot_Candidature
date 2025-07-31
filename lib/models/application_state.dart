import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApplicationState with ChangeNotifier {
  final Logger _logger = Logger();
  final List<Map<String, String>> _messages = [];
  final List<String> _questions = [];
  int _currentQuestionIndex = 0;
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isInitialized = false;
  final String _apiKey = "AIzaSyDR03TRCXDlAD89PBAAEnPThydoghRjYVM"; // À sécuriser avec .env à l'avenir
  String? _jobId;

  List<Map<String, String>> get messages => _messages;
  List<String> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isInitialized => _isInitialized;

  // Constructeur asynchrone pour initialisation différée
  ApplicationState() {
    _initializeModel(); // Initialisation par défaut sans jobData
  }

  // Méthode pour initialiser avec jobData
  Future<void> initializeWithJobData(Map<String, dynamic>? jobData) async {
    if (jobData != null && jobData['id'] != null) {
      _jobId = jobData['id'] as String;
      _logger.d('Initialized with jobId: $_jobId');
      if (!_isInitialized) await _initializeModel(); // Réinitialiser si nécessaire
    } else {
      _logger.e('Job data or jobId is null');
    }
  }

  // Initialisation asynchrone avec gestion des erreurs
  Future<void> _initializeModel() async {
    _logger.d('Initializing model with API key: $_apiKey');
    try {
      // Vérifier l'authentification Firebase avant de continuer
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.w('User not authenticated, initializing with limited functionality');
        _isInitialized = true;
        notifyListeners();
        return;
      }

      _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
      final initialResponse = await _model.generateContent([
        Content.text(
            'Generate a list of up to 5 personalized questions in English about experience, skills, or availability for a Flutter developer job. Format each question with a number (e.g., 1., 2., etc.) and return only the list.')
      ]);
      if (initialResponse.text != null) {
        _questions.addAll(_parseQuestions(initialResponse.text!));
        _chat = _model.startChat();
        addMessage('bot', 'Hello! I am your assistant to apply for the offer "${_jobId ?? 'unknown job'}".');
        _askNextQuestion();
      } else {
        _logger.e('No text response from Gemini API');
        addMessage('bot', 'Error: No questions generated. Proceeding with limited functionality.');
      }
    } catch (e) {
      _logger.e('Error initializing chatbot: $e');
      addMessage('bot', 'Error during initialization: $e. Proceeding with limited functionality.');
    }
    _isInitialized = true;
    notifyListeners();
  }

  List<String> _parseQuestions(String text) {
    final lines = text.split('\n').where((line) => line.trim().startsWith(RegExp(r'[1-5]\.'))).toList();
    return lines.map((line) => line.trim().replaceFirst(RegExp(r'[1-5]\.\s*'), '')).take(5).toList();
  }

  void _askNextQuestion() {
    if (_currentQuestionIndex < _questions.length) {
      addMessage('bot', _questions[_currentQuestionIndex]);
      notifyListeners();
    }
  }

  void addMessage(String role, String text) {
    _messages.add({'role': role, 'text': text});
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    _logger.d('Attempting to send message: $message, isInitialized: $_isInitialized');
    if (!_isInitialized || message.isEmpty) {
      _logger.e('Send failed: Not initialized or message empty');
      return;
    }
    addMessage('user', message);
    await _storeResponse(message);

    if (_messages.last['text']?.contains('Error: Job ID is missing') ?? false) return;

    if (_currentQuestionIndex < _questions.length) {
      _currentQuestionIndex++;
      if (_currentQuestionIndex < _questions.length) {
        _askNextQuestion();
      } else {
        try {
          final summaryResponse = await _chat.sendMessage(
            Content.text('Summarize the candidate\'s responses and provide a closing message.'),
          );
          addMessage('bot', summaryResponse.text ?? 'Thank you for your responses!');
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          _logger.e('Error getting summary: $e');
          addMessage('bot', 'Error summarizing: $e. Please close manually.');
        }
      }
    }
  }

  Future<void> _storeResponse(String response) async {
    final jobId = _jobId;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    _logger.d('Attempting to store response - jobId: $jobId, userId: $userId');

    if (jobId == null) {
      _logger.e('Storage failed: jobId is null, userId=$userId');
      addMessage('bot', 'Error: Job ID is missing. Cannot proceed with application.');
      return;
    }
    if (userId == null) {
      _logger.e('Storage failed: userId is null, jobId=$jobId');
      addMessage('bot', 'Error: User not authenticated. Please log in.');
      return;
    }
    try {
      final question = _currentQuestionIndex > 0 ? _questions[_currentQuestionIndex - 1] : 'Initial message';
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(jobId)
          .set({
        'responses': FieldValue.arrayUnion([
          {
            'question': question,
            'answer': response,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          }
        ]),
        'jobId': jobId,
        'candidateId': userId,
      }, SetOptions(merge: true));
      _logger.d('Response and question stored successfully for job $jobId');
    } catch (e) {
      _logger.e('Error storing response for job $jobId: $e');
      addMessage('bot', 'Error storing response: $e. Please try again.');
    }
  }
}