import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('ParallaxEvalApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ParallaxEvalApp());
    expect(find.text('Parallax-Eval'), findsOneWidget);
  });
}
