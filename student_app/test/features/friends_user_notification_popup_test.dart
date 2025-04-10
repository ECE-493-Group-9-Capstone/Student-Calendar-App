import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:student_app/features/friends/friends_user_notification_popup.dart';

@GenerateMocks([FriendsUserNotificationPopup])
void main() {
  group('FriendsUserNotificationPopup', () {
    testWidgets('renders FriendsUserNotificationPopup', (tester) async {
      // Use the mockPopup if needed in the test
      await tester.pumpWidget(const FriendsUserNotificationPopup(
        userId: 'User2',
      ));
      expect(find.byType(FriendsUserNotificationPopup), findsOneWidget);
    });
  });
}
