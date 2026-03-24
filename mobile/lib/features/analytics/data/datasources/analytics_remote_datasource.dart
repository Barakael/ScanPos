import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/analytics_model.dart';

class AnalyticsRemoteDataSource {
  final ApiClient apiClient;
  const AnalyticsRemoteDataSource({required this.apiClient});

  Future<AnalyticsModel> getAnalytics() =>
      apiClient.get<AnalyticsModel>(
        endpoint: ApiEndpoints.dashboard,
        parser: (json) => AnalyticsModel.fromDashboardJson(
          json as Map<String, dynamic>,
        ),
      );
}
