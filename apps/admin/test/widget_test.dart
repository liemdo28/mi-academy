import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy_admin/main.dart';

void main() {
  testWidgets('renders login route on startup', (tester) async {
    await tester.pumpWidget(const MIAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('MI Academy Admin'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
