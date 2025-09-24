import 'package:json_annotation/json_annotation.dart';

part 'onboarding_step.g.dart';

@JsonSerializable()
class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final String? buttonText;
  final bool isLastStep;
  final Map<String, dynamic>? metadata;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.buttonText,
    required this.isLastStep,
    this.metadata,
  });

  factory OnboardingStep.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStepFromJson(json);
  Map<String, dynamic> toJson() => _$OnboardingStepToJson(this);

  OnboardingStep copyWith({
    String? id,
    String? title,
    String? description,
    String? imagePath,
    String? buttonText,
    bool? isLastStep,
    Map<String, dynamic>? metadata,
  }) {
    return OnboardingStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      buttonText: buttonText ?? this.buttonText,
      isLastStep: isLastStep ?? this.isLastStep,
      metadata: metadata ?? this.metadata,
    );
  }
}
