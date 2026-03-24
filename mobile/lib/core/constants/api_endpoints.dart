/// Paths are relative to [RestClient] base URL, which must be the API root
/// (e.g. `http://host:8000/api`). Do not include `/api` again in each path.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Users (super_admin)
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // Shops (super_admin)
  static const String shops = '/shops';
  static String shopById(String id) => '/shops/$id';

  // Branches (owner)
  static const String branches = '/branches';
  static String branchById(String id) => '/branches/$id';

  // Staff (owner)
  static const String staff = '/staff';
  static String staffById(String id) => '/staff/$id';

  // Products / inventory
  static const String products = '/products';
  static String productById(String id) => '/products/$id';

  // Sales
  static const String sales = '/sales';
  static String saleById(String id) => '/sales/$id';

  // Shop settings (owner)
  static const String settings = '/settings';
}
