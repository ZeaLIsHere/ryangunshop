/// Data contoh untuk layar Statistik.
///
/// Seluruh angka di sini adalah contoh statis; perhitungan nyata menunggu lapisan
/// data. Layar wajib menandainya sebagai data contoh.
enum StatisticsPeriod {
  today('Hari ini'),
  week('7 hari'),
  month('30 hari');

  const StatisticsPeriod(this.label);

  final String label;
}

/// Himpunan angka statistik untuk satu periode.
class StatisticsDataSet {
  const StatisticsDataSet({
    required this.total,
    required this.previousTotal,
    required this.transactions,
    required this.itemsSold,
    required this.grossProfit,
    required this.payments,
    required this.peakTitle,
    required this.peakHours,
    required this.trendTitle,
    required this.trend,
    required this.topProducts,
    required this.slowMoving,
  });

  final int total;
  final int previousTotal;
  final int transactions;
  final int itemsSold;

  /// Laba kotor contoh (omzet dikurangi modal).
  final int grossProfit;

  final List<PaymentSlice> payments;
  final String peakTitle;
  final List<HourBucket> peakHours;
  final String trendTitle;
  final List<SalesPoint> trend;
  final List<TopProduct> topProducts;
  final List<TopProduct> slowMoving;

  int get average => transactions == 0 ? 0 : total ~/ transactions;

  double get changePercent {
    if (previousTotal == 0) {
      return 0;
    }
    return (total - previousTotal) / previousTotal * 100;
  }

  double get marginPercent => total == 0 ? 0 : grossProfit / total * 100;
}

abstract final class StatisticsSample {
  static const List<SalesPoint> _weekTrend = <SalesPoint>[
    SalesPoint(label: 'Sen', total: 120000),
    SalesPoint(label: 'Sel', total: 145000),
    SalesPoint(label: 'Rab', total: 98000),
    SalesPoint(label: 'Kam', total: 210000),
    SalesPoint(label: 'Jum', total: 165000),
    SalesPoint(label: 'Sab', total: 190000),
    SalesPoint(label: 'Min', total: 175000),
  ];

  static const List<SalesPoint> _monthTrend = <SalesPoint>[
    SalesPoint(label: 'Mg 1', total: 980000),
    SalesPoint(label: 'Mg 2', total: 1120000),
    SalesPoint(label: 'Mg 3', total: 1040000),
    SalesPoint(label: 'Mg 4', total: 1180000),
  ];

  static const Map<StatisticsPeriod, StatisticsDataSet>
  _byPeriod = <StatisticsPeriod, StatisticsDataSet>{
    StatisticsPeriod.today: StatisticsDataSet(
      total: 175000,
      previousTotal: 156000,
      transactions: 3,
      itemsSold: 42,
      grossProfit: 54250,
      payments: <PaymentSlice>[
        PaymentSlice(label: 'Tunai', total: 105000),
        PaymentSlice(label: 'QRIS', total: 70000),
      ],
      peakTitle: 'Jam sibuk (hari ini)',
      peakHours: <HourBucket>[
        HourBucket(label: '08', transactions: 2),
        HourBucket(label: '12', transactions: 5),
        HourBucket(label: '15', transactions: 3),
        HourBucket(label: '18', transactions: 6),
        HourBucket(label: '20', transactions: 4),
      ],
      trendTitle: 'Tren 7 hari terakhir',
      trend: _weekTrend,
      topProducts: <TopProduct>[
        TopProduct(name: 'Mi instan goreng', sold: 18, unit: 'bungkus'),
        TopProduct(name: 'Air mineral 600 ml', sold: 15, unit: 'botol'),
        TopProduct(name: 'Beras pandan wangi 1 kg', sold: 12, unit: 'bungkus'),
        TopProduct(name: 'Minyak goreng 1 liter', sold: 7, unit: 'botol'),
      ],
      slowMoving: <TopProduct>[
        TopProduct(name: 'Sabun mandi batang', sold: 1, unit: 'pcs'),
        TopProduct(name: 'Deterjen bubuk 800 gr', sold: 2, unit: 'bungkus'),
      ],
    ),
    StatisticsPeriod.week: StatisticsDataSet(
      total: 1103000,
      previousTotal: 980000,
      transactions: 24,
      itemsSold: 310,
      grossProfit: 342000,
      payments: <PaymentSlice>[
        PaymentSlice(label: 'Tunai', total: 660000),
        PaymentSlice(label: 'QRIS', total: 443000),
      ],
      peakTitle: 'Jam sibuk (7 hari)',
      peakHours: <HourBucket>[
        HourBucket(label: '08', transactions: 14),
        HourBucket(label: '12', transactions: 32),
        HourBucket(label: '15', transactions: 20),
        HourBucket(label: '18', transactions: 38),
        HourBucket(label: '20', transactions: 26),
      ],
      trendTitle: 'Tren 7 hari terakhir',
      trend: _weekTrend,
      topProducts: <TopProduct>[
        TopProduct(name: 'Mi instan goreng', sold: 126, unit: 'bungkus'),
        TopProduct(name: 'Air mineral 600 ml', sold: 105, unit: 'botol'),
        TopProduct(name: 'Beras pandan wangi 1 kg', sold: 84, unit: 'bungkus'),
        TopProduct(name: 'Minyak goreng 1 liter', sold: 49, unit: 'botol'),
      ],
      slowMoving: <TopProduct>[
        TopProduct(name: 'Sabun mandi batang', sold: 6, unit: 'pcs'),
        TopProduct(name: 'Deterjen bubuk 800 gr', sold: 9, unit: 'bungkus'),
      ],
    ),
    StatisticsPeriod.month: StatisticsDataSet(
      total: 4320000,
      previousTotal: 3980000,
      transactions: 96,
      itemsSold: 1240,
      grossProfit: 1340000,
      payments: <PaymentSlice>[
        PaymentSlice(label: 'Tunai', total: 2590000),
        PaymentSlice(label: 'QRIS', total: 1730000),
      ],
      peakTitle: 'Jam sibuk (30 hari)',
      peakHours: <HourBucket>[
        HourBucket(label: '08', transactions: 52),
        HourBucket(label: '12', transactions: 120),
        HourBucket(label: '15', transactions: 74),
        HourBucket(label: '18', transactions: 150),
        HourBucket(label: '20', transactions: 96),
      ],
      trendTitle: 'Tren 4 minggu terakhir',
      trend: _monthTrend,
      topProducts: <TopProduct>[
        TopProduct(name: 'Mi instan goreng', sold: 486, unit: 'bungkus'),
        TopProduct(name: 'Air mineral 600 ml', sold: 420, unit: 'botol'),
        TopProduct(name: 'Beras pandan wangi 1 kg', sold: 360, unit: 'bungkus'),
        TopProduct(name: 'Minyak goreng 1 liter', sold: 210, unit: 'botol'),
      ],
      slowMoving: <TopProduct>[
        TopProduct(name: 'Sabun mandi batang', sold: 24, unit: 'pcs'),
        TopProduct(name: 'Deterjen bubuk 800 gr', sold: 31, unit: 'bungkus'),
      ],
    ),
  };

  static StatisticsDataSet forPeriod(StatisticsPeriod period) =>
      _byPeriod[period]!;
}

/// Satu titik penjualan harian atau mingguan.
class SalesPoint {
  const SalesPoint({required this.label, required this.total});

  final String label;
  final int total;
}

/// Satu produk terlaris atau lambat laku.
class TopProduct {
  const TopProduct({
    required this.name,
    required this.sold,
    required this.unit,
  });

  final String name;
  final int sold;
  final String unit;
}

/// Sebaran satu metode pembayaran.
class PaymentSlice {
  const PaymentSlice({required this.label, required this.total});

  final String label;
  final int total;
}

/// Jumlah transaksi pada satu jam.
class HourBucket {
  const HourBucket({required this.label, required this.transactions});

  final String label;
  final int transactions;
}
