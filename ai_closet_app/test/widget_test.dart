import 'package:ai_closet_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AI closet shell shows the home workflow', (tester) async {
    await tester.pumpWidget(const AiClosetApp());

    expect(find.text('AI 옷장'), findsOneWidget);
    expect(find.text('촬영'), findsOneWidget);
    expect(find.text('옷장에게 질문'), findsOneWidget);
    expect(find.text('최근 추가한 옷'), findsOneWidget);
  });

  testWidgets('bottom navigation opens add item workflow', (tester) async {
    await tester.pumpWidget(const AiClosetApp());

    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    await tester.pumpAndSettle();

    expect(find.text('옷 추가'), findsOneWidget);
    expect(find.text('가이드 안에 옷 한 벌만 맞춰주세요'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Fashionpedia 분류 결과'),
      200,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Fashionpedia 분류 결과'), findsOneWidget);
  });

  testWidgets('home quick action opens capture workflow', (tester) async {
    await tester.pumpWidget(const AiClosetApp());

    await tester.tap(find.text('촬영'));
    await tester.pumpAndSettle();

    expect(find.text('옷 추가'), findsOneWidget);
    expect(find.text('가이드 안에 옷 한 벌만 맞춰주세요'), findsOneWidget);
  });

  testWidgets('closet filters dummy items on the frontend', (tester) async {
    await tester.pumpWidget(const AiClosetApp());

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();

    expect(find.text('6개의 옷이 보여요'), findsOneWidget);

    await tester.tap(find.text('아우터').first);
    await tester.pumpAndSettle();

    expect(find.text('2개의 옷이 보여요'), findsOneWidget);
    expect(find.text('블랙 울 블레이저'), findsOneWidget);
    expect(find.text('올리브 필드 재킷'), findsOneWidget);
  });
}
