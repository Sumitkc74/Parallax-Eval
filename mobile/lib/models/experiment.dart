class Experiment {
  final String id;
  final String name;
  final String targetModel;
  final String judgeModel;
  final String status;
  final int totalPrompts;
  final int completedPrompts;
  final DateTime createdAt;
  final String? errorMessage;
  final Map<String, dynamic> config;
  final String defenseStrategy;

  Experiment({
    required this.id,
    required this.name,
    required this.targetModel,
    required this.judgeModel,
    required this.status,
    required this.totalPrompts,
    required this.completedPrompts,
    required this.createdAt,
    this.errorMessage,
    this.config = const {},
    this.defenseStrategy = 'NONE',
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    final cfg = (json['config'] as Map<String, dynamic>?) ?? {};
    final def = (cfg['defense_strategy'] as String?) ?? 'NONE';
    return Experiment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      targetModel: json['target_model'] ?? '',
      judgeModel: json['judge_model'] ?? '',
      status: json['status'] ?? 'PENDING',
      totalPrompts: json['total_prompts'] ?? 0,
      completedPrompts: json['completed_prompts'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      errorMessage: json['error_message'],
      config: cfg,
      defenseStrategy: def,
    );
  }

  double get progress => totalPrompts > 0 ? completedPrompts / totalPrompts : 0.0;
}

class ModelResponseDetail {
  final String id;
  final String responseText;
  final int latencyMs;
  final String promptText;
  final String language;
  final String promptType;
  final String category;
  final String? finalLabel;
  final double? confidence;
  final String? judgeLabel;
  final String? judgeReasoning;
  final String? criticRecommendation;
  final String? criticCritique;
  final List<dynamic> annotations;
  final bool guardrailIntervened;
  final Map<String, dynamic>? guardrailDetails;
  final List<dynamic> redTeamAttempts;

  ModelResponseDetail({
    required this.id,
    required this.responseText,
    required this.latencyMs,
    required this.promptText,
    required this.language,
    required this.promptType,
    required this.category,
    this.finalLabel,
    this.confidence,
    this.judgeLabel,
    this.judgeReasoning,
    this.criticRecommendation,
    this.criticCritique,
    required this.annotations,
    this.guardrailIntervened = false,
    this.guardrailDetails,
    this.redTeamAttempts = const [],
  });

  factory ModelResponseDetail.fromJson(Map<String, dynamic> json) {
    final prompt = json['prompt'] ?? {};
    final behavior = prompt['behavior'] ?? {};
    final eval = json['evaluation'];

    return ModelResponseDetail(
      id: json['id'] ?? '',
      responseText: json['response_text'] ?? '',
      latencyMs: json['latency_ms'] ?? 0,
      promptText: prompt['prompt_text'] ?? '',
      language: prompt['language'] ?? 'en',
      promptType: behavior['prompt_type'] ?? 'benign',
      category: behavior['category'] ?? 'General',
      finalLabel: eval != null ? eval['final_label'] : null,
      confidence: eval != null ? (eval['confidence_score'] as num?)?.toDouble() : null,
      judgeLabel: eval != null ? eval['judge_label'] : null,
      judgeReasoning: eval != null ? eval['judge_reasoning'] : null,
      criticRecommendation: eval != null ? eval['critic_recommendation'] : null,
      criticCritique: eval != null ? eval['critic_critique'] : null,
      annotations: json['annotations'] ?? [],
      guardrailIntervened: json['guardrail_intervened'] ?? false,
      guardrailDetails: json['guardrail_details'],
      redTeamAttempts: json['red_team_attempts'] ?? [],
    );
  }
}

