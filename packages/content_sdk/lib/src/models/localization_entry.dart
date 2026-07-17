import 'package:json_annotation/json_annotation.dart';

part 'localization_entry.g.dart';

/// A localized string entry.
/// Contract: mi.content.localization / v1
@JsonSerializable(explicitToJson: true)
class LocalizationEntry {
  final String key;
  final String language;
  final String value;
  final String context;
  final String? pluralForm;
  final Map<String, String>? variants;

  const LocalizationEntry({
    required this.key,
    required this.language,
    required this.value,
    this.context = 'default',
    this.pluralForm,
    this.variants,
  });

  factory LocalizationEntry.fromJson(Map<String, dynamic> json) =>
      _$LocalizationEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizationEntryToJson(this);

  static const List<String> supportedLanguages = ['en', 'vi'];

  List<String> validate() {
    final errors = <String>[];
    if (key.isEmpty) errors.add('key is required');
    if (value.isEmpty) errors.add('value is required');
    if (!supportedLanguages.contains(language)) {
      errors.add('language must be one of: ${supportedLanguages.join(', ')}');
    }
    return errors;
  }

  LocalizationEntry copyWith({
    String? key, String? language, String? value,
    String? context, String? pluralForm, Map<String, String>? variants,
  }) {
    return LocalizationEntry(
      key: key ?? this.key, language: language ?? this.language,
      value: value ?? this.value, context: context ?? this.context,
      pluralForm: pluralForm ?? this.pluralForm,
      variants: variants ?? this.variants,
    );
  }
}
