import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'dart:convert';

void main() {
  runApp(const PausasActivasApp());
}

class PausasActivasApp extends StatelessWidget {
  const PausasActivasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pausas Activas Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}


class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setBool('isLoggedIn', true);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? '';
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        await saveToken(data['token']);
        await saveUserName(data['user']['name']);
        return {'success': true};
      } else {
        
        String errorMsg = 'Error al registrar';
        if (data.containsKey('email')) {
          errorMsg = data['email'][0] ?? 'Email ya registrado';
        } else if (data.containsKey('error')) {
          errorMsg = data['error'];
        }
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await saveToken(data['token']);
        await saveUserName(data['user']['name']);
        return {'success': true};
      }
      return {'success': false, 'error': 'Credenciales inválidas'};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setBool('isLoggedIn', false);
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => isLoggedIn ? const HomePage() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.teal, Colors.tealAccent])),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text('Pausas Activas Pro', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ApiService.login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _form,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                const Icon(Icons.health_and_safety, size: 80, color: Colors.teal),
                const SizedBox(height: 20),
                const Text('Iniciar Sesión', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Ingresa tu email' : null),
                const SizedBox(height: 15),
                TextFormField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Ingresa tu contraseña' : null),
                const SizedBox(height: 25),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)))),
                const SizedBox(height: 15),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())), child: const Text('¿No tienes cuenta? Regístrate')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ApiService.register(_name.text.trim(), _email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _form,
          child: Column(
            children: [
              const Text('Registro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Ingresa tu correo electronico' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null),
              const SizedBox(height: 15),
              TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), validator: (v) => v != _pass.text ? 'No coinciden' : null),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrarse', style: TextStyle(fontSize: 18)))),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('¿Ya tienes cuenta? Inicia sesión')),
            ],
          ),
        ),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _intervalController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  String _status = 'Listo para empezar 💪';
  String _userName = '';
  int _totalBreaks = 0;
  int _selectedIndex = 0;
  List<Map<String, String>> _history = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _exercises = [
    {'text': '🧘 Respira profundamente por 15 segundos', 'category': 'Relajación', 'duration': '15'},
    {'text': '🙆 Estira los brazos hacia el techo', 'category': 'Estiramientos', 'duration': '20'},
    {'text': '👀 Parpadea rápidamente por 10 segundos', 'category': 'Ojos', 'duration': '10'},
    {'text': '🚶 Camina en el lugar por 30 segundos', 'category': 'Movimiento', 'duration': '30'},
    {'text': '💪 Flexiones contra la pared', 'category': 'Fuerza', 'duration': '25'},
    {'text': '🦵 Marcha elevando las rodillas', 'category': 'Movimiento', 'duration': '30'},
    {'text': '🧎 Haz 5 sentadillas suaves', 'category': 'Fuerza', 'duration': '30'},
    {'text': '👁️ Cierra los ojos y respira profundo', 'category': 'Relajación', 'duration': '30'},
    {'text': '🤲 Aprieta y suelta los puños', 'category': 'Fuerza', 'duration': '15'},
    {'text': '🔄 Mueve los ojos en círculos', 'category': 'Ojos', 'duration': '15'},
    {'text': '💃 Gira la cintura suavemente', 'category': 'Movimiento', 'duration': '20'},
    {'text': '😌 Meditación rápida de 30 segundos', 'category': 'Relajación', 'duration': '30'},
  ];

  @override
  void initState() {
    super.initState();
    _intervalController.text = '25';
    _loadUser();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  Future<void> _loadUser() async {
    final name = await ApiService.getUserName();
    final prefs = await SharedPreferences.getInstance();
    final breaks = prefs.getInt('totalBreaks') ?? 0;
    final historyList = prefs.getStringList('history') ?? [];
    setState(() {
      _userName = name;
      _totalBreaks = breaks;
      _history = historyList.map((e) { final p = e.split('|'); return {'date': p[0], 'time': p[1], 'exercise': p.length > 2 ? p[2] : '', 'category': p.length > 3 ? p[3] : ''}; }).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalBreaks', _totalBreaks);
    await prefs.setStringList('history', _history.map((e) => '${e['date']}|${e['time']}|${e['exercise']}|${e['category']}').toList());
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  void _startTimer() {
    final interval = int.tryParse(_intervalController.text);
    if (interval == null || interval <= 0 || interval > 120) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intervalo inválido'), backgroundColor: Colors.red));
      return;
    }
    if (_isRunning && !_isPaused) return;
    if (!_isPaused) { _totalSeconds = interval * 60; _remainingSeconds = _totalSeconds; }
    _isRunning = true;
    _isPaused = false;
    _pulseController.repeat(reverse: true);
    setState(() => _status = '⏰ Próxima pausa en $interval min');
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
        if (_remainingSeconds <= 0) { _takeBreak(); _remainingSeconds = _totalSeconds; }
      });
    });
  }

  void _takeBreak() {
    final exercise = _exercises[Random().nextInt(_exercises.length)];
    final now = DateTime.now();
    setState(() {
      _totalBreaks++;
      _history.insert(0, {'date': DateFormat('dd/MM/yyyy').format(now), 'time': DateFormat('HH:mm:ss').format(now), 'exercise': exercise['text']!, 'category': exercise['category']!});
      if (_history.length > 100) _history.removeLast();
      _status = '✅ ¡Pausa completada!';
    });
    _saveData();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('¡Hora de tu Pausa!'),
      content: Text(exercise['text']!),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('¡Listo!'))],
    ));
  }

  void _pauseTimer() { _timer?.cancel(); _pulseController.stop(); setState(() { _isPaused = true; _status = '⏸️ Pausado'; }); }
  void _resetTimer() { _timer?.cancel(); _pulseController.stop(); _pulseController.reset(); setState(() { _remainingSeconds = 0; _totalSeconds = 0; _isRunning = false; _isPaused = false; _status = '🔄 Reiniciado'; }); }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '00:00';
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  double _getProgress() => _totalSeconds <= 0 ? 0 : (_totalSeconds - _remainingSeconds) / _totalSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    _intervalController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pausas Activas Pro'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)]),
      body: IndexedStack(
        index: _selectedIndex,
        children: [_buildTimerScreen(), _buildStatsScreen(), _buildHistoryScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Timer'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }

  Widget _buildTimerScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(children: [
                    CircleAvatar(radius: 28, backgroundColor: Colors.teal, child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 15),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('🏆 $_totalBreaks pausas', style: TextStyle(color: Colors.grey.shade600))]),
                  ]),
                  const SizedBox(height: 15),
                  TextField(controller: _intervalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Intervalo (minutos)', prefixIcon: Icon(Icons.timer), suffixText: 'min', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Stack(alignment: Alignment.center, children: [
            SizedBox(width: 200, height: 200, child: CircularProgressIndicator(value: _getProgress(), strokeWidth: 12, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal))),
            Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.teal, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20)])),
            Text(_formatTime(_remainingSeconds), style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 25),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: _startTimer, icon: const Icon(Icons.play_arrow), label: const Text('Iniciar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: _pauseTimer, icon: const Icon(Icons.pause), label: const Text('Pausar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white))),
          ]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _resetTimer, icon: const Icon(Icons.refresh), label: const Text('Reiniciar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildStatsScreen() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.analytics, size: 80, color: Colors.teal),
      const SizedBox(height: 20),
      Card(child: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
        Text('Total Pausas', style: TextStyle(color: Colors.grey.shade600)),
        Text('$_totalBreaks', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.teal)),
        const Divider(),
        Text('Usuario', style: TextStyle(color: Colors.grey.shade600)),
        Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      ]))),
    ]));
  }

  Widget _buildHistoryScreen() {
    return _history.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: Colors.grey.shade400), const SizedBox(height: 20), Text('Sin pausas aún', style: TextStyle(color: Colors.grey.shade600))]))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _history.length,
            itemBuilder: (context, i) => Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.fitness_center, color: Colors.white)),
                title: Text(_history[i]['exercise'] ?? ''),
                subtitle: Text('${_history[i]['date']} - ${_history[i]['time']}'),
                trailing: const Icon(Icons.check_circle, color: Colors.teal),
              ),
            ),
          );
  }
}