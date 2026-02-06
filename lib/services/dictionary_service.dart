import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../core/database/app_database.dart';
import '../core/network/gemini_client.dart';
import '../core/widgets/word_card_popup.dart';

/// 3-tier dictionary lookup cascade:
/// 1. Local SQLite (bundled + cached)
/// 2. Free Dictionary API
/// 3. Gemini API fallback
class DictionaryService {
  final GeminiClient _geminiClient;
  final Dio _dio;

  DictionaryService({
    required GeminiClient geminiClient,
    Dio? dio,
  })  : _geminiClient = geminiClient,
        _dio = dio ?? Dio();

  /// Look up a word through the 3-tier cascade.
  /// Results are cached to SQLite for offline access.
  Future<WordCardData> lookup(String word) async {
    final normalizedWord = word.trim().toLowerCase();

    // Tier 1: Local DB
    final localResult = await _lookupLocal(normalizedWord);
    if (localResult != null) return localResult;

    // Tier 2: Free Dictionary API
    try {
      final apiResult = await _lookupFreeDictionary(normalizedWord);
      if (apiResult != null) {
        await _cacheResult(apiResult);
        return apiResult;
      }
    } catch (_) {
      // Fall through to Tier 3
    }

    // Tier 3: Gemini API
    try {
      final geminiResult = await _lookupGemini(normalizedWord);
      await _cacheResult(geminiResult);
      return geminiResult;
    } catch (e) {
      // Return minimal data
      return WordCardData(word: normalizedWord);
    }
  }

  /// Tier 1: Local SQLite lookup.
  Future<WordCardData?> _lookupLocal(String word) async {
    final db = await AppDatabase.database;
    final results = await db.query(
      'vocabulary_entries',
      where: 'LOWER(word) = ? AND language = ?',
      whereArgs: [word, 'en'],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final row = results.first;
    return WordCardData(
      word: row['word'] as String,
      pronunciation: row['pronunciation'] as String?,
      translation: row['translation'] as String?,
      explanation: row['explanation'] as String?,
      etymology: row['etymology'] as String?,
      examples: _parseJsonList(row['example_sentences'] as String?),
      synonyms: _parseJsonList(row['synonyms'] as String?),
      isInVocabulary: true,
    );
  }

  /// Tier 2: Free Dictionary API.
  Future<WordCardData?> _lookupFreeDictionary(String word) async {
    final response = await _dio.get(
      '${AppConstants.freeDictionaryBaseUrl}/$word',
    );

    if (response.statusCode != 200 || response.data is! List) return null;

    final data = (response.data as List).first as Map<String, dynamic>;
    final meanings = data['meanings'] as List? ?? [];

    String? phonetic;
    final phonetics = data['phonetics'] as List? ?? [];
    for (final p in phonetics) {
      final text = p['text'] as String?;
      if (text != null && text.isNotEmpty) {
        phonetic = text;
        break;
      }
    }

    String? definition;
    final examples = <String>[];
    final synonyms = <String>[];

    for (final meaning in meanings) {
      final defs = meaning['definitions'] as List? ?? [];
      for (final def in defs) {
        definition ??= def['definition'] as String?;
        final example = def['example'] as String?;
        if (example != null) examples.add(example);
      }
      final syns = meaning['synonyms'] as List? ?? [];
      for (final s in syns) {
        if (s is String) synonyms.add(s);
      }
    }

    return WordCardData(
      word: word,
      pronunciation: phonetic,
      explanation: definition,
      examples: examples.take(3).toList(),
      synonyms: synonyms.take(5).toList(),
    );
  }

  /// Tier 3: Gemini API fallback.
  Future<WordCardData> _lookupGemini(String word) async {
    final prompt = '''
Provide a dictionary entry for the English word "$word" for a Chinese learner.
Return JSON with these fields:
- word: the word
- pronunciation: IPA pronunciation
- translation: Chinese translation (简体中文)
- explanation: brief English definition
- etymology: word origin (brief, in Chinese)
- examples: array of 2 example sentences
- synonyms: array of up to 5 synonyms
''';

    final result = await _geminiClient.generateStructured(prompt: prompt);

    return WordCardData(
      word: result['word'] as String? ?? word,
      pronunciation: result['pronunciation'] as String?,
      translation: result['translation'] as String?,
      explanation: result['explanation'] as String?,
      etymology: result['etymology'] as String?,
      examples: (result['examples'] as List?)
              ?.map((e) => e.toString())
              .take(3)
              .toList() ??
          [],
      synonyms: (result['synonyms'] as List?)
              ?.map((e) => e.toString())
              .take(5)
              .toList() ??
          [],
    );
  }

  /// Cache a lookup result to the local vocabulary_entries table.
  Future<void> _cacheResult(WordCardData data) async {
    final db = await AppDatabase.database;
    await db.insert(
      'vocabulary_entries',
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'word': data.word,
        'language': 'en',
        'pronunciation': data.pronunciation,
        'translation': data.translation,
        'explanation': data.explanation,
        'etymology': data.etymology,
        'example_sentences': jsonEncode(data.examples),
        'synonyms': jsonEncode(data.synonyms),
        'source_type': 'dictionary_cache',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  List<String> _parseJsonList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
