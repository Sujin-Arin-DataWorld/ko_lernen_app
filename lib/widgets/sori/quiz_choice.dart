import 'package:flutter/material.dart';

import 'tokens.dart';

/// **마이크로인터랙션: 즉시 피드백 선택지**
///
/// 버튼 누르는 순간 즉시 반응 (500ms 이내):
/// 1. scale 0.95 elasticOut (press 감각)
/// 2. 색상 변경 (정답=초록, 오답=빨강)
/// 3. ✓ 또는 ✗ 아이콘 표시
/// 4. 부모에 콜백 전송 (1ms 후 — 시각 피드백 먼저)
class QuizChoice extends StatefulWidget {
  final String text;
  final bool isCorrect;
  final VoidCallback onSelected;
  final bool isSelected;
  final String? subtitle;

  const QuizChoice({
    super.key,
    required this.text,
    required this.isCorrect,
    required this.onSelected,
    this.isSelected = false,
    this.subtitle,
  });

  @override
  State<QuizChoice> createState() => _QuizChoiceState();
}

class _QuizChoiceState extends State<QuizChoice>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isPressed) return;

    // 1. 시각적 반응 (scale down)
    setState(() => _isPressed = true);
    _scaleCtrl.forward();

    // 2. 부모에 즉시 알림 (애니 보다 우선)
    Future.delayed(Duration.zero, widget.onSelected);

    // 3. 색상 변경은 자동 (AnimatedContainer)
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _isPressed
          ? Tween<double>(begin: 1.0, end: 0.95).animate(
              CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
            )
          : AlwaysStoppedAnimation(1.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: !_isPressed
              ? const Color(0xFFFAFAFA)
              : (widget.isCorrect ? const Color(0xFF4CAF50) : Colors.red),
          border: Border.all(
            color: !_isPressed
                ? SoriColors.primary.withOpacity(0.2)
                : (widget.isCorrect ? const Color(0xFF4CAF50) : Colors.red),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isPressed ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _isPressed
                                  ? Colors.white70
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isPressed)
                    Icon(
                      widget.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
