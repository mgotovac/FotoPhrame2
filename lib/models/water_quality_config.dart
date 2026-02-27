class WaterQualityConfig {
  final String url;
  final List<WaterQualityField> selectedFields;

  const WaterQualityConfig({
    required this.url,
    required this.selectedFields,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'selectedFields': selectedFields.map((f) => f.toJson()).toList(),
      };

  factory WaterQualityConfig.fromJson(Map<String, dynamic> json) =>
      WaterQualityConfig(
        url: json['url'] as String,
        selectedFields: (json['selectedFields'] as List)
            .map((f) => WaterQualityField.fromJson(f as Map<String, dynamic>))
            .toList(),
      );
}

class WaterQualityField {
  final String jsonPath; // dot-notation path, e.g. "data.turbidity"
  final String label;
  final String? unit;

  const WaterQualityField({
    required this.jsonPath,
    required this.label,
    this.unit,
  });

  Map<String, dynamic> toJson() => {
        'jsonPath': jsonPath,
        'label': label,
        'unit': unit,
      };

  factory WaterQualityField.fromJson(Map<String, dynamic> json) =>
      WaterQualityField(
        jsonPath: json['jsonPath'] as String,
        label: json['label'] as String,
        unit: json['unit'] as String?,
      );
}
