import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// CP2026 S6: explicit icon controls need an actionable label and tooltip.
///
/// This syntax guard covers Material IconButton constructors and inline,
/// icon-only SoriPressable/GestureDetector/InkWell/Semantics controls. It does
/// not infer the rendered contents of arbitrary custom widget factories or
/// prove that a dynamic label is nonblank. Widget and device checks cover those
/// boundaries. Unknown custom content is never guessed to be an icon-only UI.
void main() {
  test('recognizes all Material constructors without parsing nearby text', () {
    final result = _audit('''
      Widget build() => Column(children: [
        IconButton(onPressed: run, icon: Icon(Icons.add)),
        const IconButton.filled(onPressed: null, icon: Icon(Icons.add)),
        m.IconButton.filledTonal(onPressed: run, icon: Icon(Icons.add)),
        new IconButton.outlined(onPressed: run, icon: Icon(Icons.add)),
        IconButton(tooltip: '   ', onPressed: run, icon: Icon(Icons.add)),
        IconButton(tooltip: null, onPressed: run, icon: Icon(Icons.add)),
        IconButton(tooltip: ok ? 'Add' : '', onPressed: run,
          icon: Icon(Icons.add)),
      ]);
      final style = IconButton.styleFrom(padding: EdgeInsets.zero);
      final sample = "IconButton(onPressed: run, icon: Icon(Icons.add))";
      // IconButton(onPressed: run, icon: Icon(Icons.add))
    ''');
    expect(result.materialCount, 7);
    expect(
      result.issues.where((i) => i.endsWith('missing tooltip')),
      hasLength(7),
    );
    expect(
      result.issues.where((i) => i.endsWith('missing label')),
      hasLength(7),
    );
  });

  test('accepts a button tooltip or a direct wrapping tooltip', () {
    expect(
      _audit('''
        Widget build() => Column(children: [
          IconButton(tooltip: t.close, onPressed: close, icon: Icon(Icons.close)),
          Tooltip(message: t.close, child: Padding(padding: EdgeInsets.zero,
            child: IconButton(onPressed: close, icon: Icon(Icons.close)))),
          Tooltip(message: t.close, excludeFromSemantics: true,
            child: Semantics(button: true, label: t.close, onTap: close,
              child: ExcludeSemantics(child: SoriPressable(onTap: close,
                child: SizedBox.square(dimension: 48,
                  child: Icon(Icons.close)))))),
        ]);
      ''').issues,
      isEmpty,
    );
  });

  test('a sibling, callback, or whole-row tooltip cannot label a button', () {
    expect(
      _audit('''
        Widget build() => Column(children: [
          Tooltip(message: 'Other', child: Text('Other')),
          IconButton(onPressed: () => Tooltip(message: 'Later', child: Text('x')),
            icon: Icon(Icons.add)),
          Tooltip(message: 'Toolbar', child: Row(children: [
            IconButton(onPressed: run, icon: Icon(Icons.add)),
          ])),
        ]);
      ''').issues,
      hasLength(4),
    );
  });

  test(
    'excluded tooltip semantics need an independent Material button label',
    () {
      expect(
        _audit('''
        Widget build() => Column(children: [
          Tooltip(message: 'Close', excludeFromSemantics: true,
            child: IconButton(onPressed: close, icon: Icon(Icons.close))),
          Tooltip(message: 'Close', excludeFromSemantics: true,
            child: Semantics(label: 'Close', child: IconButton(
              onPressed: close, icon: Icon(Icons.close)))),
          Tooltip(message: 'Close', excludeFromSemantics: true,
            child: IconButton(onPressed: close,
              icon: Icon(Icons.close, semanticLabel: 'Close'))),
        ]);
      ''').issues.single,
        endsWith('missing label'),
      );
    },
  );

  test('custom icon controls need both tooltip and a readable label', () {
    final result = _audit('''
      Widget build() => Column(children: [
        Semantics(button: true, label: 'Play', child: SoriPressable(
          onTap: play, child: ConstrainedBox(constraints: BoxConstraints(),
            child: SizedBox.square(dimension: 48,
              child: Icon(Icons.volume_up))))),
        Tooltip(message: 'Play', excludeFromSemantics: true,
          child: GestureDetector(onTap: play, child: Icon(Icons.volume_up))),
        Semantics(button: true, onTap: play, child: Icon(Icons.volume_up)),
      ]);
    ''');
    expect(
      result.issues.where((i) => i.endsWith('missing tooltip')),
      hasLength(2),
    );
    expect(
      result.issues.where((i) => i.endsWith('missing label')),
      hasLength(2),
    );
  });

  test(
    'excluded buttons need an actionable semantics owner outside the boundary',
    () {
      final result = _audit('''
      Widget build() => Column(children: [
        ExcludeSemantics(child: IconButton(tooltip: 'Play', onPressed: run,
          icon: Icon(Icons.play_arrow))),
        Tooltip(message: 'Play', child: ExcludeSemantics(
          child: IconButton(tooltip: 'Play', onPressed: run,
            icon: Icon(Icons.play_arrow)))),
        Semantics(label: 'Play', child: ExcludeSemantics(
          child: IconButton(tooltip: 'Play', onPressed: run,
            icon: Icon(Icons.play_arrow)))),
        Semantics(excludeSemantics: true, child: IconButton(tooltip: 'Play',
          onPressed: run, icon: Icon(Icons.play_arrow))),
        Semantics(label: 'Play', button: true, onTap: run,
          child: ExcludeSemantics(child: IconButton(tooltip: 'Play',
            onPressed: run, icon: Icon(Icons.play_arrow)))),
        ExcludeSemantics(excluding: false, child: IconButton(tooltip: 'Play',
          onPressed: run, icon: Icon(Icons.play_arrow))),
        Semantics(excludeSemantics: true, label: 'Play', button: true, onTap: run,
          child: IconButton(tooltip: 'Play', onPressed: run,
            icon: Icon(Icons.play_arrow))),
        Semantics(label: 'Play', button: true, enabled: false,
          child: ExcludeSemantics(child: IconButton(tooltip: 'Play',
            onPressed: null, icon: Icon(Icons.play_arrow)))),
        Semantics(excludeSemantics: true, label: 'Play', button: true,
          enabled: !loading, onTap: loading ? null : run,
          child: IconButton(tooltip: 'Play', onPressed: loading ? null : run,
            icon: Icon(Icons.play_arrow))),
        Semantics(excludeSemantics: true, label: 'Play', button: true,
          onTap: loading ? null : null, child: IconButton(tooltip: 'Play',
            onPressed: run, icon: Icon(Icons.play_arrow))),
        ExcludeSemantics(child: Row(children: [
          IconButton(tooltip: 'Play', onPressed: run, icon: Icon(Icons.play_arrow)),
        ])),
        ExcludeSemantics(child: Column(children: [
          Semantics(label: 'Play', button: true, onTap: run,
            child: IconButton(tooltip: 'Play', onPressed: run,
              icon: Icon(Icons.play_arrow))),
        ])),
        Tooltip(message: 'Play', child: ExcludeSemantics(child: Stack(children: [
          IconButton(tooltip: 'Play', onPressed: run, icon: Icon(Icons.play_arrow)),
        ]))),
      ]);
    ''');
      expect(result.materialCount, 13);
      expect(result.issues, hasLength(8));
      expect(
        result.issues,
        everyElement(endsWith('missing semantics outside exclusion')),
      );
    },
  );

  test(
    'text controls and unknown custom labels are not guessed to be icons',
    () {
      expect(
        _audit('''
        Widget build() => Column(children: [
          InkWell(onTap: run, child: Row(children: [Icon(Icons.add), Text('Add')])),
          SoriPressable(onTap: run, child: Stack(children: [
            CustomTextLabel(label: 'Add'), Icon(Icons.add),
          ])),
          SoriPressable(onTap: run, child: Image.asset('gift.png',
            errorBuilder: (_, __, ___) => Icon(Icons.image))),
        ]);
      ''').issues,
        isEmpty,
      );
    },
  );

  test('lib icon controls have tooltips and custom controls have labels', () {
    final issues = <String>[];
    var materialCount = 0;
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      if (!RegExp(
        r'IconButton|SoriPressable|GestureDetector|InkWell|Semantics',
      ).hasMatch(source)) {
        continue;
      }
      final path = file.path.replaceAll('\\', '/');
      final result = _audit(source, path: path);
      materialCount += result.materialCount;
      issues.addAll(result.issues);
    }
    expect(
      materialCount,
      greaterThan(0),
      reason: 'The scanner must find controls.',
    );
    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}

const _gestures = {'SoriPressable', 'GestureDetector', 'InkWell'};
const _singleChild = {
  'Align',
  'AnimatedContainer',
  'Center',
  'ClipOval',
  'ClipRRect',
  'Container',
  'ConstrainedBox',
  'DecoratedBox',
  'ExcludeSemantics',
  'Expanded',
  'FittedBox',
  'Flexible',
  'Ink',
  'Material',
  'Opacity',
  'Padding',
  'RepaintBoundary',
  'Semantics',
  'SizedBox',
  'SizedBox.square',
  'Tooltip',
  'Transform',
  'Transform.scale',
};

class _Call {
  _Call(this.node, this.name, this.arguments);
  final AstNode node;
  final String name;
  final ArgumentList arguments;

  Expression? arg(String key) {
    for (final arg in arguments.arguments.whereType<NamedExpression>()) {
      if (arg.name.label.name == key) {
        return arg.expression;
      }
    }
    return null;
  }
}

class _Calls extends RecursiveAstVisitor<void> {
  final calls = <AstNode, _Call>{};

  void _add(AstNode node, String name, ArgumentList arguments) {
    // A material import prefix is not part of its widget's constructor name.
    final parts = name.split('.');
    if (parts.length > 1 && RegExp(r'^[a-z]').hasMatch(parts.first)) {
      parts.removeAt(0);
    }
    calls[node] = _Call(node, parts.join('.'), arguments);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _add(
      node,
      [
        if (node.target != null) node.target!.toSource(),
        node.methodName.name,
      ].join('.'),
      node.argumentList,
    );
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _add(node, node.constructorName.toSource(), node.argumentList);
    super.visitInstanceCreationExpression(node);
  }
}

class _Audit {
  final issues = <String>[];
  var materialCount = 0;
}

bool _hasCallback(Expression? expression) {
  if (expression == null || expression is NullLiteral) {
    return false;
  }
  if (expression is ConditionalExpression) {
    return _hasCallback(expression.thenExpression) ||
        _hasCallback(expression.elseExpression);
  }
  return true;
}

bool _hasText(Expression? expression) {
  if (expression == null || expression is NullLiteral) {
    return false;
  }
  if (expression is StringLiteral) {
    return expression.stringValue?.trim().isNotEmpty ?? true;
  }
  if (expression is ConditionalExpression) {
    return _hasText(expression.thenExpression) &&
        _hasText(expression.elseExpression);
  }
  return true;
}

/// null = unknown/text content, 0 = spacer, >0 = explicit icon leaves.
int? _iconLeaves(Expression? expression, Map<AstNode, _Call> calls) {
  if (expression is ParenthesizedExpression) {
    return _iconLeaves(expression.expression, calls);
  }
  final call = calls[expression];
  if (call == null) {
    return null;
  }
  if (call.name == 'Icon') {
    return 1;
  }
  if (call.name == 'SizedBox' && call.arg('child') == null) {
    return 0;
  }
  if (_singleChild.contains(call.name)) {
    return _iconLeaves(call.arg('child'), calls);
  }
  if ({'Row', 'Column', 'Stack', 'Wrap'}.contains(call.name)) {
    final children = call.arg('children');
    if (children is! ListLiteral) {
      return null;
    }
    var count = 0;
    for (final child in children.elements) {
      final icons = child is Expression ? _iconLeaves(child, calls) : null;
      if (icons == null) {
        return null;
      }
      count += icons;
    }
    return count;
  }
  return null;
}

List<_Call> _ancestors(_Call call, Map<AstNode, _Call> calls) {
  final ancestors = <_Call>[];
  for (AstNode? node = call.node.parent; node != null; node = node.parent) {
    if (node is FunctionExpression || node is MethodDeclaration) {
      break;
    }
    final parent = calls[node];
    if (parent == null) {
      continue;
    }
    ancestors.add(parent);
  }
  return ancestors;
}

_Audit _audit(String source, {String path = 'fixture.dart'}) {
  final parsed = parseString(content: source, throwIfDiagnostics: false);
  final result = _Audit();
  if (parsed.errors.isNotEmpty) {
    result.issues.add('$path: parse error: ${parsed.errors.first.message}');
    return result;
  }
  final visitor = _Calls();
  parsed.unit.accept(visitor);
  for (final call in visitor.calls.values) {
    final material = RegExp(
      r'^IconButton(?:\.(?:filled|filledTonal|outlined))?$',
    ).hasMatch(call.name);
    final gesture =
        _gestures.contains(call.name) &&
        [
          'onTap',
          'onLongPress',
          'onTapUp',
          'onTapDown',
        ].any((key) => _hasCallback(call.arg(key)));
    final semantics =
        call.name == 'Semantics' && call.arg('button')?.toSource() == 'true';
    if (material) {
      result.materialCount++;
    } else if ((!gesture && !semantics) ||
        (_iconLeaves(call.arg('child'), visitor.calls) ?? 0) == 0) {
      continue;
    }
    final ancestors = _ancestors(call, visitor.calls);
    // A row-wide label or tooltip cannot label each individual action.
    final wrappers = ancestors
        .takeWhile((parent) => _singleChild.contains(parent.name))
        .toList();
    final tooltip =
        _hasText(call.arg('tooltip')) ||
        wrappers.any((w) => w.name == 'Tooltip' && _hasText(w.arg('message')));
    final location =
        '$path:${parsed.lineInfo.getLocation(call.node.offset).lineNumber} ${call.name}';
    if (!tooltip) {
      result.issues.add('$location missing tooltip');
    }
    // An inner label/tooltip disappears at an explicit exclusion boundary.
    // Only an outer owner can restore the button and its accessible action.
    // Exclusion affects all descendants, including across multi-child widgets.
    final exclusion = ancestors.lastIndexWhere(
      (w) =>
          (w.name == 'ExcludeSemantics' &&
              w.arg('excluding')?.toSource() != 'false') ||
          (w.name == 'Semantics' &&
              w.arg('excludeSemantics')?.toSource() == 'true'),
    );
    if (exclusion >= 0) {
      final ownerStart = wrappers.indexOf(ancestors[exclusion]);
      final restored =
          ownerStart >= 0 &&
          wrappers
              .skip(ownerStart)
              .any(
                (w) =>
                    w.name == 'Semantics' &&
                    _hasText(w.arg('label')) &&
                    w.arg('button')?.toSource() == 'true' &&
                    (_hasCallback(w.arg('onTap')) ||
                        w.arg('enabled')?.toSource() == 'false'),
              );
      if (!restored) {
        result.issues.add('$location missing semantics outside exclusion');
      }
      continue;
    }
    if (!material || !_hasText(call.arg('tooltip'))) {
      final label =
          _hasText(call.arg('label')) ||
          _hasText(visitor.calls[call.arg('icon')]?.arg('semanticLabel')) ||
          wrappers.any(
            (w) =>
                (w.name == 'Semantics' && _hasText(w.arg('label'))) ||
                (w.name == 'Tooltip' &&
                    _hasText(w.arg('message')) &&
                    w.arg('excludeFromSemantics')?.toSource() != 'true'),
          );
      if (!label) {
        result.issues.add('$location missing label');
      }
    }
  }
  return result;
}
