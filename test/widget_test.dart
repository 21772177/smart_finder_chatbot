import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:second_brain/main.dart';

void main() {
  testWidgets('App renders main shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SecondBrainApp());
    expect(find.text('Second Brain'), findsWidgets);
  });
}
