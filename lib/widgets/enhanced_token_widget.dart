import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Updated imports for newton_particles 0.2.2
import 'package:newton_particles/newton_particles.dart';

class EnhancedTokenWidget extends StatefulWidget {
  final Offset position;
  final double size;
  final String asset;
  final int playerId;
  final Color color;
  final IconData? colorBlindIcon;
  final bool canMove;
  final bool isCurrentTurn;
  final VoidCallback? onTap;
  final ConfettiController? confettiController;
  // final ParticleController? particleController;

  const EnhancedTokenWidget({
    super.key,
    required this.position,
    required this.size,
    required this.asset,
    required this.playerId,
    required this.color,
    this.colorBlindIcon,
    this.canMove = false,
    this.isCurrentTurn = false,
    this.onTap,
    this.confettiController,
    // this.particleController,
  });

  @override
  EnhancedTokenWidgetState createState() => EnhancedTokenWidgetState();
}

class EnhancedTokenWidgetState extends State<EnhancedTokenWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  AnimationController? _moveController;
  Offset _offset = Offset.zero;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _offset = widget.position;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    if (widget.canMove) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EnhancedTokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.canMove != oldWidget.canMove) {
      if (widget.canMove) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
      }
    }
  }

  Future<void> moveAlongPath(List<Offset> path) async {
    if (path.length < 2) return;
    _moveController?.dispose();
    final items = <TweenSequenceItem<Offset>>[];
    for (var i = 0; i < path.length - 1; i++) {
      items.add(TweenSequenceItem(
        tween: Tween(begin: path[i], end: path[i + 1]),
        weight: 1,
      ));
    }
    _moveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200 * items.length),
    );
    final animation = TweenSequence(items).animate(
      CurvedAnimation(parent: _moveController!, curve: Curves.elasticOut),
    );
    animation.addListener(() {
      setState(() => _offset = animation.value);
    });
    await _moveController!.forward();
  }

  void triggerCapture() {
      HapticFeedback.lightImpact();
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && widget.confettiController != null) {
        final pos = renderObject.localToGlobal(
          Offset(widget.size / 2, widget.size / 2),
        );
        // You can ignore this logic since confetti doesn't need exact position
        widget.confettiController?.play(); // Just play confetti animation
      }


    // Optional: if you want to dynamically move the confetti to different alignments,
    // you can use a state variable and update the alignment
  }

  // void triggerCapture() {
  //   HapticFeedback.lightImpact();
  //   final renderObject = context.findRenderObject();
  //   if (renderObject is RenderBox && widget.particleController != null) {
  //     final pos = renderObject.localToGlobal(
  //       Offset(widget.size / 2, widget.size / 2),
  //     );
  //     widget.particleController!.burst(pos);
  //   }
  // }

  void _handleTap() {
    HapticFeedback.selectionClick();
    setState(() => _scale = 1.1);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _scale = 1.0);
    });
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _moveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: widget.isCurrentTurn
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: widget.canMove
                        ? [
                            BoxShadow(
                              color:
                                  widget.color.withOpacity(_glowAnimation.value),
                              blurRadius: 8 * _glowAnimation.value + 2,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Semantics(
                  label: 'Player ${widget.playerId} token',
                  child: SvgPicture.asset(
                    widget.asset,
                    width: widget.size,
                    height: widget.size,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Text(
                      '${widget.playerId}',
                      style: TextStyle(
                        fontSize: widget.size * 0.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (widget.colorBlindIcon != null)
                  Icon(
                    widget.colorBlindIcon,
                    color: Colors.white,
                    size: widget.size * 0.6,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
