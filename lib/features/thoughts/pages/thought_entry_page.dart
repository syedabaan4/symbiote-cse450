import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubit/thoughts_cubit.dart';
import '../cubit/thoughts_state.dart';

class ThoughtEntryPage extends StatefulWidget {
  const ThoughtEntryPage({super.key});

  @override
  State<ThoughtEntryPage> createState() => _ThoughtEntryPageState();
}

class _ThoughtEntryPageState extends State<ThoughtEntryPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _discardThought() {
    Navigator.pop(context);
  }

  Future<void> _saveThought() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    await context.read<ThoughtsCubit>().saveThought(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<ThoughtsCubit, ThoughtsState>(
          listener: (context, state) {
            if (state is ThoughtSaved) {
              Navigator.pop(context);
            } else if (state is ThoughtsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final isSaving = state is ThoughtSaving;
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _discardThought,
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(),
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          overlayColor: WidgetStatePropertyAll(
                            Colors.grey.shade100,
                          ),
                        ),
                      ),
                      
                      if (isSaving)
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                      else if (_hasText)
                        IconButton(
                          onPressed: _saveThought,
                          icon: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(),
                        )
                      else
                        const SizedBox(width: 48), 
                    ],
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                        color: Colors.grey.shade900,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          color: Colors.grey.shade400,
                          letterSpacing: -0.2,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      cursorColor: Colors.grey.shade700,
                      cursorWidth: 2,
                      cursorHeight: 24,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

