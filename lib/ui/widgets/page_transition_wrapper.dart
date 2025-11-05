import 'package:flutter/material.dart';
import '../../models/app_settings.dart';

class PageTransitionWrapper extends StatefulWidget {
  final Widget child;
  final AppSettings settings;

  const PageTransitionWrapper({
    super.key,
    required this.child,
    required this.settings,
  });

  @override
  State<PageTransitionWrapper> createState() => _PageTransitionWrapperState();
}

class _PageTransitionWrapperState extends State<PageTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Widget? _currentChild;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.settings.animationDuration),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 오른쪽에서
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _currentChild = widget.child;
    _animationController.forward();
  }

  @override
  void didUpdateWidget(PageTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child && !_isTransitioning) {
      _transitionToNewPage();
    }
  }

  Future<void> _transitionToNewPage() async {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
    });

    // 페이지 전환 애니메이션
    if (widget.settings.animationType == 'fade') {
      // 페이드 아웃
      await _animationController.reverse();
      setState(() {
        _currentChild = widget.child;
      });
      // 페이드 인
      await _animationController.forward();
    } else if (widget.settings.animationType == 'slide') {
      // 슬라이드 아웃
      await _animationController.reverse();
      setState(() {
        _currentChild = widget.child;
      });
      // 슬라이드 인
      await _animationController.forward();
    } else {
      // 즉시 전환
      setState(() {
        _currentChild = widget.child;
      });
    }

    setState(() {
      _isTransitioning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settings.animationType == 'none') {
      return widget.child;
    }

    if (widget.settings.animationType == 'fade') {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: _currentChild ?? widget.child,
      );
    } else if (widget.settings.animationType == 'slide') {
      return SlideTransition(
        position: _slideAnimation,
        child: _currentChild ?? widget.child,
      );
    }

    return widget.child;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

