// Generator aset brand RyanGunshop.
//
// Menurunkan logo resmi menjadi launcher icon Android dan gambar native splash
// tanpa mengubah proporsinya, sesuai `DESIGN.md` bagian "Brand Asset Workflow".
//
// Pakai:
//   cd mobile
//   dart run tool/generate_brand_assets.dart "path/ke/logo.png"
//
// Bila sumber tidak dioper, tool membuat logo bawaan (slate blue + tas belanja)
// agar aset brand tetap tersedia. Tool ini sengaja tidak memakai paket pihak
// ketiga: encoder/decoder PNG ditulis memakai `dart:io` (zlib) saja.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Ukuran launcher icon Android per kepadatan layar (dp -> piksel).
const Map<String, int> _launcherSizes = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// Ukuran gambar splash per kepadatan layar.
const Map<String, int> _splashSizes = {
  'mdpi': 96,
  'hdpi': 144,
  'xhdpi': 192,
  'xxhdpi': 288,
  'xxxhdpi': 384,
};

/// Ukuran master logo yang disimpan di `assets/branding`.
const int _masterLogoSize = 512;

void main(List<String> args) {
  final sourceArg = args.isNotEmpty ? args.first.trim() : '';
  final projectRoot = _resolveProjectRoot();

  final report = generateBrandAssets(
    projectRoot: projectRoot,
    sourceLogoPath: sourceArg.isEmpty ? null : sourceArg,
  );

  stdout.writeln('Aset brand RyanGunshop dibuat ulang.');
  stdout.writeln('Sumber : ${report.sourceDescription}');
  for (final path in report.written) {
    stdout.writeln('  - $path');
  }
}

/// Menentukan akar proyek `mobile/` dari lokasi skrip ini, sehingga tool dapat
/// dijalankan dari direktori mana pun.
String _resolveProjectRoot() {
  final scriptDir = File.fromUri(Platform.script).parent;
  final candidate = scriptDir.parent;
  if (File('${candidate.path}${Platform.pathSeparator}pubspec.yaml')
      .existsSync()) {
    return candidate.path;
  }
  return Directory.current.path;
}

/// Hasil pembuatan aset brand.
class BrandAssetsReport {
  const BrandAssetsReport({
    required this.sourceDescription,
    required this.written,
  });

  /// Keterangan sumber logo yang dipakai.
  final String sourceDescription;

  /// Daftar berkas yang ditulis, relatif terhadap akar proyek.
  final List<String> written;
}

/// Membuat ulang seluruh aset brand di bawah [projectRoot].
///
/// Bila [sourceLogoPath] dioper, PNG itu dipakai sebagai sumber. Bila kosong,
/// logo bawaan dibuat secara prosedural.
BrandAssetsReport generateBrandAssets({
  required String projectRoot,
  String? sourceLogoPath,
}) {
  final root = Directory(projectRoot);
  final written = <String>[];

  final RgbaImage logo;
  final String sourceDescription;
  if (sourceLogoPath != null) {
    final file = File(sourceLogoPath);
    if (!file.existsSync()) {
      throw ArgumentError('Berkas logo tidak ditemukan: $sourceLogoPath');
    }
    logo = decodePng(file.readAsBytesSync());
    sourceDescription = sourceLogoPath;
  } else {
    logo = generateDefaultLogo(_masterLogoSize);
    sourceDescription = 'bawaan (tanpa sumber)';
  }

  void write(String relativePath, Uint8List bytes) {
    final file = File(
      '${root.path}${Platform.pathSeparator}'
      '${relativePath.replaceAll('/', Platform.pathSeparator)}',
    );
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    written.add(relativePath);
  }

  // Master logo.
  write(
    'assets/branding/ryangunshop_logo.png',
    encodePng(fitContain(logo, _masterLogoSize)),
  );

  // Launcher icon Android.
  for (final entry in _launcherSizes.entries) {
    write(
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      encodePng(fitContain(logo, entry.value)),
    );
  }

  // Gambar native splash.
  for (final entry in _splashSizes.entries) {
    write(
      'android/app/src/main/res/mipmap-${entry.key}/launch_image.png',
      encodePng(fitContain(logo, entry.value)),
    );
  }

  // Panggil gambar splash dari layer-list Android.
  write(
    'android/app/src/main/res/drawable/launch_background.xml',
    _launchBackground('<item android:drawable="@android:color/white" />'),
  );
  write(
    'android/app/src/main/res/drawable-v21/launch_background.xml',
    _launchBackground('<item android:drawable="?android:colorBackground" />'),
  );

  return BrandAssetsReport(
    sourceDescription: sourceDescription,
    written: written,
  );
}

Uint8List _launchBackground(String backgroundItem) {
  final xml =
      '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Dibuat ulang oleh tool/generate_brand_assets.dart. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    $backgroundItem
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/launch_image" />
    </item>
</layer-list>
''';
  return Uint8List.fromList(xml.codeUnits);
}

// ---------------------------------------------------------------------------
// Raster image
// ---------------------------------------------------------------------------

/// Gambar RGBA 8-bit dengan alpha lurus (straight alpha).
class RgbaImage {
  RgbaImage(this.width, this.height) : pixels = Uint8List(width * height * 4);

  RgbaImage.fromPixels(this.width, this.height, this.pixels)
    : assert(pixels.length == width * height * 4);

  final int width;
  final int height;
  final Uint8List pixels;

  bool get isEmpty => width <= 0 || height <= 0;
}

/// Mengubah ukuran [src] menjaga proporsi lalu meletakkannya di tengah kanvas
/// persegi berukuran [size] dengan latar transparan.
RgbaImage fitContain(RgbaImage src, int size) {
  final canvas = RgbaImage(size, size);
  if (src.isEmpty) {
    return canvas;
  }
  final scale = math.min(size / src.width, size / src.height);
  final targetW = math.max(1, (src.width * scale).round());
  final targetH = math.max(1, (src.height * scale).round());
  final scaled = resizeBilinear(src, targetW, targetH);
  final offsetX = ((size - targetW) / 2).round();
  final offsetY = ((size - targetH) / 2).round();

  for (var y = 0; y < targetH; y++) {
    final dy = y + offsetY;
    if (dy < 0 || dy >= size) {
      continue;
    }
    for (var x = 0; x < targetW; x++) {
      final dx = x + offsetX;
      if (dx < 0 || dx >= size) {
        continue;
      }
      final si = (y * targetW + x) * 4;
      final di = (dy * size + dx) * 4;
      canvas.pixels[di] = scaled.pixels[si];
      canvas.pixels[di + 1] = scaled.pixels[si + 1];
      canvas.pixels[di + 2] = scaled.pixels[si + 2];
      canvas.pixels[di + 3] = scaled.pixels[si + 3];
    }
  }
  return canvas;
}

/// Resampling bilinear.
RgbaImage resizeBilinear(RgbaImage src, int width, int height) {
  if (src.isEmpty || width <= 0 || height <= 0) {
    return RgbaImage(math.max(1, width), math.max(1, height));
  }
  final out = RgbaImage(width, height);
  final xRatio = width == 1 ? 0.0 : (src.width - 1) / (width - 1);
  final yRatio = height == 1 ? 0.0 : (src.height - 1) / (height - 1);

  for (var y = 0; y < height; y++) {
    final srcY = y * yRatio;
    final y0 = srcY.floor();
    final y1 = math.min(y0 + 1, src.height - 1);
    final fy = srcY - y0;

    for (var x = 0; x < width; x++) {
      final srcX = x * xRatio;
      final x0 = srcX.floor();
      final x1 = math.min(x0 + 1, src.width - 1);
      final fx = srcX - x0;

      final di = (y * width + x) * 4;
      for (var c = 0; c < 4; c++) {
        final i00 = (y0 * src.width + x0) * 4 + c;
        final i10 = (y0 * src.width + x1) * 4 + c;
        final i01 = (y1 * src.width + x0) * 4 + c;
        final i11 = (y1 * src.width + x1) * 4 + c;

        final top = src.pixels[i00] * (1 - fx) + src.pixels[i10] * fx;
        final bottom = src.pixels[i01] * (1 - fx) + src.pixels[i11] * fx;
        out.pixels[di + c] = (top * (1 - fy) + bottom * fy).round().clamp(
          0,
          255,
        );
      }
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Logo bawaan
// ---------------------------------------------------------------------------

/// Menggambar logo bawaan RyanGunshop: kanvas slate blue membulat dengan tas
/// belanja putih dan motif barcode, memakai token warna `AppColors`.
RgbaImage generateDefaultLogo(int size) {
  const primary = 0xFF565C9D;
  const primaryDark = 0xFF34385F;
  const primaryLight = 0xFFE9EAF6;
  const surface = 0xFFFFFFFF;

  final img = RgbaImage(size, size);
  final f = size / 512.0;

  // Latar: kotak membulat dengan gradasi primary -> primary dark.
  final radius = 112.0 * f;
  for (var y = 0; y < size; y++) {
    final t = size <= 1 ? 0.0 : y / (size - 1);
    final color = _lerpColor(primary, primaryDark, t);
    for (var x = 0; x < size; x++) {
      final cov = _coverage(
        _roundedRectSdf(
          x + 0.5,
          y + 0.5,
          0,
          0,
          size.toDouble(),
          size.toDouble(),
          radius,
        ),
      );
      _blend(img, x, y, color, cov);
    }
  }

  // Gagang tas (cincin putih, separuh bawahnya tertutup badan tas).
  _fillRing(img, 256 * f, 214 * f, 64 * f, 24 * f, surface);

  // Badan tas belanja.
  _fillRoundedRect(img, 148 * f, 206 * f, 364 * f, 396 * f, 30 * f, surface);

  // Panel terang berisi motif barcode.
  _fillRoundedRect(
    img,
    176 * f,
    300 * f,
    336 * f,
    372 * f,
    12 * f,
    primaryLight,
  );

  // Motif barcode.
  const bars = <(double, double)>[
    (192, 8),
    (206, 6),
    (218, 10),
    (234, 6),
    (246, 8),
    (260, 6),
    (276, 10),
    (294, 6),
    (306, 8),
    (318, 6),
  ];
  for (final bar in bars) {
    _fillRoundedRect(
      img,
      bar.$1 * f,
      314 * f,
      (bar.$1 + bar.$2) * f,
      358 * f,
      2 * f,
      primaryDark,
    );
  }

  return img;
}

void _fillRoundedRect(
  RgbaImage img,
  double x0,
  double y0,
  double x1,
  double y1,
  double radius,
  int color,
) {
  final minX = math.max(0, (x0 - 1).floor());
  final maxX = math.min(img.width, (x1 + 1).ceil());
  final minY = math.max(0, (y0 - 1).floor());
  final maxY = math.min(img.height, (y1 + 1).ceil());
  for (var y = minY; y < maxY; y++) {
    for (var x = minX; x < maxX; x++) {
      final cov = _coverage(
        _roundedRectSdf(x + 0.5, y + 0.5, x0, y0, x1, y1, radius),
      );
      _blend(img, x, y, color, cov);
    }
  }
}

void _fillRing(
  RgbaImage img,
  double cx,
  double cy,
  double radius,
  double thickness,
  int color,
) {
  final outer = radius + thickness;
  final minX = math.max(0, (cx - outer - 1).floor());
  final maxX = math.min(img.width, (cx + outer + 1).ceil());
  final minY = math.max(0, (cy - outer - 1).floor());
  final maxY = math.min(img.height, (cy + outer + 1).ceil());
  for (var y = minY; y < maxY; y++) {
    for (var x = minX; x < maxX; x++) {
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final cov = _coverage((dist - radius).abs() - thickness / 2);
      _blend(img, x, y, color, cov);
    }
  }
}

/// Jarak bertanda ke persegi membulat.
double _roundedRectSdf(
  double px,
  double py,
  double x0,
  double y0,
  double x1,
  double y1,
  double radius,
) {
  final cx = (x0 + x1) / 2;
  final cy = (y0 + y1) / 2;
  final halfW = (x1 - x0) / 2 - radius;
  final halfH = (y1 - y0) / 2 - radius;
  final qx = (px - cx).abs() - halfW;
  final qy = (py - cy).abs() - halfH;
  final outside = math.sqrt(
    math.max(qx, 0) * math.max(qx, 0) + math.max(qy, 0) * math.max(qy, 0),
  );
  final inside = math.min(math.max(qx, qy), 0.0);
  return outside + inside - radius;
}

/// Cakupan anti-alias dari jarak bertanda (1 piksel transisi).
double _coverage(double sdf) => (0.5 - sdf).clamp(0.0, 1.0);

void _blend(RgbaImage img, int x, int y, int color, double coverage) {
  if (coverage <= 0 || x < 0 || y < 0 || x >= img.width || y >= img.height) {
    return;
  }
  final a = ((color >> 24) & 0xff) / 255.0 * coverage.clamp(0.0, 1.0);
  if (a <= 0) {
    return;
  }
  final sr = (color >> 16) & 0xff;
  final sg = (color >> 8) & 0xff;
  final sb = color & 0xff;

  final i = (y * img.width + x) * 4;
  final da = img.pixels[i + 3] / 255.0;
  final outA = a + da * (1 - a);
  if (outA <= 0) {
    img.pixels[i] = 0;
    img.pixels[i + 1] = 0;
    img.pixels[i + 2] = 0;
    img.pixels[i + 3] = 0;
    return;
  }
  img.pixels[i] = ((sr * a + img.pixels[i] * da * (1 - a)) / outA)
      .round()
      .clamp(0, 255);
  img.pixels[i + 1] = ((sg * a + img.pixels[i + 1] * da * (1 - a)) / outA)
      .round()
      .clamp(0, 255);
  img.pixels[i + 2] = ((sb * a + img.pixels[i + 2] * da * (1 - a)) / outA)
      .round()
      .clamp(0, 255);
  img.pixels[i + 3] = (outA * 255).round().clamp(0, 255);
}

int _lerpColor(int a, int b, double t) {
  int channel(int shift) {
    final va = (a >> shift) & 0xff;
    final vb = (b >> shift) & 0xff;
    return (va + (vb - va) * t).round().clamp(0, 255);
  }

  return (channel(24) << 24) |
      (channel(16) << 16) |
      (channel(8) << 8) |
      channel(0);
}

// ---------------------------------------------------------------------------
// PNG codec (tanpa dependensi, memakai zlib dart:io)
// ---------------------------------------------------------------------------

const List<int> _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

/// Mengubah [image] menjadi PNG RGBA 8-bit.
Uint8List encodePng(RgbaImage image) {
  final builder = BytesBuilder();
  builder.add(_pngSignature);

  final ihdr = BytesBuilder();
  ihdr.add(_uint32(image.width));
  ihdr.add(_uint32(image.height));
  ihdr.addByte(8); // bit depth
  ihdr.addByte(6); // color type RGBA
  ihdr.addByte(0); // compression
  ihdr.addByte(0); // filter
  ihdr.addByte(0); // interlace
  builder.add(_chunk('IHDR', ihdr.takeBytes()));

  final stride = image.width * 4;
  final raw = Uint8List((stride + 1) * image.height);
  for (var y = 0; y < image.height; y++) {
    final rowStart = y * (stride + 1);
    raw[rowStart] = 0; // filter: none
    raw.setRange(rowStart + 1, rowStart + 1 + stride, image.pixels, y * stride);
  }

  final compressed = Uint8List.fromList(ZLibCodec(level: 6).encode(raw));
  builder.add(_chunk('IDAT', compressed));
  builder.add(_chunk('IEND', Uint8List(0)));
  return builder.takeBytes();
}

/// Membaca PNG 8/16-bit (grayscale, RGB, palet, atau RGBA) menjadi RGBA.
///
/// Melempar [FormatException] dengan pesan jelas untuk warna terindeks < 8-bit
/// atau PNG interlaced yang belum didukung.
RgbaImage decodePng(Uint8List bytes) {
  if (bytes.length < 8) {
    throw const FormatException('Berkas terlalu pendek untuk PNG.');
  }
  for (var i = 0; i < _pngSignature.length; i++) {
    if (bytes[i] != _pngSignature[i]) {
      throw const FormatException('Bukan berkas PNG yang valid.');
    }
  }

  var offset = 8;
  int? width;
  int? height;
  var bitDepth = 8;
  var colorType = 6;
  var interlace = 0;
  final idat = BytesBuilder();
  List<int>? palette;
  List<int>? transparency;

  while (offset + 8 <= bytes.length) {
    final length = _readUint32(bytes, offset);
    final type = String.fromCharCodes(bytes, offset + 4, offset + 8);
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd > bytes.length) {
      break;
    }

    switch (type) {
      case 'IHDR':
        width = _readUint32(bytes, dataStart);
        height = _readUint32(bytes, dataStart + 4);
        bitDepth = bytes[dataStart + 8];
        colorType = bytes[dataStart + 9];
        interlace = bytes[dataStart + 12];
      case 'PLTE':
        palette = bytes.sublist(dataStart, dataEnd);
      case 'tRNS':
        transparency = bytes.sublist(dataStart, dataEnd);
      case 'IDAT':
        idat.add(bytes.sublist(dataStart, dataEnd));
      case 'IEND':
        offset = dataEnd;
    }

    offset = dataEnd + 4; // + CRC
    if (type == 'IEND') {
      break;
    }
  }

  if (width == null || height == null) {
    throw const FormatException('IHDR PNG tidak ditemukan.');
  }
  if (interlace != 0) {
    throw const FormatException('PNG interlaced belum didukung.');
  }
  if (bitDepth < 8) {
    throw FormatException(
      'Kedalaman bit $bitDepth belum didukung; pakai 8/16-bit.',
    );
  }

  final channels = switch (colorType) {
    0 => 1,
    2 => 3,
    3 => 1,
    4 => 2,
    6 => 4,
    _ => throw FormatException('Color type PNG $colorType tidak dikenal.'),
  };
  final bytesPerSample = bitDepth ~/ 8;
  final bpp = channels * bytesPerSample;
  final stride = width * bpp;

  final inflated = Uint8List.fromList(ZLibCodec().decode(idat.takeBytes()));
  final expected = (stride + 1) * height;
  if (inflated.length < expected) {
    throw const FormatException('Data IDAT PNG tidak lengkap.');
  }

  final rows = _unfilter(inflated, width, height, bpp, stride);
  final out = RgbaImage(width, height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final src = y * stride + x * bpp;
      final dst = (y * width + x) * 4;
      switch (colorType) {
        case 0:
          final g = rows[src];
          out.pixels[dst] = g;
          out.pixels[dst + 1] = g;
          out.pixels[dst + 2] = g;
          out.pixels[dst + 3] = 255;
        case 2:
          out.pixels[dst] = rows[src];
          out.pixels[dst + 1] = rows[src + bytesPerSample];
          out.pixels[dst + 2] = rows[src + 2 * bytesPerSample];
          out.pixels[dst + 3] = 255;
        case 3:
          final index = rows[src];
          if (palette == null || index * 3 + 2 >= palette.length) {
            throw const FormatException('Indeks palet PNG di luar jangkauan.');
          }
          out.pixels[dst] = palette[index * 3];
          out.pixels[dst + 1] = palette[index * 3 + 1];
          out.pixels[dst + 2] = palette[index * 3 + 2];
          out.pixels[dst +
              3] = (transparency != null && index < transparency.length)
              ? transparency[index]
              : 255;
        case 4:
          final g = rows[src];
          out.pixels[dst] = g;
          out.pixels[dst + 1] = g;
          out.pixels[dst + 2] = g;
          out.pixels[dst + 3] = rows[src + bytesPerSample];
        case 6:
          out.pixels[dst] = rows[src];
          out.pixels[dst + 1] = rows[src + bytesPerSample];
          out.pixels[dst + 2] = rows[src + 2 * bytesPerSample];
          out.pixels[dst + 3] = rows[src + 3 * bytesPerSample];
      }
    }
  }
  return out;
}

Uint8List _unfilter(Uint8List raw, int width, int height, int bpp, int stride) {
  final out = Uint8List(stride * height);
  final previous = Uint8List(stride);
  var rawOffset = 0;

  for (var y = 0; y < height; y++) {
    final filter = raw[rawOffset++];
    final rowStart = y * stride;
    for (var x = 0; x < stride; x++) {
      final value = raw[rawOffset + x];
      final left = x >= bpp ? out[rowStart + x - bpp] : 0;
      final up = previous[x];
      final upLeft = x >= bpp ? previous[x - bpp] : 0;

      final reconstructed = switch (filter) {
        0 => value,
        1 => value + left,
        2 => value + up,
        3 => value + ((left + up) >> 1),
        4 => value + _paeth(left, up, upLeft),
        _ => throw FormatException('Filter PNG $filter tidak dikenal.'),
      };
      out[rowStart + x] = reconstructed & 0xff;
    }
    previous.setRange(0, stride, out, rowStart);
    rawOffset += stride;
  }
  return out;
}

int _paeth(int a, int b, int c) {
  final p = a + b - c;
  final pa = (p - a).abs();
  final pb = (p - b).abs();
  final pc = (p - c).abs();
  if (pa <= pb && pa <= pc) {
    return a;
  }
  if (pb <= pc) {
    return b;
  }
  return c;
}

Uint8List _chunk(String type, Uint8List data) {
  final builder = BytesBuilder();
  builder.add(_uint32(data.length));
  final typeBytes = type.codeUnits;
  builder.add(typeBytes);
  builder.add(data);

  final crcInput = BytesBuilder()
    ..add(typeBytes)
    ..add(data);
  builder.add(_uint32(_crc32(crcInput.takeBytes())));
  return builder.takeBytes();
}

Uint8List _uint32(int value) {
  final data = ByteData(4)..setUint32(0, value & 0xffffffff, Endian.big);
  return data.buffer.asUint8List();
}

int _readUint32(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xedb88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xff] ^ (crc >> 8);
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
