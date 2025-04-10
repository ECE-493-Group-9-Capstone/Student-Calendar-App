// Mocks generated by Mockito 5.4.5 from annotations
// in student_app/test/services/map_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:student_app/services/map_service.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [MapService].
///
/// See the documentation for Mockito's code generation for more information.
class MockMapService extends _i1.Mock implements _i2.MapService {
  MockMapService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<void> startLiveTracking() =>
      (super.noSuchMethod(
            Invocation.method(#startLiveTracking, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> startForegroundTracking() =>
      (super.noSuchMethod(
            Invocation.method(#startForegroundTracking, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  void stopTracking() => super.noSuchMethod(
    Invocation.method(#stopTracking, []),
    returnValueForMissingStub: null,
  );
}
