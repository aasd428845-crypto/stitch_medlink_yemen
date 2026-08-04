// Placeholder smoke test. The real app requires a live Supabase session
// bootstrap in main(), so widget tests for MedLinkApp will be added once
// a test-friendly dependency injection seam exists for AuthService/Supabase.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
