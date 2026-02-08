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
  /// Always ensures Chinese translation and etymology are present via Gemini.
  Future<WordCardData> lookup(String word) async {
    final normalizedWord = word.trim().toLowerCase();

    // Tier 1: Local DB
    final localResult = await _lookupLocal(normalizedWord);
    if (localResult != null && _isComplete(localResult)) return localResult;

    // Tier 2: Free Dictionary API
    WordCardData? apiResult;
    try {
      apiResult = await _lookupFreeDictionary(normalizedWord);
    } catch (_) {
      // Fall through
    }

    // Tier 3: Gemini API — used as primary or to supplement Tier 2
    try {
      if (apiResult != null) {
        // Supplement missing Chinese translation & etymology from Gemini
        final supplemented = await _supplementWithGemini(apiResult);
        await _cacheResult(supplemented);
        return supplemented;
      } else if (localResult != null) {
        // Local cache exists but incomplete — supplement it
        final supplemented = await _supplementWithGemini(localResult);
        await _updateCache(supplemented);
        return supplemented;
      } else {
        // Full Gemini lookup
        final geminiResult = await _lookupGemini(normalizedWord);
        await _cacheResult(geminiResult);
        return geminiResult;
      }
    } catch (e) {
      // Return whatever we have
      return apiResult ?? localResult ?? WordCardData(word: normalizedWord);
    }
  }

  /// Check if a WordCardData has all key fields populated.
  bool _isComplete(WordCardData data) {
    return data.translation != null &&
        data.translation!.isNotEmpty &&
        data.etymology != null &&
        data.etymology!.isNotEmpty;
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

  /// Supplement a partial result (from Free Dictionary API or local cache)
  /// with Chinese translation and etymology from Gemini.
  Future<WordCardData> _supplementWithGemini(WordCardData partial) async {
    final prompt = '''
For the English word "${partial.word}", provide ONLY these two fields for a Chinese learner.
Return JSON with:
- translation: Chinese translation (简体中文, concise)
- etymology: word origin/root (brief, in Chinese, e.g. 来自拉丁语 xxx，意为 yyy)
''';

    final result = await _geminiClient.generateStructured(prompt: prompt);

    return WordCardData(
      word: partial.word,
      pronunciation: partial.pronunciation,
      translation: result['translation'] as String? ?? partial.translation,
      explanation: partial.explanation,
      etymology: result['etymology'] as String? ?? partial.etymology,
      examples: partial.examples,
      synonyms: partial.synonyms,
      isInVocabulary: partial.isInVocabulary,
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

  /// Update an existing cache entry with supplemented data.
  Future<void> _updateCache(WordCardData data) async {
    final db = await AppDatabase.database;
    await db.update(
      'vocabulary_entries',
      {
        'translation': data.translation,
        'etymology': data.etymology,
        'pronunciation': data.pronunciation,
        'explanation': data.explanation,
        'example_sentences': jsonEncode(data.examples),
        'synonyms': jsonEncode(data.synonyms),
      },
      where: 'LOWER(word) = ? AND language = ?',
      whereArgs: [data.word.toLowerCase(), 'en'],
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
