import '../../domain/entities/auth_user.dart';
import '../../domain/entities/branch_access.dart';
import '../../domain/entities/tenant_access.dart';

class LoginResponseModel {
  LoginResponseModel({
    required this.accessToken,
    required this.user,
    required this.tenants,
    this.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final tenantsRaw = json['tenants'];
    final tenantsList = tenantsRaw is List
        ? tenantsRaw
            .whereType<Map<String, dynamic>>()
            .map(TenantAccessModel.fromJson)
            .toList()
        : <TenantAccess>[];

    return LoginResponseModel(
      accessToken: (json['accessToken'] ?? json['token']) as String,
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      tenants: tenantsList,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  final String accessToken;
  final String? refreshToken;
  final AuthUser user;
  final List<TenantAccess> tenants;
}

class AuthUserModel {
  static AuthUser fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'usuario',
    );
  }
}

class TenantAccessModel {
  static TenantAccess fromJson(Map<String, dynamic> json) {
    final branchesRaw = json['branches'];
    final branches = branchesRaw is List
        ? branchesRaw
            .whereType<Map<String, dynamic>>()
            .map(BranchAccessModel.fromJson)
            .toList()
        : <BranchAccess>[];

    return TenantAccess(
      id: '${json['id']}',
      companyName: json['companyName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      branches: branches,
    );
  }
}

class BranchAccessModel {
  static BranchAccess fromJson(Map<String, dynamic> json) {
    return BranchAccess(
      id: '${json['id']}',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
