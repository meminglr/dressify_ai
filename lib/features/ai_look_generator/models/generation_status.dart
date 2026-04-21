/// GenerationStatus enum representing the lifecycle states of an AI look generation.
///
/// Used by GenerationQueueItem to track progress through the generation pipeline.
enum GenerationStatus {
  /// Waiting in the queue to be processed
  queued,

  /// Currently being processed by the n8n API
  processing,

  /// Successfully completed with a result image
  completed,

  /// Failed due to a network, API, or timeout error
  failed,
}
