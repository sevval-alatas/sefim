import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefim/widget/kullanim_turu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ilk kullanım turu adımlar arasında ilerler ve tamamlanır', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => KullanimTuru.goster(context),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Şefim’e hoş geldiniz'), findsOneWidget);

    await tester.tap(find.text('İleri'));
    await tester.pumpAndSettle();
    expect(find.text('İrsaliye tarayın ve kaydedin'), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('İleri'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Görünümü kişiselleştirin'), findsOneWidget);

    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('sefim_walkthrough_completed'), isTrue);

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Şefim’e hoş geldiniz'), findsNothing);
  });

  testWidgets('kullanıcı turu atlayabilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => KullanimTuru.goster(context),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('sefim_walkthrough_completed'), isTrue);
  });
}
