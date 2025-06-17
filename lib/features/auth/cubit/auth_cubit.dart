import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../services/local_auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final LocalAuthService _localAuthService;

  AuthCubit({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    LocalAuthService? localAuthService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _localAuthService = localAuthService ?? LocalAuthService(),
        super(AuthInitial()) {
    _firebaseAuth.authStateChanges().listen((User? user) async {
      if (user != null) {
        
        final isLocalAuthEnabled = await _localAuthService.isLocalAuthEnabled();
        if (isLocalAuthEnabled) {
          emit(LocalAuthRequired(user));
        } else {
          emit(Authenticated(user));
        }
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(const AuthError('Google sign in aborted'));
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      emit(AuthLoading());
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> authenticateWithPin(String pin) async {
    try {
      final currentState = state;
      if (currentState is LocalAuthRequired) {
        emit(AuthLoading());
        
        final isValid = await _localAuthService.verifyPin(pin);
        if (isValid) {
          emit(LocalAuthSuccess(currentState.user));
          emit(Authenticated(currentState.user));
        } else {
          emit(const AuthError('Invalid PIN'));
          emit(LocalAuthRequired(currentState.user));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> authenticateWithBiometrics() async {
    try {
      final currentState = state;
      if (currentState is LocalAuthRequired) {
        emit(AuthLoading());
        
        final success = await _localAuthService.authenticateWithBiometrics();
        if (success) {
          emit(LocalAuthSuccess(currentState.user));
          emit(Authenticated(currentState.user));
        } else {
          emit(const AuthError('Biometric authentication failed'));
          emit(LocalAuthRequired(currentState.user));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> enableLocalAuth(String pin) async {
    try {
      await _localAuthService.setPin(pin);
      await _localAuthService.setLocalAuthEnabled(true);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> disableLocalAuth() async {
    try {
      await _localAuthService.setLocalAuthEnabled(false);
      await _localAuthService.removePin();
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<bool> isLocalAuthEnabled() async {
    return await _localAuthService.isLocalAuthEnabled();
  }

  Future<bool> canUseBiometrics() async {
    return await _localAuthService.canCheckBiometrics();
  }
} 