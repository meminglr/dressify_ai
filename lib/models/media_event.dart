import 'media.dart';

/// MediaEventType enum representing different types of media events from Supabase Realtime.
///
/// Validates Requirements 15.3
enum MediaEventType {
  /// Media record inserted
  insert,
  
  /// Media record deleted
  delete;
}

/// MediaEvent model representing media change events from Supabase Realtime.
///
/// This model represents events received from Supabase Realtime subscriptions
/// when media records are inserted or deleted in the database.
/// Validates Requirements 15.3
class MediaEvent {
  /// Type of the media event (insert or delete)
  final MediaEventType type;
  
  /// Media object associated with the event
  /// For insert events: contains the new media data
  /// For delete events: may contain the deleted media data or be null
  final Media? media;
  
  MediaEvent({
    required this.type,
    this.media,
  });
  
  /// Creates a MediaEvent instance from Supabase Realtime event data
  ///
  /// Expects eventType to be 'INSERT' or 'DELETE'
  /// For INSERT events, record should contain the new media data
  /// For DELETE events, record may be null or contain the old media data
  factory MediaEvent.fromRealtimeEvent({
    required String eventType,
    Map<String, dynamic>? record,
  }) {
    final type = _parseEventType(eventType);
    final media = record != null ? Media.fromJson(record) : null;
    
    return MediaEvent(
      type: type,
      media: media,
    );
  }
  
  /// Parses Supabase Realtime event type string to MediaEventType
  static MediaEventType _parseEventType(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'INSERT':
        return MediaEventType.insert;
      case 'DELETE':
        return MediaEventType.delete;
      default:
        throw ArgumentError('Unsupported event type: $eventType');
    }
  }
}