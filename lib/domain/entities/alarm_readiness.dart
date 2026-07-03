import 'package:equatable/equatable.dart';

class AlarmReadinessIssue extends Equatable {
  const AlarmReadinessIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.canFixInApp = false,
  });

  final String id;
  final String title;
  final String description;
  final ReadinessSeverity severity;
  final bool canFixInApp;

  @override
  List<Object?> get props => [id, title, severity];
}

enum ReadinessSeverity { critical, warning, info }

class AlarmReadinessReport extends Equatable {
  const AlarmReadinessReport({required this.issues});

  final List<AlarmReadinessIssue> issues;

  bool get isReady =>
      !issues.any((i) => i.severity == ReadinessSeverity.critical);

  @override
  List<Object?> get props => [issues];
}
