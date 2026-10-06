import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A lightweight, zero-dependency Markdown & RichText renderer for Parallax-Eval.
/// Automatically formats:
/// - Bold-italic (***text*** or ___text___)
/// - Bold (**text** or __text__)
/// - Italic (*text* or _text_)
/// - Inline code (`code`)
/// - Fenced code blocks (```lang ... ```)
/// - Empty bracket placeholders ([] or [ ]) -> (None)
/// - Checklists (- [ ] or - [x])
/// - Markdown links ([text](url))
/// - Headings (# H1, ## H2, ### H3, #### H4)
/// - Bullet and numbered lists (- item, * item, 1. item)
/// - Horizontal dividers (---, ***)
/// - Blockquotes (> quote)
/// - Markdown tables (| col1 | col2 |)
class FormattedMarkdownView extends StatelessWidget {
  final String data;
  final TextStyle? textStyle;
  final bool selectable;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const FormattedMarkdownView({
    Key? key,
    required this.data,
    this.textStyle,
    this.selectable = true,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  static final RegExp _inlineTokenPattern = RegExp(
    r'(`[^`]+`)'
    r'|(\*\*\*[^*]+\*\*\*)'
    r'|(____[^_]+____)'
    r'|(\*\*[^*]+\*\*)'
    r'|(__[^_]+__)'
    r'|(\*[^* \n][^*]*\*)'
    r'|(\b_[^_ \n][^_]*_\b)'
    r'|(\[[^\]]+\]\([^)]+\))'
    r'|(\[\s*\])'
    r'|(\[[xX]\])'
    r'|(\[\d+\])',
  );

  /// Parses an inline string containing markdown syntax into styled [InlineSpan]s.
  static List<InlineSpan> parseInlineSpans(
    String text, {
    TextStyle? baseStyle,
    Color? linkColor,
    Color? codeBgColor,
  }) {
    final style = baseStyle ?? const TextStyle(fontSize: 13, height: 1.4);
    final link = linkColor ?? Colors.indigo.shade700;
    final codeBg = codeBgColor ?? Colors.grey.shade200;

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _inlineTokenPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }

      final token = match.group(0)!;

      if (token.startsWith('`') && token.endsWith('`') && token.length >= 2) {
        // Inline code
        final codeText = token.substring(1, token.length - 1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: codeBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400, width: 0.8),
            ),
            child: Text(
              codeText,
              style: style.copyWith(
                fontFamily: 'monospace',
                fontSize: (style.fontSize ?? 13) * 0.88,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      } else if (token.startsWith('***') && token.endsWith('***') && token.length >= 6) {
        // Bold-italic
        final content = token.substring(3, token.length - 3);
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('___') && token.endsWith('___') && token.length >= 6) {
        // Bold-italic
        final content = token.substring(3, token.length - 3);
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('**') && token.endsWith('**') && token.length >= 4) {
        // Bold
        final content = token.substring(2, token.length - 2);
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (token.startsWith('__') && token.endsWith('__') && token.length >= 4) {
        // Bold
        final content = token.substring(2, token.length - 2);
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (token.startsWith('*') && token.endsWith('*') && token.length >= 2) {
        // Italic
        final content = token.substring(1, token.length - 1);
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('_') && token.endsWith('_') && token.length >= 2) {
        // Italic
        final content = token.substring(1, token.length - 1);
        spans.add(TextSpan(
          text: content,
          style: style.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (RegExp(r'^\[\s*\]$').hasMatch(token)) {
        // Empty bracket placeholder: [] or [ ] -> render friendly (None)
        spans.add(TextSpan(
          text: '(None)',
          style: style.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (RegExp(r'^\[[xX]\]$').hasMatch(token)) {
        // Checked box: [x]
        spans.add(TextSpan(
          text: '[x] ',
          style: style.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF245E43)),
        ));
      } else if (token.startsWith('[') && token.contains('](') && token.endsWith(')')) {
        // Link: [label](url)
        final closeBracket = token.indexOf('](');
        final linkText = token.substring(1, closeBracket);
        spans.add(TextSpan(
          text: linkText,
          style: style.copyWith(
            color: link,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (RegExp(r'^\[\d+\]$').hasMatch(token)) {
        // Citation: [1], [2]
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.indigo.shade200, width: 0.8),
            ),
            child: Text(
              token,
              style: TextStyle(
                fontSize: (style.fontSize ?? 13) * 0.82,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: token, style: style));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return spans;
  }

  /// Cleans markdown syntax tokens from a raw string for places where pure text is needed.
  static String cleanMarkdown(String raw) {
    var s = raw;
    s = s.replaceAll(RegExp(r'\[\s*\]'), '(None)');
    s = s.replaceAllMapped(RegExp(r'\*\*\*([^*]+)\*\*\*'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'___([^_]+)___'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);
    s = s.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1)!);
    return s.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppThemeColors.isDark(context);
    final effectiveStyle = textStyle ??
        TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.45,
        );
    final blocks = _parseBlocks(data);

    final widgets = <Widget>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      widgets.add(_buildBlockWidget(context, block, effectiveStyle));
      if (i < blocks.length - 1 && block.type != _BlockType.divider) {
        widgets.add(SizedBox(height: block.bottomSpacing));
      }
    }

    if (shrinkWrap) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      );
    }

    return ListView(
      physics: physics,
      padding: padding,
      children: widgets,
    );
  }

  Widget _buildBlockWidget(BuildContext context, _Block block, TextStyle baseStyle) {
    final isDark = AppThemeColors.isDark(context);
    final brandColor = isDark ? const Color(0xFF90CDF4) : const Color(0xFF1E3A8A);
    final headingDark = isDark ? Colors.white : Colors.black87;

    switch (block.type) {
      case _BlockType.h1:
        return _renderHeading(block.text, 20, FontWeight.bold, brandColor);
      case _BlockType.h2:
        return _renderHeading(block.text, 16.5, FontWeight.bold, brandColor);
      case _BlockType.h3:
        return _renderHeading(block.text, 14.5, FontWeight.bold, headingDark);
      case _BlockType.h4:
        return _renderHeading(block.text, 13.5, FontWeight.w600, headingDark);
      case _BlockType.divider:
        return Divider(height: 24, thickness: 1, color: isDark ? const Color(0xFF2E3B4E) : const Color(0xFFE2E4E8));
      case _BlockType.codeBlock:
        return _renderCodeBlock(context, block.text);
      case _BlockType.blockquote:
        return _renderBlockquote(context, block.text, baseStyle);
      case _BlockType.table:
        return _renderTable(context, block.rows, baseStyle);
      case _BlockType.bulletItem:
        return _renderBulletItem(block.text, baseStyle);
      case _BlockType.numberedItem:
        return _renderNumberedItem(block.prefix, block.text, baseStyle);
      case _BlockType.checkboxItem:
        return _renderCheckboxItem(block.isChecked, block.text, baseStyle);
      case _BlockType.paragraph:
      default:
        return _renderParagraph(block.text, baseStyle);
    }
  }

  Widget _renderHeading(String text, double fontSize, FontWeight weight, Color color) {
    final spans = parseInlineSpans(
      text,
      baseStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: 1.3,
      ),
    );

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
    );
  }

  Widget _renderParagraph(String text, TextStyle baseStyle) {
    final spans = parseInlineSpans(text, baseStyle: baseStyle);
    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
    );
  }

  Widget _renderBulletItem(String text, TextStyle baseStyle) {
    final spans = parseInlineSpans(text, baseStyle: baseStyle);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 8),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: baseStyle.color ?? Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText.rich(TextSpan(children: spans))
                : Text.rich(TextSpan(children: spans)),
          ),
        ],
      ),
    );
  }

  Widget _renderNumberedItem(String prefix, String text, TextStyle baseStyle) {
    final spans = parseInlineSpans(text, baseStyle: baseStyle);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              prefix,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText.rich(TextSpan(children: spans))
                : Text.rich(TextSpan(children: spans)),
          ),
        ],
      ),
    );
  }

  Widget _renderCheckboxItem(bool isChecked, String text, TextStyle baseStyle) {
    final spans = parseInlineSpans(text, baseStyle: baseStyle);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 16,
            color: isChecked ? Colors.green.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: selectable
                ? SelectableText.rich(TextSpan(children: spans))
                : Text.rich(TextSpan(children: spans)),
          ),
        ],
      ),
    );
  }

  Widget _renderBlockquote(BuildContext context, String text, TextStyle baseStyle) {
    final isDark = AppThemeColors.isDark(context);
    final spans = parseInlineSpans(
      text,
      baseStyle: baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: isDark ? const Color(0xFFCBD5E1) : Colors.blueGrey.shade800,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2836) : Colors.indigo.shade50.withAlpha(25),
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
            width: 3.5,
          ),
        ),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
      ),
      child: selectable
          ? SelectableText.rich(TextSpan(children: spans))
          : Text.rich(TextSpan(children: spans)),
    );
  }

  Widget _renderCodeBlock(BuildContext context, String code) {
    final isDark = AppThemeColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF2E3B4E) : Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: selectable
            ? SelectableText(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.4,
                  color: isDark ? const Color(0xFFE2E8F0) : Colors.black87,
                ),
              )
            : Text(
                code,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.4,
                  color: isDark ? const Color(0xFFE2E8F0) : Colors.black87,
                ),
              ),
      ),
    );
  }

  Widget _renderTable(BuildContext context, List<List<String>> rows, TextStyle baseStyle) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final isDark = AppThemeColors.isDark(context);
    final headerRow = rows.first;
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E2632) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: isDark ? const Color(0xFF2E3B4E) : const Color(0xFFE2E4E8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(color: isDark ? const Color(0xFF2E3B4E) : Colors.grey.shade200, width: 0.8),
            verticalInside: BorderSide(color: isDark ? const Color(0xFF2E3B4E) : Colors.grey.shade200, width: 0.8),
          ),
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(color: isDark ? const Color(0xFF243040) : Colors.indigo.shade50.withAlpha(50)),
              children: headerRow.map((cell) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text.rich(
                    TextSpan(
                      children: parseInlineSpans(
                        cell,
                        baseStyle: baseStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: (baseStyle.fontSize ?? 13) * 0.95,
                          color: isDark ? const Color(0xFF90CDF4) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Data Rows
            ...dataRows.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              final isAlt = idx % 2 == 1;

              return TableRow(
                decoration: BoxDecoration(
                  color: isDark
                      ? (isAlt ? const Color(0xFF18202A) : const Color(0xFF1E2632))
                      : (isAlt ? Colors.grey.shade50 : Colors.white),
                ),
                children: row.map((cell) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Text.rich(
                      TextSpan(
                        children: parseInlineSpans(
                          cell,
                          baseStyle: baseStyle.copyWith(
                            fontSize: (baseStyle.fontSize ?? 13) * 0.92,
                            color: isDark ? const Color(0xFFE2E8F0) : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_Block> _parseBlocks(String input) {
    final lines = input.split(RegExp(r'\r?\n'));
    final blocks = <_Block>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // 1. Code blocks (```)
      if (trimmed.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // consume closing ```
        blocks.add(_Block(
          type: _BlockType.codeBlock,
          text: codeLines.join('\n'),
          bottomSpacing: 10,
        ));
        continue;
      }

      // 2. Horizontal Rules (---, ***, ___)
      if (RegExp(r'^(---|___|\*\*\*)$').hasMatch(trimmed)) {
        blocks.add(_Block(type: _BlockType.divider, text: '', bottomSpacing: 10));
        i++;
        continue;
      }

      // 3. Headings
      if (trimmed.startsWith('# ')) {
        blocks.add(_Block(
          type: _BlockType.h1,
          text: trimmed.substring(2).trim(),
          bottomSpacing: 10,
        ));
        i++;
        continue;
      }
      if (trimmed.startsWith('## ')) {
        blocks.add(_Block(
          type: _BlockType.h2,
          text: trimmed.substring(3).trim(),
          bottomSpacing: 8,
        ));
        i++;
        continue;
      }
      if (trimmed.startsWith('### ')) {
        blocks.add(_Block(
          type: _BlockType.h3,
          text: trimmed.substring(4).trim(),
          bottomSpacing: 6,
        ));
        i++;
        continue;
      }
      if (trimmed.startsWith('#### ')) {
        blocks.add(_Block(
          type: _BlockType.h4,
          text: trimmed.substring(5).trim(),
          bottomSpacing: 6,
        ));
        i++;
        continue;
      }

      // 4. Blockquotes
      if (trimmed.startsWith('>')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          var qText = lines[i].trim();
          qText = qText.replaceFirst(RegExp(r'^>\s?'), '');
          quoteLines.add(qText);
          i++;
        }
        blocks.add(_Block(
          type: _BlockType.blockquote,
          text: quoteLines.join(' '),
          bottomSpacing: 8,
        ));
        continue;
      }

      // 5. Tables
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        final tableRows = <List<String>>[];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          final tLine = lines[i].trim();
          // Skip divider rows like | :--- | ---: |
          if (!RegExp(r'^\|[\s:\-]+\|').hasMatch(tLine) || tLine.replaceAll(RegExp(r'[\s|:\-]'), '').isNotEmpty) {
            final cells = tLine
                .split('|')
                .where((c) => c.isNotEmpty)
                .map((c) => c.trim())
                .toList();
            if (cells.isNotEmpty) {
              tableRows.add(cells);
            }
          }
          i++;
        }
        if (tableRows.isNotEmpty) {
          blocks.add(_Block(
            type: _BlockType.table,
            text: '',
            rows: tableRows,
            bottomSpacing: 12,
          ));
        }
        continue;
      }

      // 6. Checkbox items (- [ ] or - [x])
      final checkMatch = RegExp(r'^[-*+]\s*\[([ xX])\]\s+(.+)$').firstMatch(trimmed);
      if (checkMatch != null) {
        final isChecked = checkMatch.group(1)!.trim().toLowerCase() == 'x';
        final itemText = checkMatch.group(2)!.trim();
        blocks.add(_Block(
          type: _BlockType.checkboxItem,
          text: itemText,
          isChecked: isChecked,
          bottomSpacing: 4,
        ));
        i++;
        continue;
      }

      // 7. Bullet items (- , * , + )
      final bulletMatch = RegExp(r'^[-*+•]\s+(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        blocks.add(_Block(
          type: _BlockType.bulletItem,
          text: bulletMatch.group(1)!.trim(),
          bottomSpacing: 4,
        ));
        i++;
        continue;
      }

      // 8. Numbered items (1. , 2. )
      final numberedMatch = RegExp(r'^(\d+\.)\s+(.+)$').firstMatch(trimmed);
      if (numberedMatch != null) {
        blocks.add(_Block(
          type: _BlockType.numberedItem,
          prefix: numberedMatch.group(1)!,
          text: numberedMatch.group(2)!.trim(),
          bottomSpacing: 4,
        ));
        i++;
        continue;
      }

      // 9. Normal paragraph (collect contiguous non-empty, non-special lines)
      final paraLines = <String>[];
      while (i < lines.length) {
        final pLine = lines[i].trim();
        if (pLine.isEmpty ||
            pLine.startsWith('#') ||
            pLine.startsWith('```') ||
            pLine.startsWith('>') ||
            (pLine.startsWith('|') && pLine.endsWith('|')) ||
            RegExp(r'^(---|___|\*\*\*)$').hasMatch(pLine) ||
            RegExp(r'^[-*+•]\s+').hasMatch(pLine) ||
            RegExp(r'^\d+\.\s+').hasMatch(pLine)) {
          break;
        }
        paraLines.add(pLine);
        i++;
      }

      if (paraLines.isNotEmpty) {
        blocks.add(_Block(
          type: _BlockType.paragraph,
          text: paraLines.join('\n'),
          bottomSpacing: 8,
        ));
      }
    }

    return blocks;
  }
}

/// A compact, single-span or single-block inline formatted text widget.
/// Ideal for individual LLM completions, judge verdicts, and critic reasoning.
class FormattedInlineText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool selectable;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const FormattedInlineText({
    Key? key,
    required this.text,
    this.style,
    this.selectable = true,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spans = FormattedMarkdownView.parseInlineSpans(text, baseStyle: style);

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

enum _BlockType {
  h1,
  h2,
  h3,
  h4,
  divider,
  codeBlock,
  blockquote,
  table,
  bulletItem,
  numberedItem,
  checkboxItem,
  paragraph,
}

class _Block {
  final _BlockType type;
  final String text;
  final String prefix;
  final bool isChecked;
  final List<List<String>> rows;
  final double bottomSpacing;

  _Block({
    required this.type,
    required this.text,
    this.prefix = '',
    this.isChecked = false,
    this.rows = const [],
    this.bottomSpacing = 6.0,
  });
}
