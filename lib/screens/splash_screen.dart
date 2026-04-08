import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF2C0830),
                  Color(0xFF4A154B),
                  Color(0xFF611F69),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF36C5F0).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFECB22E).withValues(alpha: 0.18),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Spacer(),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 26,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const _SlackMark(),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Teamspace',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Channel-first collaboration with direct messages, clean search, and a sharper Slack-style workspace.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFE8D8EA),
                          height: 1.5,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Color(0xFF36C5F0),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Preparing your workspace...',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlackMark extends StatelessWidget {
  const _SlackMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: const <Widget>[
          _SlackMarkSegment(
            alignment: Alignment.topCenter,
            color: Color(0xFF36C5F0),
            width: 14,
            height: 24,
            radius: BorderRadius.all(Radius.circular(999)),
          ),
          _SlackMarkSegment(
            alignment: Alignment.centerLeft,
            color: Color(0xFFE01E5A),
            width: 24,
            height: 14,
            radius: BorderRadius.all(Radius.circular(999)),
          ),
          _SlackMarkSegment(
            alignment: Alignment.bottomCenter,
            color: Color(0xFF2EB67D),
            width: 14,
            height: 24,
            radius: BorderRadius.all(Radius.circular(999)),
          ),
          _SlackMarkSegment(
            alignment: Alignment.centerRight,
            color: Color(0xFFECB22E),
            width: 24,
            height: 14,
            radius: BorderRadius.all(Radius.circular(999)),
          ),
        ],
      ),
    );
  }
}

class _SlackMarkSegment extends StatelessWidget {
  const _SlackMarkSegment({
    required this.alignment,
    required this.color,
    required this.width,
    required this.height,
    required this.radius,
  });

  final Alignment alignment;
  final Color color;
  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
        ),
      ),
    );
  }
}
