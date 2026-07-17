import 'package:equatable/equatable.dart';

/// Metadata attached to every audio asset.
///
/// Per blueprint §8 (Sound Match audio requirement), each audio needs:
/// language, locale, speaker, speed, transcript, normalized volume,
/// recording date, review status.
class AudioMetadata extends Equatable {
  const AudioMetadata({
    required this.assetKey,
    required this.language,
    required this.locale,
    required this.transcript,
    this.speaker,
    this.speed = 1.0,
    this.normalizedVolume = 1.0,
    this.recordingDate,
    this.reviewStatus = AudioReviewStatus.pending,
  });

  final String assetKey;
  final String language;
  final String locale;
  final String transcript;
  final String? speaker;
  final double speed;
  final double normalizedVolume;
  final DateTime? recordingDate;
  final AudioReviewStatus reviewStatus;

  /// Whether this audio is approved for production use.
  bool get isApproved => reviewStatus == AudioReviewStatus.approved;

  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      assetKey: json['assetKey'] as String,
      language: json['language'] as String,
      locale: json['locale'] as String,
      transcript: json['transcript'] as String,
      speaker: json['speaker'] as String?,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      normalizedVolume: (json['normalizedVolume'] as num?)?.toDouble() ?? 1.0,
      recordingDate: json['recordingDate'] != null
          ? DateTime.parse(json['recordingDate'] as String)
          : null,
      reviewStatus: AudioReviewStatus.values.firstWhere(
        (s) => s.name == json['reviewStatus'],
        orElse: () => AudioReviewStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'assetKey': assetKey,
        'language': language,
        'locale': locale,
        'transcript': transcript,
        'speaker': speaker,
        'speed': speed,
        'normalizedVolume': normalizedVolume,
        'recordingDate': recordingDate?.toIso8601String(),
        'reviewStatus': reviewStatus.name,
      };

  @override
  List<Object?> get props => [
        assetKey,
        language,
        locale,
        transcript,
        speaker,
        speed,
        normalizedVolume,
        recordingDate,
        reviewStatus,
      ];
}

enum AudioReviewStatus { pending, reviewed, approved, rejected }
