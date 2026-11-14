import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicemail/data/services/app_permission_service.dart';
import 'package:voicemail/domain/services/permission_service.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return AppPermissionService();
});

