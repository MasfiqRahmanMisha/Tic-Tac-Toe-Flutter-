import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

// Key used to persist the player's chosen name across app restarts.
const String kPlayerNameKey = 'player_name';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A2B3C),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () async {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(kPlayerNameKey);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => (savedName == null || savedName.trim().isEmpty)
                ? const NameEntryScreen()
                : const ModeSelectScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1A2B3C),
              Color(0xFF1E3248),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4FC3F7).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'T',
                      style: TextStyle(
                        color: Color(0xFF0D1B2A),
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'TIC TAC TOE',
                style: TextStyle(
                  color: Color(0xFF4FC3F7),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Classic Board Game',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// NAME ENTRY SCREEN (shown once, on first install)
// ─────────────────────────────────────────
class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  static const Color bgColor = Color(0xFF1A2B3C);
  static const Color cyan    = Color(0xFF4FC3F7);
  static const Color cellColor = Color(0xFF1E3248);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    if (name.length > 20) {
      setState(() => _error = 'Name must be 20 characters or fewer');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPlayerNameKey, name);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "WHAT'S YOUR NAME?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This is what opponents will see\nwhen you play nearby multiplayer',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 20,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: cyan,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: const TextStyle(color: Colors.white24),
                  counterText: '',
                  filled: true,
                  fillColor: cellColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: cyan, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _saveAndContinue(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _saving ? null : _saveAndContinue,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: cyan,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(bgColor),
                      ),
                    )
                        : const Text(
                      'CONTINUE',
                      style: TextStyle(
                        color: bgColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
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

// ─────────────────────────────────────────
// MODE SELECT SCREEN
// ─────────────────────────────────────────
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  static const Color bgColor   = Color(0xFF1A2B3C);
  static const Color cyan      = Color(0xFF4FC3F7);
  static const Color green     = Color(0xFF2ECC71);
  static const Color cellColor = Color(0xFF1E3248);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'TIC TAC TOE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cyan,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select Game Mode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 56),

              _ModeCard(
                icon: Icons.smartphone,
                title: 'Same Device',
                subtitle: 'Two players on one phone\nPass & play',
                color: cyan,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicTacToeScreen()),
                ),
              ),
              const SizedBox(height: 20),

              _ModeCard(
                icon: Icons.wifi_tethering,
                title: 'Nearby Multiplayer',
                subtitle: 'Two phones, one game\nvia Bluetooth & WiFi',
                color: green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LobbyScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1.8),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// LOCAL TIC TAC TOE SCREEN (Same Device)
// ─────────────────────────────────────────
class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen>
    with TickerProviderStateMixin {
  List<String?> board = List.filled(9, null);
  bool isXTurn = true;
  String? winner;
  List<int> winningCells = [];

  // Remembers who started the last game. Made `static` so this survives
  // leaving and re-entering the "Same Device" screen (Back button then
  // tapping "Same Device" again creates a brand-new state, which would
  // otherwise reset this to true every time and make X always start).
  static bool _startedWithX = true;

  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  static const Color bgColor    = Color(0xFF1A2B3C);
  static const Color cellColor  = Color(0xFF1E3248);
  static const Color xColor     = Color(0xFF4FC3F7);
  static const Color oColor     = Color(0xFFFFFFFF);
  static const Color winColor   = Color(0xFF2ECC71);
  static const Color titleCyan  = Color(0xFF4FC3F7);

  @override
  void initState() {
    super.initState();
    // Sync the instance's isXTurn with the static _startedWithX value.
    // Without this, re-entering this screen would reset isXTurn to its field
    // default (true) even though _startedWithX had already flipped to false
    // from a previous game.
    isXTurn = _startedWithX;
    _initAnims();
  }

  void _initAnims() {
    _scaleControllers = List.generate(
      9,
          (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 350)),
    );
    _scaleAnimations = _scaleControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.elasticOut))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _scaleControllers) c.dispose();
    super.dispose();
  }

  void _tap(int index) {
    if (board[index] != null || winner != null) return;
    setState(() {
      board[index] = isXTurn ? 'X' : 'O';
      _scaleControllers[index].forward(from: 0);
      isXTurn = !isXTurn;
      _checkWinner();
    });
  }

  void _checkWinner() {
    const patterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final p in patterns) {
      final a = board[p[0]], b = board[p[1]], c = board[p[2]];
      if (a != null && a == b && b == c) {
        winner = a;
        winningCells = List<int>.from(p);
        return;
      }
    }
    if (!board.contains(null)) winner = 'Draw';
  }

  void _newGame() {
    setState(() {
      board = List.filled(9, null);
      winner = null;
      winningCells = [];
      // Flip who starts compared to the last game, instead of always
      // resetting to X.
      _startedWithX = !_startedWithX;
      isXTurn = _startedWithX;
      for (final c in _scaleControllers) c.reset();
    });
  }

  Widget _buildCell(int index) {
    final value = board[index];
    final isWin = winningCells.contains(index);
    return GestureDetector(
      onTap: () => _tap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isWin ? winColor : cellColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isWin
              ? [BoxShadow(color: winColor.withOpacity(0.55), blurRadius: 22, spreadRadius: 3)]
              : [],
        ),
        child: value == null
            ? null
            : ScaleTransition(
          scale: _scaleAnimations[index],
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: isWin ? Colors.white : value == 'X' ? xColor : oColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.7), width: 1.8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusText = winner == null
        ? 'Turn: ${isXTurn ? "X" : "O"}'
        : winner == 'Draw'
        ? 'Draw!'
        : 'Winner: $winner';

    final statusColor = winner != null && winner != 'Draw'
        ? winColor
        : winner == 'Draw'
        ? Colors.orangeAccent
        : Colors.white70;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white38),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Column(
            children: [
              const Text(
                'TIC TAC TOE',
                style: TextStyle(
                  color: titleCyan,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 9,
                  itemBuilder: (_, i) => _buildCell(i),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (winner != null) ...[
                    _buildBtn('NEW GAME', _newGame, xColor),
                    const SizedBox(width: 14),
                  ],
                  _buildBtn('RESET GAME', _newGame, winColor),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// LOBBY SCREEN (Nearby)
// ─────────────────────────────────────────
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  static const Color bgColor = Color(0xFF1A2B3C);
  static const Color cyan    = Color(0xFF4FC3F7);
  static const Color green   = Color(0xFF2ECC71);

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();
  }

  Future<String> _getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(kPlayerNameKey);
    return (name == null || name.trim().isEmpty) ? 'Player' : name.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white38),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nearby Multiplayer',
          style: TextStyle(color: cyan, fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Who are you?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'One player hosts, other joins',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 48),

              _LobbyBtn(
                label: 'HOST GAME',
                sublabel: 'Create a game room',
                icon: Icons.wifi_tethering,
                color: cyan,
                onTap: () async {
                  await _requestPermissions();
                  final myName = await _getSavedName();
                  if (context.mounted) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => NearbyGameScreen(isHost: true, myName: myName)));
                  }
                },
              ),
              const SizedBox(height: 16),

              _LobbyBtn(
                label: 'JOIN GAME',
                sublabel: 'Find nearby host',
                icon: Icons.search,
                color: green,
                onTap: () async {
                  await _requestPermissions();
                  final myName = await _getSavedName();
                  if (context.mounted) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => NearbyGameScreen(isHost: false, myName: myName)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LobbyBtn({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 1.8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(sublabel, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.4), size: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// NEARBY GAME SCREEN
// ─────────────────────────────────────────
class NearbyGameScreen extends StatefulWidget {
  final bool isHost;
  final String myName;
  const NearbyGameScreen({super.key, required this.isHost, required this.myName});

  @override
  State<NearbyGameScreen> createState() => _NearbyGameScreenState();
}

class _NearbyGameScreenState extends State<NearbyGameScreen>
    with TickerProviderStateMixin {

  final String _serviceId = 'com.example.tictactoe';
  String? _connectedEndpointId;
  String _status = '';
  bool _connected = false;
  bool _isConnecting = false;
  List<_Discovery> _discoveredDevices = [];
  String? _opponentName;

  List<String?> board = List.filled(9, null);
  String? winner;
  List<int> winningCells = [];
  bool _myTurn = false;

  // Only the HOST decides who starts each new game and flips this value.
  // The guest never flips it locally — it only ever receives the host's
  // decision inside the reset payload. This keeps both devices in sync
  // (if both sides tried to flip independently they could disagree).
  static bool _hostStartsNext = true;

  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  static const Color bgColor   = Color(0xFF1A2B3C);
  static const Color cellColor = Color(0xFF1E3248);
  static const Color xColor    = Color(0xFF4FC3F7);
  static const Color oColor    = Color(0xFFFFFFFF);
  static const Color winColor  = Color(0xFF2ECC71);
  static const Color cyan      = Color(0xFF4FC3F7);

  String get _myMark  => widget.isHost ? 'X' : 'O';
  String get _oppMark => widget.isHost ? 'O' : 'X';

  @override
  void initState() {
    super.initState();
    _initAnims();
    _initNearby();
  }

  void _initAnims() {
    _scaleControllers = List.generate(
      9,
          (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 350)),
    );
    _scaleAnimations = _scaleControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.elasticOut))
        .toList();
  }

  Future<void> _initNearby() async {
    if (widget.isHost) {
      setState(() => _status = 'Waiting for player to join...');
      await _startAdvertising();
    } else {
      setState(() => _status = 'Searching for host...');
      await _startDiscovery();
    }
  }

  Future<void> _startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        widget.myName,
        Strategy.P2P_POINT_TO_POINT,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            setState(() {
              _connectedEndpointId = id;
              _connected = true;
              _myTurn = true;
              _status = _opponentName != null
                  ? 'Connected with $_opponentName! You are X'
                  : 'Connected! You are X';
            });
            Nearby().stopAdvertising();
          } else {
            setState(() {
              _status = 'Connection failed. Try again.';
            });
          }
        },
        onDisconnected: (id) => setState(() {
          _connected = false;
          _status = 'Opponent disconnected!';
        }),
        serviceId: _serviceId,
      );
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        widget.myName,
        Strategy.P2P_POINT_TO_POINT,
        onEndpointFound: (id, name, serviceId) {
          setState(() {
            if (!_discoveredDevices.any((d) => d.id == id)) {
              _discoveredDevices.add(_Discovery(id: id, name: name));
            }
            _status = 'Host found! Tap to connect.';
          });
        },
        onEndpointLost: (id) {
          setState(() => _discoveredDevices.removeWhere((d) => d.id == id));
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    setState(() => _opponentName = info.endpointName);
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endId, payload) {
        if (payload.type == PayloadType.BYTES) {
          final data = jsonDecode(String.fromCharCodes(payload.bytes!));
          _handleIncomingData(data);
        }
      },
      onPayloadTransferUpdate: (endId, update) {},
    );
  }

  Future<void> _connectToHost(String endpointId) async {
    if (_isConnecting || _connected) return;
    _isConnecting = true;

    setState(() => _status = 'Connecting...');
    try {
      await Nearby().stopDiscovery();

      await Nearby().requestConnection(
        widget.myName,
        endpointId,
        onConnectionInitiated: (id, info) {
          _onConnectionInitiated(id, info);
          setState(() => _connectedEndpointId = id);
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            setState(() {
              _connected = true;
              _myTurn = false;
              _status = _opponentName != null
                  ? 'Connected with $_opponentName! You are O'
                  : 'Connected! You are O';
            });
          } else {
            _isConnecting = false;
            setState(() {
              _status = 'Connection failed. Try again.';
            });
          }
        },
        onDisconnected: (id) => setState(() {
          _connected = false;
          _status = 'Opponent disconnected!';
        }),
      );
    } catch (e) {
      _isConnecting = false;
      setState(() => _status = 'Error: $e');
    }
  }

  void _handleIncomingData(Map<String, dynamic> data) {
    if (data['type'] == 'move') {
      final index = data['index'] as int;
      setState(() {
        board[index] = _oppMark;
        _scaleControllers[index].forward(from: 0);
        _myTurn = true;
        _checkWinner();
      });
    } else if (data['type'] == 'reset') {
      // The host always includes who starts the new game in the payload.
      final hostStarts = data['hostStarts'] as bool? ?? true;
      _applyReset(hostStarts: hostStarts);
    } else if (data['type'] == 'reset_request') {
      // Guest tapped "NEW GAME" first — only the host is allowed to decide
      // and broadcast the flip, so the host does it here on the guest's behalf.
      if (widget.isHost) _hostInitiatedReset();
    }
  }

  void _tap(int index) {
    if (!_connected || !_myTurn || board[index] != null || winner != null) return;
    setState(() {
      board[index] = _myMark;
      _scaleControllers[index].forward(from: 0);
      _myTurn = false;
      _checkWinner();
    });
    final payload = jsonEncode({'type': 'move', 'index': index});
    Nearby().sendBytesPayload(
      _connectedEndpointId!,
      Uint8List.fromList(payload.codeUnits),
    );
  }

  void _checkWinner() {
    const patterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final p in patterns) {
      final a = board[p[0]], b = board[p[1]], c = board[p[2]];
      if (a != null && a == b && b == c) {
        setState(() { winner = a; winningCells = List<int>.from(p); });
        return;
      }
    }
    if (!board.contains(null)) setState(() => winner = 'Draw');
  }

  // Applies a reset locally given who starts, without touching _hostStartsNext.
  void _applyReset({required bool hostStarts}) {
    setState(() {
      board = List.filled(9, null);
      winner = null;
      winningCells = [];
      _myTurn = widget.isHost ? hostStarts : !hostStarts;
      for (final c in _scaleControllers) c.reset();
    });
  }

  // Only ever called on the HOST device: flips who starts next, applies it
  // locally, and broadcasts the decision to the guest so both sides agree.
  void _hostInitiatedReset() {
    _hostStartsNext = !_hostStartsNext;
    _applyReset(hostStarts: _hostStartsNext);
    if (_connectedEndpointId != null) {
      final payload = jsonEncode({'type': 'reset', 'hostStarts': _hostStartsNext});
      Nearby().sendBytesPayload(
        _connectedEndpointId!,
        Uint8List.fromList(payload.codeUnits),
      );
    }
  }

  // Bound to the "NEW GAME" button on BOTH devices. Whichever side taps it,
  // the outcome is the same: the host decides the flip and both boards end
  // up in sync. Host acts immediately; guest just asks the host to act.
  void _sendReset() {
    if (widget.isHost) {
      _hostInitiatedReset();
    } else if (_connectedEndpointId != null) {
      final payload = jsonEncode({'type': 'reset_request'});
      Nearby().sendBytesPayload(
        _connectedEndpointId!,
        Uint8List.fromList(payload.codeUnits),
      );
    }
  }

  @override
  void dispose() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    for (final c in _scaleControllers) c.dispose();
    super.dispose();
  }

  Widget _buildCell(int index) {
    final value = board[index];
    final isWin = winningCells.contains(index);
    return GestureDetector(
      onTap: () => _tap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isWin ? winColor : cellColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isWin
              ? [BoxShadow(color: winColor.withOpacity(0.55), blurRadius: 22, spreadRadius: 3)]
              : [],
        ),
        child: value == null
            ? null
            : ScaleTransition(
          scale: _scaleAnimations[index],
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: isWin ? Colors.white : value == 'X' ? xColor : oColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.7), width: 1.8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opponentLabel = _opponentName?.trim().isNotEmpty == true ? _opponentName! : 'Opponent';

    final statusText = !_connected
        ? _status
        : winner == null
        ? (_myTurn ? 'Your turn (${widget.myName})' : "$opponentLabel's turn")
        : winner == 'Draw'
        ? 'Draw!'
        : winner == _myMark ? 'You win! 🎉' : '$opponentLabel wins!';

    final statusColor = !_connected
        ? Colors.white38
        : winner == null
        ? (_myTurn ? cyan : Colors.white54)
        : winner == 'Draw'
        ? Colors.orangeAccent
        : winner == _myMark ? winColor : Colors.redAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white38),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TIC TAC TOE',
          style: TextStyle(color: cyan, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (widget.isHost ? cyan : winColor).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (widget.isHost ? cyan : winColor).withOpacity(0.5)),
            ),
            child: Text(
              '${widget.myName} ($_myMark)',
              style: TextStyle(
                color: widget.isHost ? cyan : winColor,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_connected && _opponentName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'vs $_opponentName',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),

              if (!widget.isHost && !_connected && _discoveredDevices.isNotEmpty)
                ...(_discoveredDevices.map((d) => GestureDetector(
                  onTap: () => _connectToHost(d.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: winColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android, color: Color(0xFF2ECC71), size: 20),
                        const SizedBox(width: 12),
                        Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Text('TAP TO JOIN', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ))),

              if (!_connected)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(cyan),
                        ),
                        const SizedBox(height: 20),
                        Text(_status, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

              if (_connected) ...[
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 9,
                    itemBuilder: (_, i) => _buildCell(i),
                  ),
                ),
                const SizedBox(height: 20),
                // Either player can tap NEW GAME or RESET GAME — whichever
                // side taps it, the host still decides the flip and
                // broadcasts it so both boards stay in sync.
                Row(
                  children: [
                    if (winner != null) ...[
                      _buildBtn('NEW GAME', _sendReset, cyan),
                      const SizedBox(width: 12),
                    ],
                    _buildBtn('RESET GAME', _sendReset, winColor),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Discovery {
  final String id;
  final String name;
  _Discovery({required this.id, required this.name});
}