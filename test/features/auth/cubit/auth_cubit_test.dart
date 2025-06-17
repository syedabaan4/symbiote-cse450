import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/auth/cubit/auth_cubit.dart';
import 'package:symbiote/features/auth/cubit/auth_state.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:symbiote/services/local_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FakeLocalAuthService implements LocalAuthService {
  bool _isLocalAuthEnabled = false;

  @override
  Future<bool> isLocalAuthEnabled() async => _isLocalAuthEnabled;
  
  void setLocalAuth(bool enabled) => _isLocalAuthEnabled = enabled;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.toString();
}

void main() {
  group('AuthCubit', () {
    late MockFirebaseAuth mockAuth;
    late FakeLocalAuthService fakeLocalAuthService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      fakeLocalAuthService = FakeLocalAuthService();
    });

    test('initial state is AuthInitial', () {
      final authCubit = AuthCubit(
        firebaseAuth: mockAuth,
        googleSignIn: GoogleSignIn(),
        localAuthService: fakeLocalAuthService,
      );
      expect(authCubit.state, equals(AuthInitial()));
    });
    
    blocTest<AuthCubit, AuthState>(
      'emits [Authenticated] when user is signed in and local auth is disabled',
      build: () {
        final mockUser = MockUser();
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        fakeLocalAuthService.setLocalAuth(false);
        return AuthCubit(
          firebaseAuth: mockAuth,
          googleSignIn: GoogleSignIn(),
          localAuthService: fakeLocalAuthService,
        );
      },
      expect: () => [isA<Authenticated>()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [LocalAuthRequired] when user is signed in and local auth is enabled',
      build: () {
        final mockUser = MockUser();
        mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
        fakeLocalAuthService.setLocalAuth(true);
        return AuthCubit(
          firebaseAuth: mockAuth,
          googleSignIn: GoogleSignIn(),
          localAuthService: fakeLocalAuthService,
        );
      },
      expect: () => [isA<LocalAuthRequired>()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Unauthenticated] when user is not signed in',
      build: () {
        mockAuth = MockFirebaseAuth(signedIn: false);
        return AuthCubit(
          firebaseAuth: mockAuth,
          googleSignIn: GoogleSignIn(),
          localAuthService: fakeLocalAuthService,
        );
      },
      expect: () => [isA<Unauthenticated>()],
    );
  });
} 