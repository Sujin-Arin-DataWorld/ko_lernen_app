import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Canonical app-owned text input for Sori surfaces.
///
/// Visual treatment comes from [ThemeData.inputDecorationTheme]. This wrapper
/// centralizes the public input contract without duplicating colors, radii, or
/// type tokens. Validation, persistence, and submit behavior stay in the
/// owning screen through the forwarded callbacks.
class SoriTextField extends StatelessWidget {
  const SoriTextField({
    super.key,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.alignLabelWithHint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
  });

  /// Optional key for callers that need to address the editable field itself.
  final Key? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool? alignLabelWithHint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        alignLabelWithHint: alignLabelWithHint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: style,
      textAlign: textAlign,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      onTap: onTap,
      onTapOutside: onTapOutside,
    );
  }
}
