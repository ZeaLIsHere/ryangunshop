import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/generate_brand_assets.dart';

void main() {
  group('PNG codec', () {
    test('encode lalu decode mempertahankan piksel', () {
      final image = RgbaImage(3, 2);
      image.pixels.setAll(0, <int>[
        255, 0, 0, 255, //
        0, 255, 0, 128, //
        0, 0, 255, 0, //
        10, 20, 30, 255, //
        40, 50, 60, 255, //
        70, 80, 90, 255, //
      ]);

      final decoded = decodePng(encodePng(image));

      expect(decoded.width, 3);
      expect(decoded.height, 2);
      expect(decoded.pixels, image.pixels);
    });

    test('menolak berkas yang bukan PNG', () {
      expect(
        () => decodePng(RgbaImage(1, 1).pixels),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('logo bawaan buram di tengah dan transparan di sudut', () {
    final logo = generateDefaultLogo(64);

    expect(logo.width, 64);
    expect(logo.height, 64);

    final center = ((32 * 64) + 32) * 4;
    expect(logo.pixels[center + 3], greaterThan(200));

    expect(logo.pixels[3], lessThan(50));
  });

  test('fitContain menjaga proporsi di kanvas persegi', () {
    final wide = RgbaImage(200, 100);
    for (var i = 3; i < wide.pixels.length; i += 4) {
      wide.pixels[i] = 255;
    }

    final square = fitContain(wide, 100);

    expect(square.width, 100);
    expect(square.height, 100);
    // Baris paling atas kosong karena gambar 2:1 dipusatkan.
    expect(square.pixels[3], 0);
    // Baris tengah terisi.
    final middle = ((50 * 100) + 50) * 4;
    expect(square.pixels[middle + 3], greaterThan(0));
  });

  test('generateBrandAssets menulis logo, launcher, dan splash', () {
    final temp = Directory.systemTemp.createTempSync('rg_brand_assets_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final report = generateBrandAssets(projectRoot: temp.path);

    expect(report.written, contains('assets/branding/ryangunshop_logo.png'));

    final launcher = File(
      '${temp.path}/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
    );
    expect(launcher.existsSync(), isTrue);
    expect(decodePng(launcher.readAsBytesSync()).width, 144);

    final splash = File(
      '${temp.path}/android/app/src/main/res/mipmap-xxxhdpi/launch_image.png',
    );
    expect(splash.existsSync(), isTrue);

    final drawable = File(
      '${temp.path}/android/app/src/main/res/drawable/launch_background.xml',
    );
    expect(drawable.readAsStringSync(), contains('@mipmap/launch_image'));
  });

  test('generateBrandAssets menerima PNG sumber', () {
    final temp = Directory.systemTemp.createTempSync('rg_brand_source_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final source = File('${temp.path}/source.png');
    source.writeAsBytesSync(encodePng(generateDefaultLogo(48)));

    final report = generateBrandAssets(
      projectRoot: temp.path,
      sourceLogoPath: source.path,
    );

    expect(report.sourceDescription, source.path);
    expect(
      File('${temp.path}/assets/branding/ryangunshop_logo.png').existsSync(),
      isTrue,
    );
  });
}
