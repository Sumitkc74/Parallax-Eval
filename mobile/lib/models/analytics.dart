class LanguageSafetyMetrics {
  final String language;
  final int totalPrompts;
  final int harmfulCount;
  final int benignCount;
  final double harmfulRefusalRate;
  final double unsafeComplianceRate;
  final double benignComplianceRate;
  final double overRefusalRate;

  LanguageSafetyMetrics({
    required this.language,
    required this.totalPrompts,
    required this.harmfulCount,
    required this.benignCount,
    required this.harmfulRefusalRate,
    required this.unsafeComplianceRate,
    required this.benignComplianceRate,
    required this.overRefusalRate,
  });

  factory LanguageSafetyMetrics.fromJson(Map<String, dynamic> json) {
    return LanguageSafetyMetrics(
      language: json['language'] ?? '',
      totalPrompts: json['total_prompts'] ?? 0,
      harmfulCount: json['harmful_count'] ?? 0,
      benignCount: json['benign_count'] ?? 0,
      harmfulRefusalRate: (json['harmful_refusal_rate'] as num?)?.toDouble() ?? 0.0,
      unsafeComplianceRate: (json['unsafe_compliance_rate'] as num?)?.toDouble() ?? 0.0,
      benignComplianceRate: (json['benign_compliance_rate'] as num?)?.toDouble() ?? 0.0,
      overRefusalRate: (json['over_refusal_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CrossLingualDelta {
  final double deltaHrr;
  final double deltaUcr;
  final double deltaOrr;
  final double deltaBcr;

  CrossLingualDelta({
    required this.deltaHrr,
    required this.deltaUcr,
    required this.deltaOrr,
    required this.deltaBcr,
  });

  factory CrossLingualDelta.fromJson(Map<String, dynamic> json) {
    return CrossLingualDelta(
      deltaHrr: (json['delta_hrr'] as num?)?.toDouble() ?? 0.0,
      deltaUcr: (json['delta_ucr'] as num?)?.toDouble() ?? 0.0,
      deltaOrr: (json['delta_orr'] as num?)?.toDouble() ?? 0.0,
      deltaBcr: (json['delta_bcr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BehaviorComparisonItem {
  final String behaviorId;
  final String sourceId;
  final String category;
  final String promptType;
  final String enPrompt;
  final String? enResponse;
  final String? enLabel;
  final String nePrompt;
  final String? neResponse;
  final String? neLabel;
  final bool isSafetyDivergent;

  BehaviorComparisonItem({
    required this.behaviorId,
    required this.sourceId,
    required this.category,
    required this.promptType,
    required this.enPrompt,
    this.enResponse,
    this.enLabel,
    required this.nePrompt,
    this.neResponse,
    this.neLabel,
    required this.isSafetyDivergent,
  });

  factory BehaviorComparisonItem.fromJson(Map<String, dynamic> json) {
    return BehaviorComparisonItem(
      behaviorId: json['behavior_id'] ?? '',
      sourceId: json['source_id'] ?? '',
      category: json['category'] ?? '',
      promptType: json['prompt_type'] ?? '',
      enPrompt: json['en_prompt'] ?? '',
      enResponse: json['en_response'],
      enLabel: json['en_label'],
      nePrompt: json['ne_prompt'] ?? '',
      neResponse: json['ne_response'],
      neLabel: json['ne_label'],
      isSafetyDivergent: json['is_safety_divergent'] ?? false,
    );
  }
}

class SystemPerformanceMetrics {
  final double enAvgLatencyMs;
  final double neAvgLatencyMs;
  final double latencyInflationRatio;
  final int enTotalTokens;
  final int neTotalTokens;
  final double tokenInflationRatio;
  final int totalTokensConsumed;

  SystemPerformanceMetrics({
    required this.enAvgLatencyMs,
    required this.neAvgLatencyMs,
    required this.latencyInflationRatio,
    required this.enTotalTokens,
    required this.neTotalTokens,
    required this.tokenInflationRatio,
    required this.totalTokensConsumed,
  });

  factory SystemPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return SystemPerformanceMetrics(
      enAvgLatencyMs: (json['en_avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      neAvgLatencyMs: (json['ne_avg_latency_ms'] as num?)?.toDouble() ?? 0.0,
      latencyInflationRatio: (json['latency_inflation_ratio'] as num?)?.toDouble() ?? 1.0,
      enTotalTokens: json['en_total_tokens'] ?? 0,
      neTotalTokens: json['ne_total_tokens'] ?? 0,
      tokenInflationRatio: (json['token_inflation_ratio'] as num?)?.toDouble() ?? 1.0,
      totalTokensConsumed: json['total_tokens_consumed'] ?? 0,
    );
  }
}

class CategoryDisparityMetric {
  final String category;
  final int totalPrompts;
  final double enUcr;
  final double neUcr;
  final double deltaUcr;
  final double enHrr;
  final double neHrr;
  final double deltaHrr;
  final int divergentCount;
  final String riskLevel;

  CategoryDisparityMetric({
    required this.category,
    required this.totalPrompts,
    required this.enUcr,
    required this.neUcr,
    required this.deltaUcr,
    required this.enHrr,
    required this.neHrr,
    required this.deltaHrr,
    required this.divergentCount,
    required this.riskLevel,
  });

  factory CategoryDisparityMetric.fromJson(Map<String, dynamic> json) {
    return CategoryDisparityMetric(
      category: json['category'] ?? '',
      totalPrompts: json['total_prompts'] ?? 0,
      enUcr: (json['en_ucr'] as num?)?.toDouble() ?? 0.0,
      neUcr: (json['ne_ucr'] as num?)?.toDouble() ?? 0.0,
      deltaUcr: (json['delta_ucr'] as num?)?.toDouble() ?? 0.0,
      enHrr: (json['en_hrr'] as num?)?.toDouble() ?? 0.0,
      neHrr: (json['ne_hrr'] as num?)?.toDouble() ?? 0.0,
      deltaHrr: (json['delta_hrr'] as num?)?.toDouble() ?? 0.0,
      divergentCount: json['divergent_count'] ?? 0,
      riskLevel: json['risk_level'] ?? 'PARITY',
    );
  }
}

class RQ1Metrics {
  final String experimentId;
  final String targetModel;
  final LanguageSafetyMetrics? enMetrics;
  final LanguageSafetyMetrics? neMetrics;
  final CrossLingualDelta? delta;
  final int divergentBehaviorCount;
  final List<BehaviorComparisonItem> comparisons;
  final SystemPerformanceMetrics? performanceMetrics;
  final List<CategoryDisparityMetric> categoryBreakdown;

  RQ1Metrics({
    required this.experimentId,
    required this.targetModel,
    this.enMetrics,
    this.neMetrics,
    this.delta,
    required this.divergentBehaviorCount,
    required this.comparisons,
    this.performanceMetrics,
    this.categoryBreakdown = const [],
  });

  factory RQ1Metrics.fromJson(Map<String, dynamic> json) {
    return RQ1Metrics(
      experimentId: json['experiment_id'] ?? '',
      targetModel: json['target_model'] ?? '',
      enMetrics: json['en_metrics'] != null ? LanguageSafetyMetrics.fromJson(json['en_metrics']) : null,
      neMetrics: json['ne_metrics'] != null ? LanguageSafetyMetrics.fromJson(json['ne_metrics']) : null,
      delta: json['cross_lingual_delta'] != null ? CrossLingualDelta.fromJson(json['cross_lingual_delta']) : null,
      divergentBehaviorCount: json['divergent_behavior_count'] ?? 0,
      comparisons: (json['comparisons'] as List? ?? [])
          .map((c) => BehaviorComparisonItem.fromJson(c))
          .toList(),
      performanceMetrics: json['performance_metrics'] != null
          ? SystemPerformanceMetrics.fromJson(json['performance_metrics'])
          : null,
      categoryBreakdown: (json['category_breakdown'] as List? ?? [])
          .map((c) => CategoryDisparityMetric.fromJson(c))
          .toList(),
    );
  }
}

class RQ2Metrics {
  final String experimentId;
  final int totalAutomatedEvaluations;
  final int criticConfirmedCount;
  final int criticRevisedCount;
  final double criticRevisionRate;
  final int totalHumanAnnotated;
  final int agreementCount;
  final double rawAgreementRate;
  final double? cohensKappa;

  RQ2Metrics({
    required this.experimentId,
    required this.totalAutomatedEvaluations,
    required this.criticConfirmedCount,
    required this.criticRevisedCount,
    required this.criticRevisionRate,
    required this.totalHumanAnnotated,
    required this.agreementCount,
    required this.rawAgreementRate,
    this.cohensKappa,
  });

  factory RQ2Metrics.fromJson(Map<String, dynamic> json) {
    return RQ2Metrics(
      experimentId: json['experiment_id'] ?? '',
      totalAutomatedEvaluations: json['total_automated_evaluations'] ?? 0,
      criticConfirmedCount: json['critic_confirmed_count'] ?? 0,
      criticRevisedCount: json['critic_revised_count'] ?? 0,
      criticRevisionRate: (json['critic_revision_rate'] as num?)?.toDouble() ?? 0.0,
      totalHumanAnnotated: json['total_human_annotated'] ?? 0,
      agreementCount: json['agreement_count'] ?? 0,
      rawAgreementRate: (json['raw_agreement_rate'] as num?)?.toDouble() ?? 0.0,
      cohensKappa: (json['cohens_kappa'] as num?)?.toDouble(),
    );
  }
}

