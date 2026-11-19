import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/data/monitor_layout_repository.dart';
import '../../../core/data/product_record.dart';
import '../model/monitor_layout.dart';

class MonitorViewModel extends ChangeNotifier {
  MonitorViewModel({
    required this.loadLayout,
    required this.saveLayout,
    required this.canEdit,
    this.loadProducts,
  });

  final Future<List<ProductRecord>> Function()? loadProducts;
  List<ProductRecord> products = [];
  String? productsError;
  int _productsRequest = 0;
  Future<void> refreshProducts() async {
    if (loadProducts == null) return;
    final request = ++_productsRequest;
    try {
      final data = await loadProducts!();
      if (_disposed || request != _productsRequest) return;
      products = data;
      productsError = null;
    } catch (_) {
      if (_disposed || request != _productsRequest) return;
      productsError = 'Stok gagal dimuat. Coba muat ulang.';
    }
    _notify();
  }

  List<ProductRecord> productsAt(String? fixtureId) => products.where((p) {
    final id = layout?.assignments[p.id];
    return fixtureId == null ? id == null : id == fixtureId;
  }).toList();

  ({int low, int out}) counts(String? fixtureId) {
    final items = fixtureId == null ? products : productsAt(fixtureId);
    return (
      low: items
          .where((p) => p.stock > 0 && p.stock <= p.lowStockThreshold)
          .length,
      out: items.where((p) => p.stock == 0).length,
    );
  }

  void assign(Map<String, String> assignments) {
    if (!canEdit() || !editing || saving || conflict || draft == null) return;
    try {
      draft = draft!.copyWith(assignments: assignments);
      error = null;
    } on FormatException catch (e) {
      error = e.message.toString();
    }
    _notify();
  }

  final Future<StoredMonitorLayout?> Function() loadLayout;
  final Future<StoredMonitorLayout> Function(MonitorLayout, int) saveLayout;
  final bool Function() canEdit;
  StoredMonitorLayout? _stored;
  MonitorLayout? draft;
  String? selectedId;
  String? error;
  bool loading = true;
  bool saving = false;
  bool editing = false;
  bool conflict = false;
  bool _disposed = false;
  int _sequence = 0;

  MonitorLayout? get layout => draft ?? _stored?.layout;
  bool get dirty =>
      editing &&
      jsonEncode(draft?.toJson()) != jsonEncode(_stored?.layout.toJson());
  MonitorFixture? get selected {
    for (final fixture in layout?.fixtures ?? <MonitorFixture>[]) {
      if (fixture.id == selectedId) return fixture;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (saving || (editing && dirty)) return;
    loading = true;
    error = null;
    _notify();
    try {
      final stored = await loadLayout();
      await refreshProducts();
      if (_disposed) return;
      _stored = stored;
      draft = null;
      editing = false;
      selectedId = null;
      conflict = false;
    } catch (_) {
      if (!_disposed) {
        error = 'Tata letak gagal dimuat. Coba lagi; data tidak dihapus.';
      }
    } finally {
      loading = false;
      _notify();
    }
  }

  void chooseTemplate(MonitorTemplate template) {
    if (!canEdit() || saving || loading || _stored != null) return;
    draft = template.create();
    editing = true;
    selectedId = null;
    error = null;
    _notify();
  }

  void edit() {
    if (!canEdit() || saving || loading || _stored == null) return;
    draft = _stored!.layout;
    editing = true;
    error = null;
    _notify();
  }

  void cancel() {
    if (saving) return;
    draft = null;
    editing = false;
    selectedId = null;
    error = null;
    conflict = false;
    _notify();
  }

  void select(String id) {
    if (saving) return;
    selectedId = id;
    _notify();
  }

  bool _replace(Iterable<MonitorFixture> fixtures) {
    if (!canEdit() || !editing || saving || conflict || draft == null) {
      return false;
    }
    try {
      final list = fixtures.toList();
      draft = draft!.copyWith(
        fixtures: list,
        assignments: {
          for (final entry in draft!.assignments.entries)
            if (list.any((f) => f.id == entry.value)) entry.key: entry.value,
        },
      );
      error = null;
      _notify();
      return true;
    } on FormatException catch (e) {
      error = e.message.toString();
      _notify();
      return false;
    }
  }

  bool change({String? name, int dx = 0, int dy = 0, bool rotate = false}) {
    final fixture = selected;
    if (fixture == null || draft == null) return false;
    try {
      final replacement = fixture.copyWith(
        name: name,
        x: fixture.x + dx,
        y: fixture.y + dy,
        quarterTurns: rotate
            ? (fixture.quarterTurns + 1) % 4
            : fixture.quarterTurns,
      );
      return _replace(
        draft!.fixtures.map((f) => f.id == fixture.id ? replacement : f),
      );
    } on FormatException catch (e) {
      error = e.message.toString();
      _notify();
      return false;
    }
  }

  void add(MonitorFixtureType type) {
    if (!canEdit() || !editing || saving || conflict || draft == null) return;
    for (var y = 0; y <= draft!.gridHeight - type.height; y++) {
      for (var x = 0; x <= draft!.gridWidth - type.width; x++) {
        final id =
            'object_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
        final fixture = MonitorFixture(
          id: id,
          type: type,
          name: type.label,
          x: x,
          y: y,
        );
        try {
          final next = draft!.copyWith(fixtures: [...draft!.fixtures, fixture]);
          draft = next;
          selectedId = id;
          error = null;
          _notify();
          return;
        } on FormatException {
          /* Coba sel berikutnya yang tidak bertumpuk. */
        }
      }
    }
    error =
        'Tidak ada ruang kosong untuk ${type.label.toLowerCase()}. Pindahkan atau hapus objek lain.';
    _notify();
  }

  void remove() {
    final id = selectedId;
    if (id == null || draft == null) return;
    if (_replace(draft!.fixtures.where((f) => f.id != id))) {
      selectedId = null;
      _notify();
    }
  }

  Future<bool> save() async {
    if (!canEdit() ||
        saving ||
        loading ||
        !editing ||
        draft == null ||
        conflict) {
      return false;
    }
    saving = true;
    error = null;
    _notify();
    try {
      if (loadProducts != null) {
        await refreshProducts();
        if (productsError != null) throw StateError(productsError!);
        draft = draft!.copyWith(
          assignments: {
            for (final entry in draft!.assignments.entries)
              if (products.any((p) => p.id == entry.key))
                entry.key: entry.value,
          },
        );
      }
      if (!canEdit()) return false;
      final saved = await saveLayout(draft!, _stored?.revision ?? 0);
      if (_disposed) return false;
      _stored = saved;
      draft = null;
      editing = false;
      selectedId = null;
      await refreshProducts();
      return true;
    } on MonitorLayoutConflict {
      conflict = true;
      error = 'Tata letak berubah di tempat lain. Draft tetap ada. Batalkan edit lalu muat ulang sebelum mencoba lagi.';
      return false;
    } catch (_) {
      if (!_disposed) error = 'Tata letak belum tersimpan. Draft tetap ada; periksa penempatan dan coba lagi.';
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
