import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class PinAuthPage extends StatefulWidget {
  const PinAuthPage({super.key});

  @override
  State<PinAuthPage> createState() => _PinAuthPageState();
}

class _PinAuthPageState extends State<PinAuthPage> {
  String _pin = '';
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus to show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    // Only allow numeric input
    if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
      return;
    }
    
    if (value.length <= 6) {
      setState(() {
        _pin = value;
      });
      
      if (value.length == 6) {
        // Delay slightly to show the complete PIN before authenticating
        Future.delayed(const Duration(milliseconds: 300), () {
          context.read<AuthCubit>().authenticateWithPin(value);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            setState(() {
              _pin = '';
            });
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.blueGrey.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter PIN',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // PIN Input Field
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _pinController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 8,
                          color: Colors.blueGrey.shade700,
                        ),
                        onChanged: _onPinChanged,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • • •',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 24,
                            color: Colors.grey.shade400,
                            letterSpacing: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                    ),
                    
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 