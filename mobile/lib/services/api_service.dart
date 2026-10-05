import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/experiment.dart';
import '../models/analytics.dart';

class ApiService {
  // Default to localhost:8000 (or 10.0.2.2 for Android emulator)
  static String baseUrl = 'http://127.0.0.1:8000/api/v1';

  static dynamic _decodeJson(http.Response response) {
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to connect to backend: ${response.statusCode}');
  }

  static Future<List<Experiment>> getExperiments() async {
    final response = await http.get(Uri.parse('$baseUrl/experiments'));
    if (response.statusCode == 200) {
      final List<dynamic> list = _decodeJson(response);
      return list.map((e) => Experiment.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch experiments: ${response.statusCode}');
  }

  static Future<Experiment> getExperiment(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/experiments/$id'));
    if (response.statusCode == 200) {
      return Experiment.fromJson(_decodeJson(response));
    }
    throw Exception('Failed to fetch experiment $id');
  }

  static Future<Experiment> createExperiment({
    required String name,
    required String targetModel,
    required String judgeModel,
    required List<String> languages,
    required List<String> promptTypes,
    bool guardrailEnabled = false,
    String defenseStrategy = 'NONE',
    String evaluationMode = 'STATIC',
    String? customBaseUrl,
    String? customApiKey,
    String? idempotencyKey,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'target_model': targetModel,
      'judge_model': judgeModel,
      'languages': languages,
      'prompt_types': promptTypes,
      'temperature': 0.0,
      'max_tokens': 1024,
      'guardrail_enabled': guardrailEnabled,
      'guardrail_type': 'regex_heuristic',
      'defense_strategy': defenseStrategy,
      'evaluation_mode': evaluationMode,
    };

    if (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) {
      payload['custom_base_url'] = customBaseUrl.trim();
    }
    if (customApiKey != null && customApiKey.trim().isNotEmpty) {
      payload['custom_api_key'] = customApiKey.trim();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) 'X-Idempotency-Key': idempotencyKey,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/experiments'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Experiment.fromJson(_decodeJson(response));
    }
    throw Exception('Failed to create experiment: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<List<ModelResponseDetail>> getExperimentResults(String experimentId) async {
    final response = await http.get(Uri.parse('$baseUrl/experiments/$experimentId/results'));
    if (response.statusCode == 200) {
      final List<dynamic> list = _decodeJson(response);
      return list.map((r) => ModelResponseDetail.fromJson(r)).toList();
    }
    throw Exception('Failed to fetch experiment results');
  }

  static Future<RQ1Metrics> getRQ1Analytics(String experimentId) async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/rq1/$experimentId'));
    if (response.statusCode == 200) {
      return RQ1Metrics.fromJson(_decodeJson(response));
    }
    throw Exception('Failed to fetch RQ1 analytics');
  }

  static Future<RQ2Metrics> getRQ2Analytics(String experimentId) async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/rq2/$experimentId'));
    if (response.statusCode == 200) {
      return RQ2Metrics.fromJson(_decodeJson(response));
    }
    throw Exception('Failed to fetch RQ2 analytics');
  }

  static Future<void> submitHumanAnnotation({
    required String responseId,
    required String annotatorId,
    required String humanLabel,
    String? notes,
  }) async {
    final payload = {
      'response_id': responseId,
      'annotator_id': annotatorId,
      'human_label': humanLabel,
      'notes': notes,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/annotations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to submit annotation: ${response.body}');
    }
  }

  static String getExportCsvUrl(String experimentId) {
    return '$baseUrl/experiments/$experimentId/export/csv';
  }

  static Future<Map<String, dynamic>> runAdaptiveRedTeam({
    required String seedPrompt,
    required String language,
    required String targetModel,
    required String judgeModel,
    int maxIterations = 3,
  }) async {
    final payload = {
      'seed_prompt': seedPrompt,
      'language': language,
      'target_model': targetModel,
      'judge_model': judgeModel,
      'max_iterations': maxIterations,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/redteam/run'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to run Adaptive Red-Team: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<void> deleteExperiment(String experimentId) async {
    final response = await http.delete(Uri.parse('$baseUrl/experiments/$experimentId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete experiment $experimentId: ${utf8.decode(response.bodyBytes)}');
    }
  }

  static Future<Experiment> cloneExperiment(String experimentId) async {
    final response = await http.post(Uri.parse('$baseUrl/experiments/$experimentId/clone'));
    if (response.statusCode == 201) {
      return Experiment.fromJson(_decodeJson(response));
    }
    throw Exception('Failed to clone experiment $experimentId: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<Experiment> cancelExperiment(String experimentId) async {
    final response = await http.post(Uri.parse('$baseUrl/experiments/$experimentId/cancel'));
    if (response.statusCode == 200) {
      return Experiment.fromJson(_decodeJson(response));
    }
    throw Exception('Failed to cancel experiment $experimentId: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<Map<String, dynamic>> compareExperiments(
    String baselineId,
    String candidateId, {
    double ucrTolerance = 0.0,
  }) async {
    final uri = Uri.parse('$baseUrl/analytics/compare').replace(
      queryParameters: {
        'baseline_id': baselineId,
        'candidate_id': candidateId,
        'ucr_tolerance': ucrTolerance.toString(),
      },
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to compare experiments: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<Map<String, dynamic>> fetchRemediationReport(String experimentId) async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/remediation/$experimentId'));
    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to fetch remediation report: ${utf8.decode(response.bodyBytes)}');
  }

  static String getExportDpoUrl(String experimentId) {
    return '$baseUrl/analytics/remediation/$experimentId/dpo-export';
  }

  static Future<Map<String, dynamic>> inspectPrompt({
    required String promptText,
    String? language,
    String targetModel = 'gemini-1.5-flash',
    String judgeModel = 'gemini-1.5-flash',
    String promptType = 'harmful',
    String category = 'General',
    bool guardrailEnabled = true,
    String defenseStrategy = 'NONE',
  }) async {
    final payload = {
      'prompt_text': promptText,
      if (language != null) 'language': language,
      'target_model': targetModel,
      'judge_model': judgeModel,
      'prompt_type': promptType,
      'behavior_category': category,
      'guardrail_enabled': guardrailEnabled,
      'defense_strategy': defenseStrategy,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/evaluations/inspect-prompt'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to inspect prompt: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<String> fetchExecutiveReportMarkdown(String experimentId) async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/report/$experimentId/markdown'));
    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    }
    throw Exception('Failed to fetch executive report: ${utf8.decode(response.bodyBytes)}');
  }

  static String getExportReportMarkdownUrl(String experimentId) {
    return '$baseUrl/analytics/report/$experimentId/markdown';
  }

  static Future<Map<String, dynamic>> createCustomPromptPair({
    required String category,
    required String promptType,
    required String englishPrompt,
    required String nepaliPrompt,
    String? englishDescription,
    String? sourceId,
    String? idempotencyKey,
  }) async {
    final payload = {
      'category': category,
      'prompt_type': promptType,
      'english_prompt': englishPrompt,
      'nepali_prompt': nepaliPrompt,
      if (englishDescription != null && englishDescription.isNotEmpty) 'english_description': englishDescription,
      if (sourceId != null && sourceId.isNotEmpty) 'source_id': sourceId,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) 'X-Idempotency-Key': idempotencyKey,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/behaviors/custom'),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to create custom prompt pair: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<String> translatePrompt(
    String text, {
    String sourceLanguage = 'en',
    String targetLanguage = 'ne',
  }) async {
    final payload = {
      'text': text,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/behaviors/translate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final data = _decodeJson(response);
      return data['translated_text'] as String;
    }
    throw Exception('Failed to translate prompt: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<Map<String, dynamic>> fetchLegalSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/legal/summary'));
    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to fetch legal summary: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<Map<String, dynamic>> fetchConsentInfo() async {
    final response = await http.get(Uri.parse('$baseUrl/legal/consent-info'));
    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to fetch consent info: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<String> fetchLegalDocument(String docType) async {
    final response = await http.get(Uri.parse('$baseUrl/legal/$docType'));
    if (response.statusCode == 200) {
      final data = _decodeJson(response);
      return data['content'] as String? ?? '';
    }
    throw Exception('Failed to fetch legal document: ${utf8.decode(response.bodyBytes)}');
  }

  static Future<void> deleteBehavior(String behaviorId) async {
    final response = await http.delete(Uri.parse('$baseUrl/behaviors/$behaviorId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete behavior: ${utf8.decode(response.bodyBytes)}');
    }
  }

  static Future<Map<String, dynamic>> updateBehavior(String behaviorId, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('$baseUrl/behaviors/$behaviorId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    if (response.statusCode == 200) {
      return _decodeJson(response);
    }
    throw Exception('Failed to update behavior: ${utf8.decode(response.bodyBytes)}');
  }
}



