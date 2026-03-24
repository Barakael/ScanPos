import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/analytics_entity.dart';

part 'analytics_model.g.dart';

@JsonSerializable()
class AnalyticsModel {
  final int totalSales;
  final double totalRevenue;
  final int totalCustomers;
  final int totalProducts;
  final double averageOrderValue;
  final List<DailySalesModel> dailySales;

  /// Filled when mapping from `GET /api/dashboard` (not from generic JSON).
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? todayTransactions;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final double? todayTotalRevenue;

  const AnalyticsModel({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalCustomers,
    required this.totalProducts,
    required this.averageOrderValue,
    required this.dailySales,
    this.todayTransactions,
    this.todayTotalRevenue,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsModelFromJson(json);

  /// Laravel [DashboardController@index] payload.
  factory AnalyticsModel.fromDashboardJson(Map<String, dynamic> json) {
    final weekly = json['weekly_sales'] as List<dynamic>? ?? [];
    final dailySales = weekly.map((e) {
      final m = e as Map<String, dynamic>;
      return DailySalesModel(
        date: m['date']?.toString() ?? '',
        count: (m['transactions'] as num?)?.toInt() ?? 0,
        revenue: (m['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final todayTx = (json['today_transactions'] as num?)?.toInt() ?? 0;
    final todayTotal = (json['today_total'] as num?)?.toDouble() ?? 0.0;
    final products = (json['total_products'] as num?)?.toInt() ?? 0;

    return AnalyticsModel(
      totalSales: todayTx,
      totalRevenue: todayTotal,
      totalCustomers: 0,
      totalProducts: products,
      averageOrderValue: todayTx > 0 ? todayTotal / todayTx : 0.0,
      dailySales: dailySales,
      todayTransactions: todayTx,
      todayTotalRevenue: todayTotal,
    );
  }

  Map<String, dynamic> toJson() => _$AnalyticsModelToJson(this);

  AnalyticsEntity toEntity() => AnalyticsEntity(
        totalSales: totalSales,
        totalRevenue: totalRevenue,
        totalCustomers: totalCustomers,
        totalProducts: totalProducts,
        averageOrderValue: averageOrderValue,
        dailySales: dailySales.map((d) => d.toEntity()).toList(),
        todaySales: todayTransactions,
        todayRevenue: todayTotalRevenue,
      );
}

@JsonSerializable()
class DailySalesModel {
  final String date;
  final int count;
  final double revenue;

  const DailySalesModel({
    required this.date,
    required this.count,
    required this.revenue,
  });

  factory DailySalesModel.fromJson(Map<String, dynamic> json) =>
      _$DailySalesModelFromJson(json);
  Map<String, dynamic> toJson() => _$DailySalesModelToJson(this);

  DailySalesEntity toEntity() =>
      DailySalesEntity(date: date, count: count, revenue: revenue);
}
