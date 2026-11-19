import 'package:flutter_test/flutter_test.dart';

import 'package:peer_learning_mobile/app.dart';
import 'package:peer_learning_mobile/state/app_state.dart';

void main() {
  testWidgets('Splash screen leads to the login screen', (tester) async {
    await tester.pumpWidget(
      AppScope(notifier: AppState(), child: const PeerTeachingApp()),
    );

    expect(find.text('Learn Share Grow'), findsOneWidget);

    // Let the splash timer finish and the fade transition complete.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome Back 👋'), findsOneWidget);
  });
}
