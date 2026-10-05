import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/formatted_markdown_view.dart';

void main() {
  group('FormattedMarkdownView Unit Tests', () {
    test('cleanMarkdown strips markdown tokens', () {
      const input = '***Bold Italic*** and **Bold** and *Italic* and `Code` and [] and [Link](https://test.com)';
      final cleaned = FormattedMarkdownView.cleanMarkdown(input);
      expect(cleaned, contains('Bold Italic'));
      expect(cleaned, contains('Bold'));
      expect(cleaned, contains('Italic'));
      expect(cleaned, contains('Code'));
      expect(cleaned, contains('(None)'));
      expect(cleaned, contains('Link'));
      expect(cleaned.contains('***'), isFalse);
      expect(cleaned.contains('**'), isFalse);
      expect(cleaned.contains('[]'), isFalse);
    });

    test('parseInlineSpans produces correct bold, italic, code, and empty placeholder spans', () {
      const input = '**Verdict**: Safe Refusal. The response ***cannot be provided***. Code: `rm -rf /` and results: []';
      final spans = FormattedMarkdownView.parseInlineSpans(input);

      expect(spans.isNotEmpty, isTrue);

      // Check bold span
      final boldSpan = spans.firstWhere(
        (s) => s is TextSpan && s.text == 'Verdict',
        orElse: () => const TextSpan(),
      ) as TextSpan;
      expect(boldSpan.style?.fontWeight, equals(FontWeight.bold));

      // Check bold-italic span
      final boldItalicSpan = spans.firstWhere(
        (s) => s is TextSpan && s.text == 'cannot be provided',
        orElse: () => const TextSpan(),
      ) as TextSpan;
      expect(boldItalicSpan.style?.fontWeight, equals(FontWeight.bold));
      expect(boldItalicSpan.style?.fontStyle, equals(FontStyle.italic));

      // Check empty bracket converted to (None)
      final emptySpan = spans.firstWhere(
        (s) => s is TextSpan && s.text == '(None)',
        orElse: () => const TextSpan(),
      ) as TextSpan;
      expect(emptySpan.text, equals('(None)'));
      expect(emptySpan.style?.fontStyle, equals(FontStyle.italic));
    });

    testWidgets('FormattedInlineText renders formatted text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormattedInlineText(
              text: '**Unsafe Compliance**: Model answered ***in full***.',
            ),
          ),
        ),
      );

      expect(find.byType(FormattedInlineText), findsOneWidget);
    });

    testWidgets('FormattedMarkdownView renders headers, lists, code blocks and tables', (WidgetTester tester) async {
      const doc = '''
# Safety Parity Report
## Section 1: Findings
- **High Risk**: Found vulnerabilities.
- [ ] Checklist item 1
- [x] Checklist item 2
1. First priority
2. Second priority

> This is a scientific evaluation.

```python
print("safe")
```

| Threat | EN | NE |
| :--- | :--- | :--- |
| Cyber | 100% | 60% |
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormattedMarkdownView(
              data: doc,
              shrinkWrap: true,
            ),
          ),
        ),
      );

      expect(find.byType(FormattedMarkdownView), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(Divider), findsNothing); // No divider in this doc
    });
  });
}
