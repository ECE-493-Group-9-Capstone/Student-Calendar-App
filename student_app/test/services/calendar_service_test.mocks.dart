// Mocks generated by Mockito 5.4.5 from annotations
// in student_app/test/services/calendar_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:convert' as _i5;
import 'dart:typed_data' as _i7;

import 'package:googleapis/calendar/v3.dart' as _i3;
import 'package:http/http.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;
import 'package:student_app/services/calendar_service.dart' as _i8;

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

class _FakeResponse_0 extends _i1.SmartFake implements _i2.Response {
  _FakeResponse_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeStreamedResponse_1 extends _i1.SmartFake
    implements _i2.StreamedResponse {
  _FakeStreamedResponse_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeAclResource_2 extends _i1.SmartFake implements _i3.AclResource {
  _FakeAclResource_2(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeCalendarListResource_3 extends _i1.SmartFake
    implements _i3.CalendarListResource {
  _FakeCalendarListResource_3(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeCalendarsResource_4 extends _i1.SmartFake
    implements _i3.CalendarsResource {
  _FakeCalendarsResource_4(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeChannelsResource_5 extends _i1.SmartFake
    implements _i3.ChannelsResource {
  _FakeChannelsResource_5(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeColorsResource_6 extends _i1.SmartFake
    implements _i3.ColorsResource {
  _FakeColorsResource_6(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeEventsResource_7 extends _i1.SmartFake
    implements _i3.EventsResource {
  _FakeEventsResource_7(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFreebusyResource_8 extends _i1.SmartFake
    implements _i3.FreebusyResource {
  _FakeFreebusyResource_8(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeSettingsResource_9 extends _i1.SmartFake
    implements _i3.SettingsResource {
  _FakeSettingsResource_9(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeEvent_10 extends _i1.SmartFake implements _i3.Event {
  _FakeEvent_10(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeEvents_11 extends _i1.SmartFake implements _i3.Events {
  _FakeEvents_11(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeChannel_12 extends _i1.SmartFake implements _i3.Channel {
  _FakeChannel_12(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [Client].
///
/// See the documentation for Mockito's code generation for more information.
class MockClient extends _i1.Mock implements _i2.Client {
  MockClient() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.Response> head(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#head, [url], {#headers: headers}),
            returnValue: _i4.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(#head, [url], {#headers: headers}),
              ),
            ),
          )
          as _i4.Future<_i2.Response>);

  @override
  _i4.Future<_i2.Response> get(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#get, [url], {#headers: headers}),
            returnValue: _i4.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(#get, [url], {#headers: headers}),
              ),
            ),
          )
          as _i4.Future<_i2.Response>);

  @override
  _i4.Future<_i2.Response> post(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i5.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #post,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i4.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #post,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i4.Future<_i2.Response>);

  @override
  _i4.Future<_i2.Response> put(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i5.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #put,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i4.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #put,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i4.Future<_i2.Response>);

  @override
  _i4.Future<_i2.Response> patch(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i5.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #patch,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i4.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #patch,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i4.Future<_i2.Response>);

  @override
  _i4.Future<_i2.Response> delete(
    Uri? url, {
    Map<String, String>? headers,
    Object? body,
    _i5.Encoding? encoding,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #delete,
              [url],
              {#headers: headers, #body: body, #encoding: encoding},
            ),
            returnValue: _i4.Future<_i2.Response>.value(
              _FakeResponse_0(
                this,
                Invocation.method(
                  #delete,
                  [url],
                  {#headers: headers, #body: body, #encoding: encoding},
                ),
              ),
            ),
          )
          as _i4.Future<_i2.Response>);

  @override
  _i4.Future<String> read(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
            Invocation.method(#read, [url], {#headers: headers}),
            returnValue: _i4.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#read, [url], {#headers: headers}),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<_i7.Uint8List> readBytes(
    Uri? url, {
    Map<String, String>? headers,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#readBytes, [url], {#headers: headers}),
            returnValue: _i4.Future<_i7.Uint8List>.value(_i7.Uint8List(0)),
          )
          as _i4.Future<_i7.Uint8List>);

  @override
  _i4.Future<_i2.StreamedResponse> send(_i2.BaseRequest? request) =>
      (super.noSuchMethod(
            Invocation.method(#send, [request]),
            returnValue: _i4.Future<_i2.StreamedResponse>.value(
              _FakeStreamedResponse_1(
                this,
                Invocation.method(#send, [request]),
              ),
            ),
          )
          as _i4.Future<_i2.StreamedResponse>);

  @override
  void close() => super.noSuchMethod(
    Invocation.method(#close, []),
    returnValueForMissingStub: null,
  );
}

/// A class which mocks [CalendarApi].
///
/// See the documentation for Mockito's code generation for more information.
class MockCalendarApi extends _i1.Mock implements _i3.CalendarApi {
  MockCalendarApi() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.AclResource get acl =>
      (super.noSuchMethod(
            Invocation.getter(#acl),
            returnValue: _FakeAclResource_2(this, Invocation.getter(#acl)),
          )
          as _i3.AclResource);

  @override
  _i3.CalendarListResource get calendarList =>
      (super.noSuchMethod(
            Invocation.getter(#calendarList),
            returnValue: _FakeCalendarListResource_3(
              this,
              Invocation.getter(#calendarList),
            ),
          )
          as _i3.CalendarListResource);

  @override
  _i3.CalendarsResource get calendars =>
      (super.noSuchMethod(
            Invocation.getter(#calendars),
            returnValue: _FakeCalendarsResource_4(
              this,
              Invocation.getter(#calendars),
            ),
          )
          as _i3.CalendarsResource);

  @override
  _i3.ChannelsResource get channels =>
      (super.noSuchMethod(
            Invocation.getter(#channels),
            returnValue: _FakeChannelsResource_5(
              this,
              Invocation.getter(#channels),
            ),
          )
          as _i3.ChannelsResource);

  @override
  _i3.ColorsResource get colors =>
      (super.noSuchMethod(
            Invocation.getter(#colors),
            returnValue: _FakeColorsResource_6(
              this,
              Invocation.getter(#colors),
            ),
          )
          as _i3.ColorsResource);

  @override
  _i3.EventsResource get events =>
      (super.noSuchMethod(
            Invocation.getter(#events),
            returnValue: _FakeEventsResource_7(
              this,
              Invocation.getter(#events),
            ),
          )
          as _i3.EventsResource);

  @override
  _i3.FreebusyResource get freebusy =>
      (super.noSuchMethod(
            Invocation.getter(#freebusy),
            returnValue: _FakeFreebusyResource_8(
              this,
              Invocation.getter(#freebusy),
            ),
          )
          as _i3.FreebusyResource);

  @override
  _i3.SettingsResource get settings =>
      (super.noSuchMethod(
            Invocation.getter(#settings),
            returnValue: _FakeSettingsResource_9(
              this,
              Invocation.getter(#settings),
            ),
          )
          as _i3.SettingsResource);
}

/// A class which mocks [EventsResource].
///
/// See the documentation for Mockito's code generation for more information.
class MockEventsResource extends _i1.Mock implements _i3.EventsResource {
  MockEventsResource() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<void> delete(
    String? calendarId,
    String? eventId, {
    bool? sendNotifications,
    String? sendUpdates,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #delete,
              [calendarId, eventId],
              {
                #sendNotifications: sendNotifications,
                #sendUpdates: sendUpdates,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<_i3.Event> get(
    String? calendarId,
    String? eventId, {
    bool? alwaysIncludeEmail,
    int? maxAttendees,
    String? timeZone,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #get,
              [calendarId, eventId],
              {
                #alwaysIncludeEmail: alwaysIncludeEmail,
                #maxAttendees: maxAttendees,
                #timeZone: timeZone,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Event>.value(
              _FakeEvent_10(
                this,
                Invocation.method(
                  #get,
                  [calendarId, eventId],
                  {
                    #alwaysIncludeEmail: alwaysIncludeEmail,
                    #maxAttendees: maxAttendees,
                    #timeZone: timeZone,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Event>);

  @override
  _i4.Future<_i3.Event> import(
    _i3.Event? request,
    String? calendarId, {
    int? conferenceDataVersion,
    bool? supportsAttachments,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #import,
              [request, calendarId],
              {
                #conferenceDataVersion: conferenceDataVersion,
                #supportsAttachments: supportsAttachments,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Event>.value(
              _FakeEvent_10(
                this,
                Invocation.method(
                  #import,
                  [request, calendarId],
                  {
                    #conferenceDataVersion: conferenceDataVersion,
                    #supportsAttachments: supportsAttachments,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Event>);

  @override
  _i4.Future<_i3.Event> insert(
    _i3.Event? request,
    String? calendarId, {
    int? conferenceDataVersion,
    int? maxAttendees,
    bool? sendNotifications,
    String? sendUpdates,
    bool? supportsAttachments,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #insert,
              [request, calendarId],
              {
                #conferenceDataVersion: conferenceDataVersion,
                #maxAttendees: maxAttendees,
                #sendNotifications: sendNotifications,
                #sendUpdates: sendUpdates,
                #supportsAttachments: supportsAttachments,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Event>.value(
              _FakeEvent_10(
                this,
                Invocation.method(
                  #insert,
                  [request, calendarId],
                  {
                    #conferenceDataVersion: conferenceDataVersion,
                    #maxAttendees: maxAttendees,
                    #sendNotifications: sendNotifications,
                    #sendUpdates: sendUpdates,
                    #supportsAttachments: supportsAttachments,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Event>);

  @override
  _i4.Future<_i3.Events> instances(
    String? calendarId,
    String? eventId, {
    bool? alwaysIncludeEmail,
    int? maxAttendees,
    int? maxResults,
    String? originalStart,
    String? pageToken,
    bool? showDeleted,
    DateTime? timeMax,
    DateTime? timeMin,
    String? timeZone,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #instances,
              [calendarId, eventId],
              {
                #alwaysIncludeEmail: alwaysIncludeEmail,
                #maxAttendees: maxAttendees,
                #maxResults: maxResults,
                #originalStart: originalStart,
                #pageToken: pageToken,
                #showDeleted: showDeleted,
                #timeMax: timeMax,
                #timeMin: timeMin,
                #timeZone: timeZone,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Events>.value(
              _FakeEvents_11(
                this,
                Invocation.method(
                  #instances,
                  [calendarId, eventId],
                  {
                    #alwaysIncludeEmail: alwaysIncludeEmail,
                    #maxAttendees: maxAttendees,
                    #maxResults: maxResults,
                    #originalStart: originalStart,
                    #pageToken: pageToken,
                    #showDeleted: showDeleted,
                    #timeMax: timeMax,
                    #timeMin: timeMin,
                    #timeZone: timeZone,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Events>);

  @override
  _i4.Future<_i3.Events> list(
    String? calendarId, {
    bool? alwaysIncludeEmail,
    List<String>? eventTypes,
    String? iCalUID,
    int? maxAttendees,
    int? maxResults,
    String? orderBy,
    String? pageToken,
    List<String>? privateExtendedProperty,
    String? q,
    List<String>? sharedExtendedProperty,
    bool? showDeleted,
    bool? showHiddenInvitations,
    bool? singleEvents,
    String? syncToken,
    DateTime? timeMax,
    DateTime? timeMin,
    String? timeZone,
    DateTime? updatedMin,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #list,
              [calendarId],
              {
                #alwaysIncludeEmail: alwaysIncludeEmail,
                #eventTypes: eventTypes,
                #iCalUID: iCalUID,
                #maxAttendees: maxAttendees,
                #maxResults: maxResults,
                #orderBy: orderBy,
                #pageToken: pageToken,
                #privateExtendedProperty: privateExtendedProperty,
                #q: q,
                #sharedExtendedProperty: sharedExtendedProperty,
                #showDeleted: showDeleted,
                #showHiddenInvitations: showHiddenInvitations,
                #singleEvents: singleEvents,
                #syncToken: syncToken,
                #timeMax: timeMax,
                #timeMin: timeMin,
                #timeZone: timeZone,
                #updatedMin: updatedMin,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Events>.value(
              _FakeEvents_11(
                this,
                Invocation.method(
                  #list,
                  [calendarId],
                  {
                    #alwaysIncludeEmail: alwaysIncludeEmail,
                    #eventTypes: eventTypes,
                    #iCalUID: iCalUID,
                    #maxAttendees: maxAttendees,
                    #maxResults: maxResults,
                    #orderBy: orderBy,
                    #pageToken: pageToken,
                    #privateExtendedProperty: privateExtendedProperty,
                    #q: q,
                    #sharedExtendedProperty: sharedExtendedProperty,
                    #showDeleted: showDeleted,
                    #showHiddenInvitations: showHiddenInvitations,
                    #singleEvents: singleEvents,
                    #syncToken: syncToken,
                    #timeMax: timeMax,
                    #timeMin: timeMin,
                    #timeZone: timeZone,
                    #updatedMin: updatedMin,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Events>);

  @override
  _i4.Future<_i3.Event> move(
    String? calendarId,
    String? eventId,
    String? destination, {
    bool? sendNotifications,
    String? sendUpdates,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #move,
              [calendarId, eventId, destination],
              {
                #sendNotifications: sendNotifications,
                #sendUpdates: sendUpdates,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Event>.value(
              _FakeEvent_10(
                this,
                Invocation.method(
                  #move,
                  [calendarId, eventId, destination],
                  {
                    #sendNotifications: sendNotifications,
                    #sendUpdates: sendUpdates,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Event>);

  @override
  _i4.Future<_i3.Event> patch(
    _i3.Event? request,
    String? calendarId,
    String? eventId, {
    bool? alwaysIncludeEmail,
    int? conferenceDataVersion,
    int? maxAttendees,
    bool? sendNotifications,
    String? sendUpdates,
    bool? supportsAttachments,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #patch,
              [request, calendarId, eventId],
              {
                #alwaysIncludeEmail: alwaysIncludeEmail,
                #conferenceDataVersion: conferenceDataVersion,
                #maxAttendees: maxAttendees,
                #sendNotifications: sendNotifications,
                #sendUpdates: sendUpdates,
                #supportsAttachments: supportsAttachments,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Event>.value(
              _FakeEvent_10(
                this,
                Invocation.method(
                  #patch,
                  [request, calendarId, eventId],
                  {
                    #alwaysIncludeEmail: alwaysIncludeEmail,
                    #conferenceDataVersion: conferenceDataVersion,
                    #maxAttendees: maxAttendees,
                    #sendNotifications: sendNotifications,
                    #sendUpdates: sendUpdates,
                    #supportsAttachments: supportsAttachments,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Event>);

  @override
  _i4.Future<_i3.Event> quickAdd(
    String? calendarId,
    String? text, {
    bool? sendNotifications,
    String? sendUpdates,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #quickAdd,
              [calendarId, text],
              {
                #sendNotifications: sendNotifications,
                #sendUpdates: sendUpdates,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Event>.value(
              _FakeEvent_10(
                this,
                Invocation.method(
                  #quickAdd,
                  [calendarId, text],
                  {
                    #sendNotifications: sendNotifications,
                    #sendUpdates: sendUpdates,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Event>);

  @override
  _i4.Future<_i3.Event> update(
    _i3.Event? request,
    String? calendarId,
    String? eventId, {
    bool? alwaysIncludeEmail,
    int? conferenceDataVersion,
    int? maxAttendees,
    bool? sendNotifications,
    String? sendUpdates,
    bool? supportsAttachments,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #update,
              [request, calendarId, eventId],
              {
                #alwaysIncludeEmail: alwaysIncludeEmail,
                #conferenceDataVersion: conferenceDataVersion,
                #maxAttendees: maxAttendees,
                #sendNotifications: sendNotifications,
                #sendUpdates: sendUpdates,
                #supportsAttachments: supportsAttachments,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Event>.value(
              _FakeEvent_10(
                this,
                Invocation.method(
                  #update,
                  [request, calendarId, eventId],
                  {
                    #alwaysIncludeEmail: alwaysIncludeEmail,
                    #conferenceDataVersion: conferenceDataVersion,
                    #maxAttendees: maxAttendees,
                    #sendNotifications: sendNotifications,
                    #sendUpdates: sendUpdates,
                    #supportsAttachments: supportsAttachments,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Event>);

  @override
  _i4.Future<_i3.Channel> watch(
    _i3.Channel? request,
    String? calendarId, {
    bool? alwaysIncludeEmail,
    List<String>? eventTypes,
    String? iCalUID,
    int? maxAttendees,
    int? maxResults,
    String? orderBy,
    String? pageToken,
    List<String>? privateExtendedProperty,
    String? q,
    List<String>? sharedExtendedProperty,
    bool? showDeleted,
    bool? showHiddenInvitations,
    bool? singleEvents,
    String? syncToken,
    DateTime? timeMax,
    DateTime? timeMin,
    String? timeZone,
    DateTime? updatedMin,
    String? $fields,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #watch,
              [request, calendarId],
              {
                #alwaysIncludeEmail: alwaysIncludeEmail,
                #eventTypes: eventTypes,
                #iCalUID: iCalUID,
                #maxAttendees: maxAttendees,
                #maxResults: maxResults,
                #orderBy: orderBy,
                #pageToken: pageToken,
                #privateExtendedProperty: privateExtendedProperty,
                #q: q,
                #sharedExtendedProperty: sharedExtendedProperty,
                #showDeleted: showDeleted,
                #showHiddenInvitations: showHiddenInvitations,
                #singleEvents: singleEvents,
                #syncToken: syncToken,
                #timeMax: timeMax,
                #timeMin: timeMin,
                #timeZone: timeZone,
                #updatedMin: updatedMin,
                #$fields: $fields,
              },
            ),
            returnValue: _i4.Future<_i3.Channel>.value(
              _FakeChannel_12(
                this,
                Invocation.method(
                  #watch,
                  [request, calendarId],
                  {
                    #alwaysIncludeEmail: alwaysIncludeEmail,
                    #eventTypes: eventTypes,
                    #iCalUID: iCalUID,
                    #maxAttendees: maxAttendees,
                    #maxResults: maxResults,
                    #orderBy: orderBy,
                    #pageToken: pageToken,
                    #privateExtendedProperty: privateExtendedProperty,
                    #q: q,
                    #sharedExtendedProperty: sharedExtendedProperty,
                    #showDeleted: showDeleted,
                    #showHiddenInvitations: showHiddenInvitations,
                    #singleEvents: singleEvents,
                    #syncToken: syncToken,
                    #timeMax: timeMax,
                    #timeMin: timeMin,
                    #timeZone: timeZone,
                    #updatedMin: updatedMin,
                    #$fields: $fields,
                  },
                ),
              ),
            ),
          )
          as _i4.Future<_i3.Channel>);
}

/// A class which mocks [CalendarService].
///
/// See the documentation for Mockito's code generation for more information.
class MockCalendarService extends _i1.Mock implements _i8.CalendarService {
  MockCalendarService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<List<_i3.Event>> fetchCalendarEvents(String? accessToken) =>
      (super.noSuchMethod(
            Invocation.method(#fetchCalendarEvents, [accessToken]),
            returnValue: _i4.Future<List<_i3.Event>>.value(<_i3.Event>[]),
          )
          as _i4.Future<List<_i3.Event>>);

  @override
  _i4.Future<List<_i3.Event>> fetchTodayCalendarEvents(String? accessToken) =>
      (super.noSuchMethod(
            Invocation.method(#fetchTodayCalendarEvents, [accessToken]),
            returnValue: _i4.Future<List<_i3.Event>>.value(<_i3.Event>[]),
          )
          as _i4.Future<List<_i3.Event>>);
}
