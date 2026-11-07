import 'package:flutter_test/flutter_test.dart';
import 'package:ryangunshop/core/session/app_session.dart';
import 'package:ryangunshop/core/session/user_role.dart';
import 'package:ryangunshop/features/checkout/model/cart_item.dart';

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

    test(
      'mencatat transaksi baru dan memperbarui omzet serta nota hari ini',
      () {
        final session = AppSession();
        final initialRevenue = session.todayRevenue;
        final initialCount = session.todayTransactionCount;
        var notified = false;
        session.addListener(() => notified = true);

        session.recordTransaction(
          totalAmount: 50000,
          items: const [
            CartItem(
              productId: 'prod-1',
              productName: 'Kopi Susu',
              unitPrice: 25000,
              quantity: 2,
              unit: 'btl',
            ),
          ],
          paymentMethod: 'Tunai',
          cashReceived: 100000,
          changeAmount: 50000,
        );

        expect(notified, isTrue);
        expect(session.todayRevenue, initialRevenue + 50000);
        expect(session.todayTransactionCount, initialCount + 1);
        expect(session.recentTransactions.first.title, 'Kopi Susu');
        expect(session.recentTransactions.first.amount, 50000);
        expect(session.recentTransactions.first.paymentMethod, 'Tunai');

        session.dispose();
      },
    );
  });
}
