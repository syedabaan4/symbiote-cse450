import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../cubit/threads_cubit.dart';
import '../cubit/threads_state.dart';
import '../cubit/thread_detail_cubit.dart';
import '../../ai/models/ai_agent.dart';
import 'thread_detail_page.dart';

class ThreadEntryPage extends StatefulWidget {
  final String? existingThreadId;

  const ThreadEntryPage({
    super.key,
    this.existingThreadId,
  });

  @override
  State<ThreadEntryPage> createState() => _ThreadEntryPageState();
}

class _ThreadEntryPageState extends State<ThreadEntryPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  AIAgentType? _selectedAgent;

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

  void _discardContent() {
    Navigator.pop(context);
  }

  Future<void> _saveContent() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.existingThreadId != null) {
      
      await context.read<ThreadDetailCubit>().addThoughtToThread(widget.existingThreadId!, content);
    } else {
      
      if (_selectedAgent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select an AI agent for your thread',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
      await context.read<ThreadsCubit>().createThreadWithThought(content, aiAgentType: _selectedAgent);
    }
  }

  void _showAgentSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Pick your Symbiote',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            
            Expanded(
              child: PageView.builder(
                itemCount: AIAgent.availableAgents.length,
                padEnds: false,
                controller: PageController(viewportFraction: 1.0),
                itemBuilder: (context, index) {
                  final agent = AIAgent.availableAgents[index];
                  final isSelected = _selectedAgent == agent.type;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: _AgentCard(
                      agent: agent,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAgent = agent.type;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            
            
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  AIAgent.availableAgents.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<ThreadsCubit, ThreadsState>(
              listener: (context, state) {
                if (state is ThreadCreated) {
                  if (widget.existingThreadId == null) {
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadDetailPage(threadId: state.thread.id),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                } else if (state is ThreadsError) {
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
            ),
            BlocListener<ThreadDetailCubit, ThreadDetailState>(
              listener: (context, state) {
                if (state is ThoughtAdded) {
                  Navigator.pop(context);
                } else if (state is ThreadDetailError) {
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
            ),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _discardContent,
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
                    
                    
                    BlocBuilder<ThreadsCubit, ThreadsState>(
                      builder: (context, threadsState) {
                        return BlocBuilder<ThreadDetailCubit, ThreadDetailState>(
                          builder: (context, detailState) {
                            final isCreating = widget.existingThreadId != null 
                                ? detailState is ThoughtAdding 
                                : threadsState is ThreadCreating;
                            
                            if (isCreating) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Saving',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (_hasText) {
                              return TextButton(
                                onPressed: _saveContent,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Save',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox(width: 48);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              
              if (widget.existingThreadId == null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        GestureDetector(
                        onTap: () => _showAgentSelectionBottomSheet(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _selectedAgent != null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AIAgent.getByType(_selectedAgent!).name,
                                            style: GoogleFonts.pixelifySans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Select an AI agent',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                              ),
                              Icon(
                                Icons.expand_more,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 10, 
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.2,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.existingThreadId != null 
                            ? 'Continue your thoughts...'
                            : 'Start a new thread...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final AIAgent agent;
  final bool isSelected;
  final VoidCallback onTap;

  const _AgentCard({
    required this.agent,
    required this.isSelected,
    required this.onTap,
  });

  String _getBackgroundImage(AIAgentType type) {
    switch (type) {
      case AIAgentType.reflective:
        return 'assets/images/therapeutic.png';
      case AIAgentType.creative:
        return 'assets/images/intense.png';
      case AIAgentType.organize:
        return 'assets/images/organizer.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImage = _getBackgroundImage(agent.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  
                  Text(
                    agent.name,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  
                  Text(
                    agent.description,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isSelected ? 'Selected' : 'Select Agent',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 