import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/gemini_client.dart';
import '../../../../injection.dart';
import '../../../../services/data_export_service.dart';
import '../../../../services/gemini_tts_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isValidating = false;
  bool _isKeyConfigured = false;
  bool _obscureKey = true;
  String _selectedVoice = AppConstants.geminiTtsDefaultVoice;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadVoicePreference();
  }

  Future<void> _loadApiKey() async {
    final key = await _storage.read(key: AppConstants.keyGeminiApiKey);
    if (key != null && key.isNotEmpty) {
      setState(() {
        _apiKeyController.text = key;
        _isKeyConfigured = true;
      });
    }
  }

  Future<void> _loadVoicePreference() async {
    final voice = await _storage.read(key: AppConstants.keyGeminiTtsVoice);
    if (voice != null && AppConstants.geminiTtsVoices.contains(voice)) {
      setState(() => _selectedVoice = voice);
      getIt<GeminiTtsService>().setVoice(voice);
    }
  }

  Future<void> _validateAndSave() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      _showSnackBar('请输入 API 密钥');
      return;
    }

    setState(() => _isValidating = true);

    try {
      final geminiClient = getIt<GeminiClient>();
      final isValid = await geminiClient.validateApiKey(key);

      if (isValid) {
        await _storage.write(key: AppConstants.keyGeminiApiKey, value: key);
        geminiClient.configure(key);
        setState(() => _isKeyConfigured = true);
        _showSnackBar('API 密钥验证成功');
      } else {
        _showSnackBar('API 密钥无效，请检查后重试');
      }
    } catch (e) {
      _showSnackBar('验证失败: $e');
    } finally {
      setState(() => _isValidating = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Key Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isKeyConfigured ? Icons.check_circle : Icons.key,
                        color: _isKeyConfigured
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('Gemini API 密钥', style: theme.textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '需要 Google Gemini API 密钥来使用 AI 功能',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      hintText: '输入你的 Gemini API 密钥',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscureKey
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscureKey = !_obscureKey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isValidating ? null : _validateAndSave,
                      child: _isValidating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('验证并保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AI Voice Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('AI 语音设置', style: theme.textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择 Gemini AI 语音（需要 API 密钥和网络）',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVoice,
                    decoration: const InputDecoration(
                      labelText: '语音',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.geminiTtsVoices
                        .map((voice) => DropdownMenuItem(
                              value: voice,
                              child: Text(voice),
                            ))
                        .toList(),
                    onChanged: (voice) async {
                      if (voice == null) return;
                      setState(() => _selectedVoice = voice);
                      getIt<GeminiTtsService>().setVoice(voice);
                      await _storage.write(
                        key: AppConstants.keyGeminiTtsVoice,
                        value: voice,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        getIt<GeminiTtsService>().speak('Hello, how are you?');
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('试听'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Language Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('语言设置', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    '母语',
                    AppConstants.nativeLanguageName,
                    Icons.language,
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(
                    '学习语言',
                    AppConstants.targetLanguageName,
                    Icons.school,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'V1.0 版本固定为中文 → 英语',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data Management Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('数据管理', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('导出备份'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('导入备份'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关于', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    '版本',
                    AppConstants.appVersion,
                    Icons.info_outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final exportService = getIt<DataExportService>();
      final path = await exportService.exportData();
      if (mounted) {
        _showSnackBar('备份已导出: $path');
      }
    } catch (e) {
      _showSnackBar('导出失败: $e');
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final exportService = getIt<DataExportService>();
      final count = await exportService.importData(result.files.single.path!);
      if (mounted) {
        _showSnackBar('已导入 $count 条记录');
      }
    } catch (e) {
      _showSnackBar('导入失败: $e');
    }
  }

  Widget _buildSettingRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      ],
    );
  }
}
