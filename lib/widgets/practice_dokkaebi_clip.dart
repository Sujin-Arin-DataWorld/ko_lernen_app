/// Two distinct user-supplied gestures; doccabi6 and 도깨비 are identical files.
/// Their complete motion and matching posters share the puzzle-contact canvas.
enum PracticeDokkaebiClip {
  strike('dokkaebi_hint', Duration(milliseconds: 1300)),
  swing('dokkaebi_hint_swing', Duration(milliseconds: 667));

  const PracticeDokkaebiClip(this._stem, this.impactAt);
  final String _stem;
  final Duration impactAt;
  String get videoAsset => 'assets/video/practice/${_stem}_hanji.mp4';
  String get startAsset => 'assets/video/practice/${_stem}_start.png';
  String get endAsset => 'assets/video/practice/${_stem}_end.png';

  static PracticeDokkaebiClip forRequest(int requestId) =>
      requestId <= 0 ? strike : values[(requestId - 1) % values.length];
}
