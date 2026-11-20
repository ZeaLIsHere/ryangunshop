/// Footprint logis; tidak menyimpan stok atau penempatan produk.
enum MonitorFixtureType {
  shelf('Rak', 3, 1),
  fridge('Kulkas', 2, 2),
  showcase('Etalase', 2, 1),
  cashCounter('Meja kasir', 3, 2);

  const MonitorFixtureType(this.label, this.width, this.height);
  final String label;
  final int width;
  final int height;
}

final class UnsupportedMonitorLayoutVersion extends FormatException {
  UnsupportedMonitorLayoutVersion(this.version)
    : super('Versi tata letak Monitor tidak didukung: $version');
  final int version;
}

final class MonitorFixture {
  MonitorFixture({
    required this.id,
    required this.type,
    required this.name,
    required this.x,
    required this.y,
    this.quarterTurns = 0,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(id)) {
      throw const FormatException('ID objek Monitor tidak valid');
    }
    if (name.trim().isEmpty ||
        name != name.trim() ||
        name.length > 80 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
      throw const FormatException(
        'Nama objek harus 1–80 karakter tanpa kontrol',
      );
    }
    _integer(x, 'x', 0, MonitorLayout.maxGridSize - 1);
    _integer(y, 'y', 0, MonitorLayout.maxGridSize - 1);
    _integer(quarterTurns, 'quarterTurns', 0, 3);
  }

  final String id;
  final MonitorFixtureType type;
  final String name;
  final int x;
  final int y;
  final int quarterTurns;
  int get width => quarterTurns.isEven ? type.width : type.height;
  int get height => quarterTurns.isEven ? type.height : type.width;

  MonitorFixture copyWith({String? name, int? x, int? y, int? quarterTurns}) =>
      MonitorFixture(
        id: id,
        type: type,
        name: name ?? this.name,
        x: x ?? this.x,
        y: y ?? this.y,
        quarterTurns: quarterTurns ?? this.quarterTurns,
      );

  factory MonitorFixture.fromJson(Object? value) {
    final json = _object(value, {
      'id',
      'type',
      'name',
      'x',
      'y',
      'quarterTurns',
    });
    final types = MonitorFixtureType.values.where(
      (t) => t.name == json['type'],
    );
    if (types.isEmpty) {
      throw const FormatException('Jenis objek Monitor tidak valid');
    }
    return MonitorFixture(
      id: _string(json['id']),
      type: types.single,
      name: _string(json['name']),
      x: _integer(json['x'], 'x', 0, MonitorLayout.maxGridSize - 1),
      y: _integer(json['y'], 'y', 0, MonitorLayout.maxGridSize - 1),
      quarterTurns: _integer(json['quarterTurns'], 'quarterTurns', 0, 3),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'x': x,
    'y': y,
    'quarterTurns': quarterTurns,
  };
}

final class MonitorLayout {
  MonitorLayout({
    this.gridWidth = 16,
    this.gridHeight = 16,
    Iterable<MonitorFixture> fixtures = const [],
    Map<String, String> assignments = const {},
  }) : fixtures = List.unmodifiable(fixtures),
       assignments = Map.unmodifiable(assignments) {
    if (this.assignments.length > 400) {
      throw const FormatException('Maksimal 400 penempatan per layout');
    }
    _integer(gridWidth, 'gridWidth', 4, maxGridSize);
    _integer(gridHeight, 'gridHeight', 4, maxGridSize);
    // ponytail: 100 objek/grid 64; naikkan setelah benchmark renderer perangkat.
    if (this.fixtures.length > 100) {
      throw const FormatException('Maksimal 100 objek');
    }
    final ids = <String>{};
    for (var i = 0; i < this.fixtures.length; i++) {
      final a = this.fixtures[i];
      if (!ids.add(a.id)) throw const FormatException('ID objek berulang');
      if (a.x + a.width > gridWidth || a.y + a.height > gridHeight) {
        throw FormatException('Objek di luar area: ${a.name}');
      }
      for (final b in this.fixtures.take(i)) {
        if (a.x < b.x + b.width &&
            a.x + a.width > b.x &&
            a.y < b.y + b.height &&
            a.y + a.height > b.y) {
          throw FormatException('Objek bertumpuk: ${a.name} dan ${b.name}');
        }
      }
    }
    for (final entry in this.assignments.entries) {
      if (entry.key.trim().isEmpty ||
          entry.key.contains('/') ||
          entry.key.length > 1500 ||
          !this.fixtures.any(
            (f) =>
                f.id == entry.value && f.type != MonitorFixtureType.cashCounter,
          )) {
        throw const FormatException('Penempatan produk tidak valid');
      }
    }
  }

  static const version = 1;
  static const mainId = 'main';
  static const maxGridSize = 64;
  final int gridWidth;
  final int gridHeight;
  final List<MonitorFixture> fixtures;
  final Map<String, String> assignments;

  MonitorLayout copyWith({
    int? gridWidth,
    int? gridHeight,
    Iterable<MonitorFixture>? fixtures,
    Map<String, String>? assignments,
  }) => MonitorLayout(
    gridWidth: gridWidth ?? this.gridWidth,
    gridHeight: gridHeight ?? this.gridHeight,
    fixtures: fixtures ?? this.fixtures,
    assignments: assignments ?? this.assignments,
  );

  factory MonitorLayout.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Dokumen tata letak tidak valid');
    }
    final normalized = Map<Object?, Object?>.from(value)
      ..putIfAbsent('assignments', () => <String, String>{});
    final json = _object(normalized, {
      'assignments',
      'schemaVersion',
      'id',
      'gridWidth',
      'gridHeight',
      'fixtures',
    });
    final schema = _integer(
      json['schemaVersion'],
      'schemaVersion',
      1,
      2147483647,
    );
    if (schema != version) throw UnsupportedMonitorLayoutVersion(schema);
    if (json['id'] != mainId || json['fixtures'] is! List) {
      throw const FormatException('Dokumen tata letak tidak valid');
    }
    return MonitorLayout(
      gridWidth: _integer(json['gridWidth'], 'gridWidth', 4, maxGridSize),
      gridHeight: _integer(json['gridHeight'], 'gridHeight', 4, maxGridSize),
      fixtures: (json['fixtures'] as List).map(MonitorFixture.fromJson),
      assignments: _assignments(json['assignments']),
    );
  }

  Map<String, Object> toJson() => {
    'schemaVersion': version,
    'id': mainId,
    'gridWidth': gridWidth,
    'gridHeight': gridHeight,
    'fixtures': fixtures.map((f) => f.toJson()).toList(),
    'assignments': assignments,
  };
}

enum MonitorTemplate {
  walls('Rak dinding'),
  rows('Dua baris rak'),
  wallsAndCenter('Rak dinding + tengah');

  const MonitorTemplate(this.label);
  final String label;

  MonitorLayout create() {
    MonitorFixture fixture(
      String key,
      MonitorFixtureType type,
      String label,
      int x,
      int y, [
      int turns = 0,
    ]) => MonitorFixture(
      id: '${name}_$key',
      type: type,
      name: label,
      x: x,
      y: y,
      quarterTurns: turns,
    );
    final shelves = switch (this) {
      walls => [(1, 1, 0), (5, 1, 0), (1, 5, 1), (1, 9, 1)],
      rows => [(3, 3, 1), (3, 7, 1), (9, 3, 1), (9, 7, 1)],
      wallsAndCenter => [(1, 1, 0), (5, 1, 0), (1, 5, 1), (6, 6, 1), (9, 6, 1)],
    };
    return MonitorLayout(
      fixtures: [
        for (var i = 0; i < shelves.length; i++)
          fixture(
            'shelf_${i + 1}',
            MonitorFixtureType.shelf,
            'Rak ${i + 1}',
            shelves[i].$1,
            shelves[i].$2,
            shelves[i].$3,
          ),
        fixture('fridge', MonitorFixtureType.fridge, 'Kulkas', 12, 1),
        fixture('showcase', MonitorFixtureType.showcase, 'Etalase', 7, 12),
        fixture(
          'counter',
          MonitorFixtureType.cashCounter,
          'Meja kasir',
          10,
          12,
        ),
      ],
    );
  }
}

int _integer(Object? value, String field, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw FormatException('$field harus bilangan bulat $min–$max');
  }
  return value;
}

String _string(Object? value) {
  if (value is! String) {
    throw const FormatException('Teks tata letak tidak valid');
  }
  return value;
}

Map<String, Object?> _object(Object? value, Set<String> keys) {
  if (value is! Map ||
      value.length != keys.length ||
      value.keys.any((key) => key is! String || !keys.contains(key))) {
    throw const FormatException('Bidang tata letak tidak valid');
  }
  return Map<String, Object?>.from(value);
}

Map<String, String> _assignments(Object? value) {
  if (value is! Map || value.length > 400) {
    throw const FormatException('Maksimal 400 penempatan per layout');
  }
  return {
    for (final entry in value.entries) _string(entry.key): _string(entry.value),
  };
}
