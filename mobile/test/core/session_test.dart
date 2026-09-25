import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';

void main() {
  group('UserRole', () {
    test('hanya pemilik yang boleh membuka mode edit denah', () {
      expect(UserRole.owner.canEditFloorPlan, isTrue);
      expect(UserRole.cashier.canEditFloorPlan, isFalse);
    });
  });

  group('AppSession', () {
    test('memulai sebagai pemilik', () {
      final session = AppSession();

      expect(session.role, UserRole.owner);
      expect(session.canEditFloorPlan, isTrue);

      session.dispose();
    });

    test('memberi tahu pendengar saat peran berganti', () {
      final session = AppSession();
      var notifications = 0;
      session.addListener(() => notifications++);

      session.selectRole(UserRole.cashier);
      expect(session.role, UserRole.cashier);
      expect(session.canEditFloorPlan, isFalse);
      expect(notifications, 1);

      session.selectRole(UserRole.cashier);
      expect(
        notifications,
        1,
        reason: 'peran yang sama tidak memicu perubahan',
      );

      session.dispose();
    });
  });
}
