import 'package:flutter/foundation.dart';

import '../model/fixture_item.dart';
import '../sample/floor_plan_sample.dart';

class FloorPlanViewModel extends ChangeNotifier {
  FloorPlanViewModel() : _fixtures = List.of(FloorPlanSample.defaultFixtures);

  final List<FixtureItem> _fixtures;
  String? _selectedFixtureId;
  String? _highlightedFixtureId;
  bool _isEditMode = false;

  List<FixtureItem> get fixtures => List.unmodifiable(_fixtures);
  String? get selectedFixtureId => _selectedFixtureId;
  String? get highlightedFixtureId => _highlightedFixtureId;
  bool get isEditMode => _isEditMode;

  FixtureItem? get selectedFixture {
    if (_selectedFixtureId == null) return null;
    try {
      return _fixtures.firstWhere((item) => item.id == _selectedFixtureId);
    } catch (_) {
      return null;
    }
  }

  void selectFixture(String? id) {
    if (_selectedFixtureId == id) {
      _selectedFixtureId = null;
    } else {
      _selectedFixtureId = id;
    }
    notifyListeners();
  }

  void highlightFixture(String? id) {
    _highlightedFixtureId = id;
    if (id != null) {
      _selectedFixtureId = id;
    }
    notifyListeners();
  }

  void clearHighlight() {
    _highlightedFixtureId = null;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    if (!_isEditMode) {
      _selectedFixtureId = null;
    }
    notifyListeners();
  }

  void setEditMode(bool enabled) {
    if (_isEditMode == enabled) return;
    _isEditMode = enabled;
    if (!_isEditMode) {
      _selectedFixtureId = null;
    }
    notifyListeners();
  }

  void updateFixturePosition(String id, double newX, double newY) {
    final index = _fixtures.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final fixture = _fixtures[index];
      final clampedX = newX.clamp(0.0, 1.0 - fixture.width);
      final clampedY = newY.clamp(0.0, 1.0 - fixture.height);
      _fixtures[index] = fixture.copyWith(x: clampedX, y: clampedY);
      notifyListeners();
    }
  }

  void rotateFixture(String id) {
    final index = _fixtures.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final fixture = _fixtures[index];
      final newRotation = (fixture.rotation + 90) % 360;
      _fixtures[index] = fixture.copyWith(rotation: newRotation);
      notifyListeners();
    }
  }

  /// Mengubah ukuran objek secara proporsional sebesar [delta] (relatif kanvas).
  ///
  /// Objek tetap berada di dalam batas kanvas dan tidak lebih kecil dari ukuran
  /// minimum agar tetap dapat disentuh.
  void resizeFixture(String id, {required double delta}) {
    final index = _fixtures.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    const minWidth = 0.1;
    const minHeight = 0.08;
    final fixture = _fixtures[index];
    final maxWidth = (1.0 - fixture.x).clamp(minWidth, 1.0);
    final maxHeight = (1.0 - fixture.y).clamp(minHeight, 1.0);
    _fixtures[index] = fixture.copyWith(
      width: (fixture.width + delta).clamp(minWidth, maxWidth),
      height: (fixture.height + delta).clamp(minHeight, maxHeight),
    );
    notifyListeners();
  }

  /// Menggandakan objek terpilih dengan salinan yang bergeser sedikit, lalu
  /// memilih salinan itu agar langsung dapat dipindahkan.
  void duplicateFixture(String id) {
    final index = _fixtures.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    const offset = 0.03;
    final fixture = _fixtures[index];
    final newId = 'fixture-${DateTime.now().microsecondsSinceEpoch}';
    _fixtures.add(
      fixture.copyWith(
        id: newId,
        name: '${fixture.name} (salinan)',
        x: (fixture.x + offset).clamp(0.0, 1.0 - fixture.width),
        y: (fixture.y + offset).clamp(0.0, 1.0 - fixture.height),
      ),
    );
    _selectedFixtureId = newId;
    notifyListeners();
  }

  void renameFixture(String id, String newName) {
    final index = _fixtures.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _fixtures[index] = _fixtures[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  void deleteFixture(String id) {
    _fixtures.removeWhere((item) => item.id == id);
    if (_selectedFixtureId == id) {
      _selectedFixtureId = null;
    }
    notifyListeners();
  }

  void addFixture({
    required FixtureType type,
    required String name,
    double width = 0.25,
    double height = 0.2,
  }) {
    final newId = 'fixture-${DateTime.now().millisecondsSinceEpoch}';
    _fixtures.add(
      FixtureItem(
        id: newId,
        name: name,
        type: type,
        x: 0.35,
        y: 0.4,
        width: width,
        height: height,
        productCount: 0,
      ),
    );
    _selectedFixtureId = newId;
    notifyListeners();
  }
}
