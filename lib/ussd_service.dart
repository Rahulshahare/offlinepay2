import 'dart:async';
import 'package:flutter/services.dart';

// ── SIM Slot model ────────────────────────────────────────────────────────────
class SimSlot {
  final int subscriptionId;
  final int simSlotIndex;
  final String displayName;
  final String carrierName;
  final String number;

  SimSlot({
    required this.subscriptionId,
    required this.simSlotIndex,
    required this.displayName,
    required this.carrierName,
    required this.number,
  });

  factory SimSlot.fromMap(Map map) => SimSlot(
        subscriptionId: map['subscriptionId'] as int,
        simSlotIndex: map['simSlotIndex'] as int,
        displayName: map['displayName'] as String,
        carrierName: map['carrierName'] as String,
        number: map['number'] as String,
      );

  @override
  String toString() => '$displayName ($carrierName)';
}

// ── My Details model ──────────────────────────────────────────────────────────
class MyDetails {
  final String fullName;
  final String upiId;
  final String bankName;
  final String accountLast4;
  final bool isPinSet;

  MyDetails({
    required this.fullName,
    required this.upiId,
    required this.bankName,
    required this.accountLast4,
    required this.isPinSet,
  });

  factory MyDetails.fromMap(Map map) => MyDetails(
        fullName: map['fullName'] as String,
        upiId: map['upiId'] as String,
        bankName: map['bankName'] as String,
        accountLast4: map['accountLast4'] as String,
        isPinSet: (map['pinStatus'] as String).toLowerCase() == 'set',
      );

  String get maskedAccount => '••••${accountLast4}';
}

// ── Session Event types ───────────────────────────────────────────────────────
enum SessionEventType {
  sessionResponse,
  sessionEnd,
  sessionError,
  sessionTimeout,
  incomingCall,
  myDetails,
  unknown,
}

// ── Session Event model ───────────────────────────────────────────────────────
class SessionEvent {
  final SessionEventType type;
  final String? message;
  final bool expectsInput;
  final String? step;
  final String? errorReason;
  final MyDetails? myDetails;

  SessionEvent({
    required this.type,
    this.message,
    this.expectsInput = false,
    this.step,
    this.errorReason,
    this.myDetails,
  });

  factory SessionEvent.fromMap(Map map) {
    final typeStr = map['type'] as String? ?? '';

    final eventType = switch (typeStr) {
      'session_response' => SessionEventType.sessionResponse,
      'session_end' => SessionEventType.sessionEnd,
      'session_error' => SessionEventType.sessionError,
      'session_timeout' => SessionEventType.sessionTimeout,
      'incoming_call_during_session' => SessionEventType.incomingCall,
      'my_details' => SessionEventType.myDetails,
      _ => SessionEventType.unknown,
    };

    return SessionEvent(
      type: eventType,
      message: map['message'] as String?,
      expectsInput: map['expectsInput'] as bool? ?? false,
      step: map['step'] as String?,
      errorReason: map['reason'] as String?,
      myDetails: eventType == SessionEventType.myDetails
          ? MyDetails.fromMap(map)
          : null,
    );
  }
}

// ── Main USSD Service ─────────────────────────────────────────────────────────
class UssdService {
  static const _method = MethodChannel('com.offlinepay.payapp/ussd');
  static const _event = EventChannel('com.offlinepay.payapp/events');

  // ── Dialer role ───────────────────────────────────────────────────────────

  static Future<bool> isDefaultDialer() async {
    return await _method.invokeMethod<bool>('isDefaultDialer') ?? false;
  }

  static Future<bool> requestDefaultDialer() async {
    return await _method.invokeMethod<bool>('requestDefaultDialer') ?? false;
  }

  // ── SIM slots ─────────────────────────────────────────────────────────────

  static Future<List<SimSlot>> getSimSlots() async {
    try {
      final raw = await _method.invokeListMethod<Map>('getSimSlots');
      return (raw ?? []).map(SimSlot.fromMap).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get SIM slots: ${e.message}');
    }
  }

  // ── USSD session ──────────────────────────────────────────────────────────

  /// Dial a USSD code — responses come via [sessionStream]
  static Future<void> dialUssd(
    String code, {
    int? subscriptionId,
  }) async {
    try {
      await _method.invokeMethod('dialUssd', {
        'code': code,
        if (subscriptionId != null) 'subscriptionId': subscriptionId,
      });
    } on PlatformException catch (e) {
      throw Exception('Dial error: ${e.message}');
    }
  }

  /// Send reply in active session
  static Future<void> sendReply(String text) async {
    try {
      await _method.invokeMethod('sendReply', {'text': text});
    } on PlatformException catch (e) {
      throw Exception('Reply error: ${e.message}');
    }
  }

  /// End active session
  static Future<void> endSession() async {
    await _method.invokeMethod('endSession');
  }

  /// Tell native layer which step Flutter is currently on
  static Future<void> setCurrentStep(String step) async {
    await _method.invokeMethod('setCurrentStep', {'step': step});
  }

  /// Check if session is active
  static Future<bool> isSessionActive() async {
    return await _method.invokeMethod<bool>('isSessionActive') ?? false;
  }

  // ── Event stream ──────────────────────────────────────────────────────────

  /// Live stream of all session events
  static Stream<SessionEvent> get sessionStream {
    return _event
        .receiveBroadcastStream()
        .map((event) => SessionEvent.fromMap(event as Map));
  }
}

// ── App-level state — cached My Details ───────────────────────────────────────
class AppState {
  static MyDetails? myDetails;
  static SimSlot? preferredSim;
  static bool isOnboarded = false;

  static void clear() {
    myDetails = null;
    preferredSim = null;
    isOnboarded = false;
  }
}
