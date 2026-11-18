import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kosfinder/main.dart';

void main() {
  testWidgets('KosFinderApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KosFinderApp());
    expect(find.byType(KosFinderApp), findsOneWidget);
  });
}
