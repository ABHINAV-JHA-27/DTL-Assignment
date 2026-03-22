import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:meetspace_mobile/app/app.dart';

void main() {
  testWidgets('renders the meeting launch screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetSpaceApp());

    expect(find.text('Start or join a meeting'), findsOneWidget);
    expect(find.text('Create Meeting'), findsOneWidget);
    expect(find.text('Join Meeting'), findsOneWidget);
  });
}
