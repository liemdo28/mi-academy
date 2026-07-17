/// MI Academy — AI Safety Core
///
/// AI safety controls, model registry, validation, and audit logging.
///
/// Per blueprint §27: Mandatory safety controls include:
/// - Input/output schema validation
/// - Prompt versioning
/// - Prohibited topic filter
/// - Child-facing output block
/// - Human review gate
/// - Rate limiting
/// - Timeout
/// - Offline fallback
/// - Audit log
library ai_safety;

export 'src/model_registry.dart';
export 'src/safety_validator.dart';
export 'src/audit_logger.dart';
export 'src/content_lifecycle.dart';
