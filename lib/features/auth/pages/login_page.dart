import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/google_sign_in_button.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/reins.png',
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.15),
          colorBlendMode: BlendMode.darken,
          ),
          SafeArea(
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),    
                    // Text(
                    //   'Discover unique styles and\ndefine your own look.',
                    //   textAlign: TextAlign.center,
                    //   style: GoogleFonts.pixelifySans(
                    //     fontSize: 16,
                    //     color: Colors.white,
                    //     fontWeight: FontWeight.w400,
                    //   ),
                    // ),
                    const Spacer(flex: 14),
                    if (state is AuthLoading)
                      LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 50)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: GoogleSignInButton(
                          onPressed: () {
                            context.read<AuthCubit>().signInWithGoogle();
                          },
                        ),
                      ),
                    const Spacer(flex: 1),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 