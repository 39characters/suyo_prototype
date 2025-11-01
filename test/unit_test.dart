import 'package:flutter_test/flutter_test.dart';

/// Example logic functions used in SUYO (mocked for testing)
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return emailRegex.hasMatch(email);
}

bool isPasswordStrong(String password) => password.length >= 6;

bool isBookingFormComplete({required String title, required String desc, required DateTime? date}) {
  return title.isNotEmpty && desc.isNotEmpty && date != null;
}

String assignUserRole(bool isProvider) => isProvider ? "provider" : "customer";

bool isValidCoordinate(double lat, double lng) {
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

void main() {
  group('Email Validation', () {
    test('Valid email returns true', () {
      expect(isValidEmail('test@example.com'), true);
    });

    test('Invalid email returns false', () {
      expect(isValidEmail('bademail.com'), false);
    });
  });

  group('Password Strength', () {
    test('Strong password passes', () {
      expect(isPasswordStrong('abcdef'), true);
    });

    test('Weak password fails', () {
      expect(isPasswordStrong('abc'), false);
    });
  });

  group('User Role Assignment', () {
    test('Assigns customer role', () {
      expect(assignUserRole(false), 'customer');
    });

    test('Assigns provider role', () {
      expect(assignUserRole(true), 'provider');
    });
  });

  group('Booking Form Completion', () {
    test('Returns true when title, desc, date are filled', () {
      expect(
        isBookingFormComplete(title: 'Clean car', desc: 'Need detailing', date: DateTime.now()),
        true,
      );
    });

    test('Returns false when date is null', () {
      expect(
        isBookingFormComplete(title: 'Clean car', desc: 'Need detailing', date: null),
        false,
      );
    });
  });

  group('Coordinate Validity', () {
    test('Valid coordinates return true', () {
      expect(isValidCoordinate(14.6, 121.0), true);
    });

    test('Invalid coordinates return false', () {
      expect(isValidCoordinate(120.0, 200.0), false);
    });
  });
}
