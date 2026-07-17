/// Error taxonomy for educational error pattern detection.
///
/// Per blueprint §14: Taxonomy of common educational errors.
/// Error patterns help: hint selection, review lesson selection,
/// insight generation, and content analysis.
///
/// NOTE: Error patterns are NOT labels for children.
/// They are used for educational content analytics only.
library error_taxonomy;

/// Math error patterns.
class MathErrorPattern {
  MathErrorPattern._();
  static const offByOne = 'OFF_BY_ONE';
  static const operationConfusion = 'OPERATION_CONFUSION';
  static const placeValueError = 'PLACE_VALUE_ERROR';
  static const carryingError = 'CARRYING_ERROR';
  static const borrowingError = 'BORROWING_ERROR';
  static const signConfusion = 'SIGN_CONFUSION';
  static const reversedDigits = 'REVERSED_DIGITS';
  static const missingZero = 'MISSING_ZERO';
}

/// Language error patterns.
class LanguageErrorPattern {
  LanguageErrorPattern._();
  static const initialSoundConfusion = 'INITIAL_SOUND_CONFUSION';
  static const vowelConfusion = 'VOWEL_CONFUSION';
  static const diacriticConfusion = 'DIACRITIC_CONFUSION';
  static const letterOrderError = 'LETTER_ORDER_ERROR';
  static const rhymeConfusion = 'RHYME_CONFUSION';
  static const graphemeMismatch = 'GRAPHEME_MISMATCH';
  static const homophoneConfusion = 'HOMOPHONE_CONFUSION';
}

/// Logic/Coding error patterns.
class LogicErrorPattern {
  LogicErrorPattern._();
  static const turnDirectionError = 'TURN_DIRECTION_ERROR';
  static const sequenceOrderError = 'SEQUENCE_ORDER_ERROR';
  static const missingLoop = 'MISSING_LOOP';
  static const conditionMisuse = 'CONDITION_MISUSE';
  static const overlongSolution = 'OVERLONG_SOLUTION';
  static const infiniteLoopRisk = 'INFINITE_LOOP_RISK';
  static const offByOneNavigation = 'OFF_BY_ONE_NAVIGATION';
}

/// Detect error pattern from answer evidence.
class ErrorPatternDetector {
  const ErrorPatternDetector();

  /// Detect error patterns from attempted answer and expected answer.
  ///
  /// Returns a list of detected error patterns.
  List<String> detect({
    required String subjectArea,
    required String attemptedAnswer,
    required String expectedAnswer,
    required String operation,
  }) {
    final patterns = <String>[];

    if (subjectArea == 'math') {
      // Try to parse as numbers for math-specific detection
      final attempted = int.tryParse(attemptedAnswer);
      final expected = int.tryParse(expectedAnswer);
      if (attempted != null && expected != null) {
        final diff = (attempted - expected).abs();
        // Off by one
        if (diff == 1) patterns.add(MathErrorPattern.offByOne);
        // Reversed digits
        if (attempted.toString().length == expected.toString().length) {
          final reversed = attempted.toString().split('').reversed.join();
          if (reversed == expected.toString()) {
            patterns.add(MathErrorPattern.reversedDigits);
          }
        }
      }
    }

    if (subjectArea == 'language') {
      // Letter order detection
      if (attemptedAnswer.length == expectedAnswer.length) {
        final chars = attemptedAnswer.toLowerCase().split('');
        final expectedChars = expectedAnswer.toLowerCase().split('');
        if (chars.length == expectedChars.length) {
          var swapped = 0;
          for (var i = 0; i < chars.length; i++) {
            if (chars[i] != expectedChars[i]) swapped++;
          }
          if (swapped == 1) {
            patterns.add(LanguageErrorPattern.letterOrderError);
          }
        }
      }
    }

    return patterns;
  }
}
