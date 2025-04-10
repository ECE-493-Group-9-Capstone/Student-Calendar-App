// Mocks generated by Mockito 5.4.5 from annotations
// in student_app/test/features/home_page_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;
import 'dart:typed_data' as _i6;

import 'package:cloud_firestore/cloud_firestore.dart' as _i2;
import 'package:flutter/material.dart' as _i7;
import 'package:mockito/mockito.dart' as _i1;
import 'package:student_app/services/firebase_service.dart' as _i4;
import 'package:student_app/utils/user_model.dart' as _i5;

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

class _FakeFirebaseFirestore_0 extends _i1.SmartFake
    implements _i2.FirebaseFirestore {
  _FakeFirebaseFirestore_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeStreamSubscription_1<T> extends _i1.SmartFake
    implements _i3.StreamSubscription<T> {
  _FakeStreamSubscription_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [FirebaseService].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirebaseService extends _i1.Mock implements _i4.FirebaseService {
  @override
  _i2.FirebaseFirestore get firestore =>
      (super.noSuchMethod(
            Invocation.getter(#firestore),
            returnValue: _FakeFirebaseFirestore_0(
              this,
              Invocation.getter(#firestore),
            ),
            returnValueForMissingStub: _FakeFirebaseFirestore_0(
              this,
              Invocation.getter(#firestore),
            ),
          )
          as _i2.FirebaseFirestore);

  @override
  _i3.Future<void> addUser(String? name, String? ccid, {String? photoURL}) =>
      (super.noSuchMethod(
            Invocation.method(#addUser, [name, ccid], {#photoURL: photoURL}),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> acceptFriendRequest(String? userId1, String? userId2) =>
      (super.noSuchMethod(
            Invocation.method(#acceptFriendRequest, [userId1, userId2]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> sendRecieveRequest(String? senderId, String? receiverId) =>
      (super.noSuchMethod(
            Invocation.method(#sendRecieveRequest, [senderId, receiverId]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> deleteUser(String? id) =>
      (super.noSuchMethod(
            Invocation.method(#deleteUser, [id]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<List<_i5.UserModel>> getAllUsers() =>
      (super.noSuchMethod(
            Invocation.method(#getAllUsers, []),
            returnValue: _i3.Future<List<_i5.UserModel>>.value(
              <_i5.UserModel>[],
            ),
            returnValueForMissingStub: _i3.Future<List<_i5.UserModel>>.value(
              <_i5.UserModel>[],
            ),
          )
          as _i3.Future<List<_i5.UserModel>>);

  @override
  _i3.Future<List<String>> getUserFriends(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#getUserFriends, [userId]),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
            returnValueForMissingStub: _i3.Future<List<String>>.value(
              <String>[],
            ),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<Map<String, dynamic>?> fetchUserData(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#fetchUserData, [userId]),
            returnValue: _i3.Future<Map<String, dynamic>?>.value(),
            returnValueForMissingStub:
                _i3.Future<Map<String, dynamic>?>.value(),
          )
          as _i3.Future<Map<String, dynamic>?>);

  @override
  _i3.Future<List<Map<String, dynamic>>> getFriendRequests(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#getFriendRequests, [userId]),
            returnValue: _i3.Future<List<Map<String, dynamic>>>.value(
              <Map<String, dynamic>>[],
            ),
            returnValueForMissingStub:
                _i3.Future<List<Map<String, dynamic>>>.value(
                  <Map<String, dynamic>>[],
                ),
          )
          as _i3.Future<List<Map<String, dynamic>>>);

  @override
  _i3.Future<List<String>> getRequestedFriends(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#getRequestedFriends, [userId]),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
            returnValueForMissingStub: _i3.Future<List<String>>.value(
              <String>[],
            ),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<void> declineFriendRequest(String? requesterId, String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#declineFriendRequest, [requesterId, userId]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> removeFriendFromUsers(String? userId1, String? userId2) =>
      (super.noSuchMethod(
            Invocation.method(#removeFriendFromUsers, [userId1, userId2]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> addUserSchedule(String? userId, String? scheduleContent) =>
      (super.noSuchMethod(
            Invocation.method(#addUserSchedule, [userId, scheduleContent]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> markPopupAsSeen(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#markPopupAsSeen, [userId]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> updateUserProfile(
    String? ccid, {
    String? discipline,
    String? educationLvl,
    String? degree,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #updateUserProfile,
              [ccid],
              {
                #discipline: discipline,
                #educationLvl: educationLvl,
                #degree: degree,
              },
            ),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> updateUserLocationPreference(
    String? ccid,
    String? trackingOption,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#updateUserLocationPreference, [
              ccid,
              trackingOption,
            ]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> updateUserLocation(
    String? ccid,
    double? latitude,
    double? longitude,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#updateUserLocation, [ccid, latitude, longitude]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> updateUserPhoto(String? ccid, String? photoURL) =>
      (super.noSuchMethod(
            Invocation.method(#updateUserPhoto, [ccid, photoURL]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> updateUserActiveStatus(String? ccid, bool? isActive) =>
      (super.noSuchMethod(
            Invocation.method(#updateUserActiveStatus, [ccid, isActive]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> uploadPhoneNumber(String? userId, String? phoneNumber) =>
      (super.noSuchMethod(
            Invocation.method(#uploadPhoneNumber, [userId, phoneNumber]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> uploadInstagramLink(String? userId, String? instagramUrl) =>
      (super.noSuchMethod(
            Invocation.method(#uploadInstagramLink, [userId, instagramUrl]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<_i6.Uint8List?> downloadImageBytes(String? photoURL) =>
      (super.noSuchMethod(
            Invocation.method(#downloadImageBytes, [photoURL]),
            returnValue: _i3.Future<_i6.Uint8List?>.value(),
            returnValueForMissingStub: _i3.Future<_i6.Uint8List?>.value(),
          )
          as _i3.Future<_i6.Uint8List?>);

  @override
  _i3.Future<void> initializeLastSeen(
    List<dynamic>? friends,
    _i7.ValueNotifier<Map<String, DateTime?>>? notifier,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#initializeLastSeen, [friends, notifier]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.StreamSubscription<dynamic> subscribeToFriendLocations(
    List<String>? friendIds,
    _i7.ValueNotifier<Map<String, DateTime?>>? notifier,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#subscribeToFriendLocations, [
              friendIds,
              notifier,
            ]),
            returnValue: _FakeStreamSubscription_1<dynamic>(
              this,
              Invocation.method(#subscribeToFriendLocations, [
                friendIds,
                notifier,
              ]),
            ),
            returnValueForMissingStub: _FakeStreamSubscription_1<dynamic>(
              this,
              Invocation.method(#subscribeToFriendLocations, [
                friendIds,
                notifier,
              ]),
            ),
          )
          as _i3.StreamSubscription<dynamic>);

  @override
  _i3.Future<void> toggleHideLocation(
    String? currentUserId,
    String? targetUserId,
    bool? shouldHide,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#toggleHideLocation, [
              currentUserId,
              targetUserId,
              shouldHide,
            ]),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<Set<String>> getHiddenFromMeList(String? userId) =>
      (super.noSuchMethod(
            Invocation.method(#getHiddenFromMeList, [userId]),
            returnValue: _i3.Future<Set<String>>.value(<String>{}),
            returnValueForMissingStub: _i3.Future<Set<String>>.value(
              <String>{},
            ),
          )
          as _i3.Future<Set<String>>);
}
