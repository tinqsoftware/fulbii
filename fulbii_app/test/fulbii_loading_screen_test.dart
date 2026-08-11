import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbii_app/src/app.dart';

void main() {
  testWidgets(
    'shows the branded loading screen without motion when requested',
    (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: FulbiiLoadingScreen()),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF071A10));
      expect(find.text('Preparando tu próxima pichanga'), findsOneWidget);
      expect(find.byKey(const Key('fulbii-loading-semantic')), findsOneWidget);

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        'assets/widget/logo_widget_transparente.png',
      );
    },
  );
}
