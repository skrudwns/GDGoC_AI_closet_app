import 'package:ai_closet_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AI closet shell shows the home workflow', (tester) async {
    await tester.pumpWidget(const AiClosetApp());
    await tester.pump();

    expect(find.text('AI 옷장'), findsOneWidget);
    expect(find.text('촬영'), findsOneWidget);
    expect(find.text('옷장에게 질문'), findsOneWidget);
    expect(find.text('최근 추가한 옷'), findsOneWidget);
  });

  testWidgets('bottom navigation opens add item workflow', (tester) async {
    await tester.pumpWidget(const AiClosetApp());
    await tester.pump();

    await tester.tap(find.text('추가'));
    await tester.pump();

    expect(find.text('옷 추가'), findsOneWidget);
    expect(find.text('갤러리에서 이미지를 선택하세요'), findsOneWidget);
  });

  testWidgets('settings saves a Gemini API key', (tester) async {
    await tester.pumpWidget(const AiClosetApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump();

    expect(find.text('Gemini API 키'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'AIza-test-key');
    await tester.tap(find.text('저장'));
    await tester.pump();

    expect(find.text('Gemini API 키 저장 완료'), findsOneWidget);
  });

  testWidgets('question tab asks for a Gemini key before calling LLM',
      (tester) async {
    await tester.pumpWidget(const AiClosetApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pump();

    expect(find.text('옷장에게 질문'), findsOneWidget);
    expect(find.text('Gemini에게 질문'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '내일 면접에 뭐 입을까?',
    );
    await tester.tap(find.text('Gemini에게 질문'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Gemini API 키'), findsOneWidget);
  });
}
