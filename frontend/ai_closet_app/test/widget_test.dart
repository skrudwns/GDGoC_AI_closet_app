import 'package:ai_closet_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Offstage는 모든 탭을 렌더링하므로 mock 이미지 URL 오류를 무시합니다.
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('NetworkImageLoadException') ||
          details.exception.toString().contains('HTTP request failed') ||
          details.exception.toString().contains('Multiple exceptions')) {
        return; // 이미지 로딩 오류는 테스트에서 무시
      }
      FlutterError.presentError(details);
    };
  });

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
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
    // 새 UI: 입력 힌트 텍스트와 전송 아이콘 버튼 확인
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '내일 면접에 뭐 입을까?',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Gemini API 키'), findsOneWidget);
  });
}
