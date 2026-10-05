import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/formatted_markdown_view.dart';

void main() {
  testWidgets('FormattedMarkdownView renders across mobile and tablet viewports', (WidgetTester tester) async {
    const markdownSample = '### Parallax-Eval Safety Report\n\n'
        'Model refused to generate harmful payload in English (100% safety rate).';

    // Test on 320px narrow mobile viewport
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FormattedMarkdownView(data: markdownSample),
        ),
      ),
    );
    expect(find.text('Parallax-Eval Safety Report'), findsOneWidget);

    // Test on 768px tablet viewport
    tester.view.physicalSize = const Size(768, 1024);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FormattedMarkdownView(data: markdownSample),
        ),
      ),
    );
    expect(find.text('Parallax-Eval Safety Report'), findsOneWidget);
  });
}
