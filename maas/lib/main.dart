import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Android emulator: 10.0.2.2 reaches the host machine's localhost.
// Physical device: replace with your machine's local IP (e.g. 192.168.x.x).
const String _apiBase = 'https://api.dystopian.fr';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0A0A0A),
    ),
  );
  runApp(const MaaSApp());
}

class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['quote'] as String,
        author: json['author'] as String,
      );
}

class MaaSApp extends StatelessWidget {
  const MaaSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaaS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const QuoteScreen(),
    );
  }
}

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with SingleTickerProviderStateMixin {
  Quote? _quote;
  bool _loading = true;
  bool _error = false;
  bool _hintVisible = true;
  bool _fetching = false;

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fetchQuote(initial: true);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _hintVisible = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchQuote({bool initial = false}) async {
    if (_fetching) return;
    _fetching = true;

    if (!initial) {
      await _controller.reverse();
    }

    setState(() {
      _error = false;
      if (initial) _loading = true;
    });

    try {
      final response = await http.get(Uri.parse('$_apiBase/quote'));
      if (response.statusCode == 200) {
        final quote = Quote.fromJson(jsonDecode(response.body));
        if (mounted) {
          setState(() {
            _quote = quote;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _loading = false; _error = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }

    _fetching = false;
    if (mounted) _controller.forward();
  }

  void _onSwipe() {
    setState(() => _hintVisible = false);
    _fetchQuote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -80) _onSwipe();
        },
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: _loading
                    ? const _Spinner()
                    : FadeTransition(
                        opacity: _fade,
                        child: _error
                            ? const _ErrorView()
                            : _QuoteView(quote: _quote!),
                      ),
              ),
              AnimatedOpacity(
                opacity: _hintVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: _SwipeHint(),
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

class _QuoteView extends StatelessWidget {
  final Quote quote;

  const _QuoteView({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u201C',
            style: TextStyle(
              fontSize: 96,
              height: 0.7,
              color: Colors.white.withValues(alpha: 0.08),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            quote.text,
            style: const TextStyle(
              fontSize: 21,
              height: 1.65,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 20,
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quote.author,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.8,
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 1,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'No connection',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'swipe to retry',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.18),
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offset;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _offset = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 30),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _offset.value),
        child: Opacity(
          opacity: _opacity.value,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(height: 2),
              Text(
                'swipe up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
