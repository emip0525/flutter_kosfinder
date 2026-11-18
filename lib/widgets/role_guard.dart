import 'package:flutter/material.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.role,
    required this.allowed,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final String role;
  final List<String> allowed;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return allowed.contains(role) ? child : fallback;
  }
}
