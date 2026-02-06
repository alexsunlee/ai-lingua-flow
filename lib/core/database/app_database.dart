import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../constants/app_constants.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_texts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        original_text TEXT NOT NULL,
        source_type TEXT NOT NULL,
        source_language TEXT NOT NULL DEFAULT 'en',
        target_language TEXT NOT NULL DEFAULT 'zh',
        analysis_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE paragraphs (
        id TEXT PRIMARY KEY,
        study_text_id TEXT NOT NULL,
        paragraph_index INTEGER NOT NULL,
        original_text TEXT NOT NULL,
        translated_text TEXT,
        knowledge_json TEXT,
        summary TEXT,
        FOREIGN KEY (study_text_id) REFERENCES study_texts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE video_resources (
        id TEXT PRIMARY KEY,
        youtube_url TEXT NOT NULL,
        youtube_video_id TEXT NOT NULL,
        title TEXT NOT NULL,
        channel_name TEXT,
        thumbnail_url TEXT,
        duration_seconds INTEGER,
        audio_file_path TEXT,
        study_text_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (study_text_id) REFERENCES study_texts(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transcript_segments (
        id TEXT PRIMARY KEY,
        video_resource_id TEXT NOT NULL,
        segment_index INTEGER NOT NULL,
        start_ms INTEGER NOT NULL,
        end_ms INTEGER NOT NULL,
        original_text TEXT NOT NULL,
        translated_text TEXT,
        FOREIGN KEY (video_resource_id) REFERENCES video_resources(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vocabulary_entries (
        id TEXT PRIMARY KEY,
        word TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        pronunciation TEXT,
        translation TEXT,
        explanation TEXT,
        etymology TEXT,
        example_sentences TEXT,
        synonyms TEXT,
        source_type TEXT,
        source_id TEXT,
        source_context TEXT,
        audio_file_path TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(word, language)
      )
    ''');

    await db.execute('''
      CREATE TABLE review_schedules (
        id TEXT PRIMARY KEY,
        vocabulary_entry_id TEXT NOT NULL UNIQUE,
        repetition_count INTEGER NOT NULL DEFAULT 0,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0,
        next_review_date TEXT NOT NULL,
        last_review_date TEXT,
        last_quality INTEGER,
        FOREIGN KEY (vocabulary_entry_id) REFERENCES vocabulary_entries(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shadowing_sessions (
        id TEXT PRIMARY KEY,
        source_type TEXT NOT NULL,
        source_id TEXT NOT NULL,
        sentence_text TEXT NOT NULL,
        sentence_index INTEGER NOT NULL DEFAULT 0,
        recording_file_path TEXT,
        recognized_text TEXT,
        pronunciation_score REAL,
        feedback_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE learning_activities (
        id TEXT PRIMARY KEY,
        activity_type TEXT NOT NULL,
        source_id TEXT,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        words_encountered INTEGER NOT NULL DEFAULT 0,
        new_words_added INTEGER NOT NULL DEFAULT 0,
        content_difficulty_score REAL,
        metadata_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE assessment_reports (
        id TEXT PRIMARY KEY,
        report_type TEXT NOT NULL,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        overall_score REAL,
        dimensions_json TEXT,
        summary_text TEXT,
        recommendations_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Indexes
    await db.execute(
        'CREATE INDEX idx_paragraphs_study_text ON paragraphs(study_text_id)');
    await db.execute(
        'CREATE INDEX idx_transcript_video ON transcript_segments(video_resource_id)');
    await db.execute(
        'CREATE INDEX idx_review_next ON review_schedules(next_review_date)');
    await db.execute(
        'CREATE INDEX idx_vocab_word ON vocabulary_entries(word)');
    await db.execute(
        'CREATE INDEX idx_activities_type ON learning_activities(activity_type)');
    await db.execute(
        'CREATE INDEX idx_activities_date ON learning_activities(created_at)');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
