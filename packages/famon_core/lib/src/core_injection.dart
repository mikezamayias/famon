// ignore_for_file: unused_import
import 'package:famon_core/src/core_injection.module.dart';
import 'package:injectable/injectable.dart';

/// Micro-package module annotation target.
///
/// This generates [FamonCorePackageModule] in `core_injection.module.dart`,
/// which is consumed by the CLI package's `@InjectableInit` to register
/// all core services.
@InjectableInit.microPackage()
void initFamonCore() {}
