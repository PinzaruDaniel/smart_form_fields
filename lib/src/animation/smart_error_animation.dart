/// Animation applied when a smart field receives a validation error.
enum SmartErrorAnimation {
  /// Do not animate validation errors.
  none,

  /// Briefly move the invalid field from side to side.
  shake,

  /// Briefly fade the invalid field in.
  fade,

  /// Briefly slide the invalid field down into place.
  slide,

  /// Briefly scale the invalid field up into place.
  scale,

  /// Briefly enlarges and settles the invalid field.
  pulse,
}
