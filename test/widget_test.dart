import 'package:flutter_test/flutter_test.dart';
import 'package:viewer_assist/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ViewerAssistApp());

    // Verify the app shows the title
    expect(find.text('📁 ViewerAssist'), findsOneWidget);
  });
}
