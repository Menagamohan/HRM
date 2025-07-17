import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:confetti/confetti.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gif/gif.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:googleapis_auth/auth_browser.dart';
// import 'package:googleapis_auth/auth_io.dart';
import 'package:hanon/log_database.dart';
import 'package:hanon/log_entry.dart';
import 'package:hanon/push_notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login.dart'; // inside main.dart
import 'headers.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';
import 'birthday.dart';

// void main() => runApp(const MyApp());
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
  print('Fingerprint is $isBiometricEnabled');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // Background messages
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print('📱 App opened from notification: ${message.notification?.title}');
    if (message.notification?.title == 'Wishes') {
      print('Birthday Page...');
      await prefs.setBool('birthday', true);
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const BirthdayPage()),
      );
    } else {
      print('Home Page...');
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  });
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ask permission (iOS)
  await FirebaseMessaging.instance.requestPermission();
  _firebaseListener();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
    home: isBiometricEnabled ? const LoginPage() : const MyApp(),
  ));
}

void _firebaseListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message received: ${message.notification?.title}');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📦 Background message received: ${message.messageId}");
  print("🔔 Title: ${message.notification?.title}");
  print("📄 Body: ${message.notification?.body}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
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

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Welcome',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Color(0xff1530ca),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool? isBiometricEnabled;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
    _biometricCheck();
  }

  void _checkIfLoggedIn() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token: $token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('FcmToken', token!);
  }

  void _biometricCheck() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    });
    print('======>BioMetric: $isBiometricEnabled');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/banner.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/l logo.png',
                        height: 100,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isBiometricEnabled == false)
                        TextField(
                          controller: _usernameController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Enter username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (isBiometricEnabled == false)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (isBiometricEnabled == false)
                        PasswordField(controller: _passwordController),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff09355a),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _login,
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 25, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (isBiometricEnabled == false) {
      setState(() {
        _isLoading = true;
      });
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? FcmToken = await prefs.getString('FcmToken');
        print('FcmToken : $FcmToken');
        final response = await http.post(
          Uri.parse('http://hrmwebapi.lemeniz.com/api/Auth/Login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text,
            'password': _passwordController.text,
            'FcmToken': FcmToken
          }),
        );

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final responseBody = json.decode(response.body);
          log('====> ${responseBody}');
          final String token = responseBody['accessToken'] ?? '';
          if (token.isNotEmpty) {
            await prefs.setString('apiToken', token);
            await prefs.setString('user', _usernameController.text);
            print("Password : ${_passwordController.text}");
            await prefs.setString('passwordId', _passwordController.text);
            String? passwordId = await prefs.getString('passwordId');
            print('Conform : $passwordId');
            await prefs.setString(
                'user_name', responseBody['actualName'] ?? '');
            await prefs.setString(
                'designation', responseBody['designation'] ?? '');
            await prefs.setString('userName', responseBody['userName'] ?? '');
            await prefs.setString('userId', responseBody['userId'] ?? '');
            await prefs.setString('dob', responseBody['dob'] ?? '');
            await prefs.setBool('approver', responseBody['isApprover'] ?? '');
            // await prefs.setBool('isBiometricEnabled',
            //     true); // Enable biometric login for next time
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully Logged In!'),
                backgroundColor: Colors.green,
              ),
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            });
          } else {
            _showError('Invalid credentials!');
          }
        } else {
          _showError(
              'Invalid response from server. Code: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (isBiometricEnabled == true) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BiometricPage()),
        );
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordField({super.key, required this.controller});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: 'Enter your password',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final File? capturedImage;
  const HomePage({Key? key, this.capturedImage}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? userName;
  String? designationName;
  String? empID;
  String? tokenApi;
  bool _isLoading = true;
  String? gender;
  String? genderBarPhoto;
  int? genderBottomBarPhoto;
  String? genderPhoto;
  String? gifAsset;
  late final GifController controller1;
  bool? roleType;
  int? pendingCount;
  int? approverCount;
  int? rejectedCount;
  String? profileImagePath;

  // in your HomePage class
  ConfettiController? _confettiController;
  bool showConfetti = false;

  @override
  void dispose() {
    _confettiController?.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    print('Home Page......');
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 15));
    checkIfTodayIsMyBirthday();
    checkApprover();
    checkPending();
    loadProfileImage();
    controller1 = GifController(vsync: this);
    Future.delayed(const Duration(seconds: 1), () async {
      await fetchUser();
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profileImagePath = prefs.getString('profileImagePath');
    });
  }

  void checkApprover() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? role = await prefs.getBool('approver');
    print('Approver: $role');
    setState(() {
      roleType = role;
    });
  }

  Widget buildBoxItem(
    BuildContext context,
    String imagePath,
    String label,
    Widget page, {
    int leaveEntries = 0, // Default value
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 60,
                width: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: Image.asset(imagePath),
              ),
              if (leaveEntries > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        '$leaveEntries',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget buildBoxItems(
      BuildContext context, String imagePath, String label, Widget page,
      {required String leaveEntries}) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Image.asset(imagePath, width: 60, height: 60),
              if (leaveEntries != '0')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    leaveEntries,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> checkPending() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken');
    const url =
        'http://hrmwebapi.lemeniz.com/api/Notification/GetOverallDashboardDetails';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        pendingCount = data['leaveEntries']['P'];
        approverCount = data['leaveEntries']['A'];
        rejectedCount = data['leaveEntries']['R'];
      });
      print('PendingCount: $pendingCount');
    }
  }

  Future<void> checkIfTodayIsMyBirthday() async {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('user');
    final token = prefs.getString('apiToken');

    const url =
        'http://hrmwebapi.lemeniz.com/api/Notification/GetBirthdayDetails';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final isBirthday = data.any((person) => person['employeeId'] == empId);

      if (isBirthday) {
        setState(() {
          showConfetti = true;
        });
        _confettiController?.play();
      }
    }
  }

  void _firebaseListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(message.notification?.title ?? 'Notification'),
          content: Text(message.notification?.body ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  String getLastPunchValue(List<dynamic> punchData) {
    if (punchData.isNotEmpty) {
      return punchData.last['punch'] ?? 'No punch value';
    } else {
      return 'No data available';
    }
  }

  Future<void> fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = await prefs.getString('user_name');
    String? designation = await prefs.getString('designation');
    String? empNo = await prefs.getString('userName');
    String? token = await prefs.getString('apiToken');
    print('Token : $token');
    setState(() {
      userName = username;
      designationName = designation;
      empID = empNo;
      tokenApi = token;
    });
    print(userName);
    print(designationName);
    print(empID);
    print(tokenApi);

    try {
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      print('Current Month : $currentMonth');
      print('Current year : $currentYear');
      Uri urlApi = Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/Attendance/GetRawPunchDetails?month=$currentMonth&year=$currentYear');
      final response = await http.get(
        urlApi,
        headers: {
          'Authorization': 'Bearer $tokenApi',
          'Content-Type': 'application/json',
        },
      );
      print('url : $urlApi');

      if (response.statusCode == 200) {
        print(response.body);
        final prefs = await SharedPreferences.getInstance();
        final dob = prefs.getString('dob');
        final gender = jsonDecode(response.body);

        String genderCheck = gender[0]['gender'];
        print(gender);
        final lastPunch = getLastPunchValue(gender);
        print('Last punch value: $lastPunch');

        DateTime now = DateTime.now();
        int hour = now.hour;
        int minute = now.minute;

        bool isLunchTime =
            (hour == 12 && minute >= 30) || (hour == 13 && minute < 30);
        bool isEveningLeisure = hour >= 13 && hour < 20;
        bool isEveningEating = hour >= 20 && hour < 22;
        bool isSleepingTime = hour >= 22 || hour < 5;
        bool isWorkoutTime = hour >= 5 && hour < 7;
        bool isWorkingTime = hour >= 7 && lastPunch == 'In';
        bool isWaterTime = [10, 15, 17].contains(hour);

        if (genderCheck == 'Male') {
          print('male');
          setState(() {
            genderBarPhoto = 'assets/animations/blue s bg.png';
            genderBottomBarPhoto = 0xff2950ae;
            genderPhoto = 'assets/animations/blue bg.png';
          });

          DateTime dobDate = DateFormat("dd-MM-yyyy").parse(dob!);
          DateTime today = DateTime.now();

          print('dob: $dob');
          print('Today: ${DateTime.now().day} , ${DateTime.now().month}');

          if (dobDate.day == today.day && dobDate.month == today.month) {
            print('Appie Birthday...');
            setState(() {
              gifAsset = 'assets/animations/cake img.gif';
            });
          } else {
            print('Normal day.......');
            if (isLunchTime) {
              print('Eating');
              setState(() {
                gifAsset = 'assets/animations/boy eating.gif';
              });
            } else if (isEveningLeisure && lastPunch == 'Out') {
              print('Evening leisure');
              setState(() {
                gifAsset = 'assets/animations/boy leisure.gif';
              });
            } else if (isEveningEating && lastPunch == 'Out') {
              setState(() {
                gifAsset = 'assets/animations/boy eating.gif';
              });
            } else if (isSleepingTime) {
              print('Sleeping');
              setState(() {
                gifAsset = 'assets/animations/boy sleep.gif';
              });
            } else if (isWorkoutTime) {
              print('workout');
              setState(() {
                gifAsset = 'assets/animations/boy workout.gif';
              });
            } else if (isWorkingTime) {
              print('working');
              setState(() {
                gifAsset = 'assets/animations/boy work.gif';
              });
            } else if (isWaterTime) {
              print('water time');
              setState(() {
                gifAsset = 'assets/animations/boy water.gif';
              });
            }
          }
        } else if (genderCheck == 'Female') {
          genderBarPhoto = 'assets/animations/pink s bg.png';
          genderBottomBarPhoto = 0xFFfa8492;
          genderPhoto = 'assets/animations/pink bg.png';

          DateTime dobDate = DateFormat("dd-MM-yyyy").parse(dob!);
          DateTime today = DateTime.now();

          if (dobDate.day == today.day && dobDate.month == today.month) {
            print('Appie Birthday...');
            setState(() {
              gifAsset = 'assets/animations/cake img.gif';
            });
          } else {
            if (isLunchTime) {
              setState(() {
                gifAsset = 'assets/animations/girl eating.gif';
              });
            } else if (isEveningLeisure && lastPunch == 'Out') {
              setState(() {
                gifAsset = 'assets/animations/girl leisure.gif';
              });
            } else if (isEveningEating && lastPunch == 'Out') {
              setState(() {
                gifAsset = 'assets/animations/girl eating.gif';
              });
            } else if (isSleepingTime) {
              setState(() {
                gifAsset = 'assets/animations/girl sleep.gif';
              });
            } else if (isWorkoutTime) {
              setState(() {
                gifAsset = 'assets/animations/girl workout.gif';
              });
            } else if (isWorkingTime) {
              setState(() {
                gifAsset = 'assets/animations/girl work.gif';
              });
            } else if (isWaterTime) {
              setState(() {
                gifAsset = 'assets/animations/girl water.gif';
              });
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Ask the user to enable location services
      await Geolocator.openLocationSettings();
      throw Exception('Please enable location services.');
    }

    // Check and request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, please enable them from settings.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Color(0xfff2f1f4),
        elevation: 5,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: Colors.black),
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => const Menupage()),
        //     );
        //   },
        //
        // ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: 30),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Top background image
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    genderBarPhoto ?? 'assets/animations/blue s bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: widget.capturedImage != null
                        ? FileImage(widget.capturedImage!)
                        : const AssetImage('assets/no_profile.jpg')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$empID - $userName',
                        style: const TextStyle(
                            fontSize: 19,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            '$designationName',
                            style: const TextStyle(
                              fontSize: 19,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildBoxItem(
                                context,
                                "assets/attendance.png",
                                "Attendance",
                                YourAttendanceUI(
                                    empId: empID ?? '',
                                    designation: designationName ?? '',
                                    name: userName ?? '',
                                    genderColor: genderBarPhoto ?? '',
                                    barColor:
                                        genderBottomBarPhoto ?? 0xff2950ae)),
                            buildBoxItem(context, "assets/log.png", "Log",
                                LogPage(name: userName!)),
                            buildBoxItem(context, "assets/leave.png", "Leave",
                                const LeaveHistoryPage()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildBoxItem(
                                context,
                                "assets/panic.png",
                                "Manual Punch",
                                AlertPage(
                                  name: userName!,
                                )),
                            buildBoxItem(context, "assets/biometric.png",
                                "Biometric", const BiometricPage()),
                            buildBoxItem(context, "assets/logout.png", "Logout",
                                const LogoutPage()),
                          ],
                        ),
                        if (roleType == true) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildBoxItems(
                                context,
                                "assets/pending.png",
                                "Pending",
                                PendingPage(),
                                leaveEntries: (pendingCount ?? 0) > 99
                                    ? "99+"
                                    : (pendingCount ?? 0).toString(),
                              ),
                              buildBoxItems(
                                context,
                                "assets/approver.png",
                                "Approved",
                                ApprovedPage(),
                                leaveEntries: (approverCount ?? 0) > 99
                                    ? "99+"
                                    : (approverCount ?? 0).toString(),
                              ),
                              buildBoxItems(
                                context,
                                "assets/rejected.png",
                                "Rejected",
                                RejectedPage(),
                                leaveEntries: (rejectedCount ?? 0) > 99
                                    ? "99+"
                                    : (rejectedCount ?? 0).toString(),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: Gif(
                      autostart: Autostart.loop,
                      placeholder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                      image: AssetImage(
                          gifAsset ?? 'assets/animations/boy sleep.gif'),
                      fit: BoxFit
                          .cover, // This stretches the GIF to cover the box fully
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
          if (showConfetti)
            ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              gravity: 0.3,
              colors: const [
                Colors.pink,
                Colors.red,
                Colors.orange,
                Colors.purple
              ],
              numberOfParticles: 90,
            ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerItem(
                      icon: Icons.calendar_today,
                      label: 'Holidays',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HolidayPage()),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.compare_arrows,
                      label: 'Approver & Requestor',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ApproverPage()),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DashboardPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Custom Curved Bottom Navigation Bar with SOS
      bottomNavigationBar: SizedBox(
        height: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background bar
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Color(genderBottomBarPhoto ?? 0xff2950ae),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),

            // Home Button (left)
            Positioned(
              bottom: 20,
              left: 40,
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF21465B),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.home, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 4),
                  const CircleAvatar(radius: 4, backgroundColor: Colors.white),
                ],
              ),
            ),

            // Profile Button (right)
            Positioned(
              bottom: 20,
              right: 40,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.person, color: Color(0xFF21465B)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfilePage(
                                genderPhoto: genderPhoto!,
                                capturedImage: widget.capturedImage,
                              )),
                    );
                  },
                ),
              ),
            ),

            // SOS Button (center)
            Positioned(
              top: -1,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: GestureDetector(
                onLongPress: () async {
                  try {
                    Position position = await _getCurrentLocation();
                    DateTime now = DateTime.now();

                    String date = DateFormat('yyyy-MM-dd').format(now);
                    String time = DateFormat('HH:mm:ss').format(now);

                    print('Date: $date');
                    print('Time: $time');

                    print(position.latitude);
                    print(position.longitude);

                    final log = LogEntry(
                      date: date,
                      time: time,
                      latitude: position.latitude,
                      longitude: position.longitude,
                    );

                    final id = await LogDatabase.instance.insertLog(log);
                    print('Inserted log with id: $id');

                    if (!context.mounted) return;

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location acquired successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => PanicAlertPage(
                    //       // name: empID ?? 'Unknown',
                    //       // designation: designationName ?? 'N/A',
                    //       // lat: position.latitude,
                    //       // lon: position.longitude,
                    //     ),
                    //   ),
                    // );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to get location: $e')),
                    );
                  }
                },
                child: ElevatedButton(
                  onPressed: () {}, // Regular tap does nothing
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21465B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    "SOS",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer item widget
  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue.shade800),
          ),
          title: Text(label),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget buildBoxItemes(
      BuildContext context, String imagePath, String label, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(imagePath),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String genderPhoto;
  final File? capturedImage;

  const ProfilePage({
    super.key,
    required this.genderPhoto,
    this.capturedImage,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? actualName;
  String? designationName;
  String? userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      fetchUser();
      setState(() {
        _isLoading = false;
      });
    });
  }

  void fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      actualName = prefs.getString('user_name') ?? '';
      designationName = prefs.getString('designation') ?? '';
      userName = prefs.getString('userName') ?? '';
    });
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue.shade800),
          ),
          title: Text(label),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerItem(
                      icon: Icons.calendar_today,
                      label: 'Holidays',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HolidayPage()),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.compare_arrows,
                      label: 'Approver & Requestor',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ApproverPage()),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DashboardPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with background image and profile
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(widget.genderPhoto),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 2,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 2,
                      child: Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.menu_open, color: Colors.white),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: widget.capturedImage != null
                                ? FileImage(widget.capturedImage!)
                                : const AssetImage('assets/no_profile.jpg')
                                    as ImageProvider,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '$userName - $actualName',
                                  style: const TextStyle(
                                      fontSize: 19,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$designationName ',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      buildOptionTile(Icons.info, "Employee Details", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EmployeeDetailsPage(
                                    token: 'apiToken',
                                    empId: 'empid',
                                  )),
                        );
                      }),
                      buildOptionTile(Icons.support_agent, "Contact Support",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ContactSupportPage()),
                        );
                      }),
                      buildOptionTile(Icons.verified, "App Version: 5.2", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AppVersionPage()),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// Model class for employee details
class EmployeeDetails {
  final String actualName;
  final String userName;
  final String designation;
  final String phoneNumber;
  final String dob;
  final String gender;
  final String joinDate;
  final String email;
  final String role;

  EmployeeDetails({
    required this.actualName,
    required this.userName,
    required this.designation,
    required this.phoneNumber,
    required this.dob,
    required this.gender,
    required this.joinDate,
    required this.email,
    required this.role,
  });

  factory EmployeeDetails.fromJson(Map<String, dynamic> json) {
    return EmployeeDetails(
      actualName: json['Name'] ?? '',
      userName: json['EmployeeID'] ?? '',
      designation: json['Designation'] ?? '',
      phoneNumber: json['MobileNo'] ?? '',
      dob: json['DOB'] ?? '',
      gender: json['Gender'] ?? '',
      joinDate: json['JoinDate'] ?? '',
      email: json['Email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

// Widget for each detail row
Widget buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class EmployeeDetailsPage extends StatefulWidget {
  final String token;
  final String empId;

  const EmployeeDetailsPage({
    super.key,
    required this.token,
    required this.empId,
  });

  @override
  State<EmployeeDetailsPage> createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  late Future<EmployeeDetails> employeeDetailsFuture;
  late var jsonBody;

  @override
  void initState() {
    super.initState();
    employeeDetailsFuture = fetchEmployeeDetails(widget.token, widget.empId);
  }

  Future<EmployeeDetails> fetchEmployeeDetails(
      Object token, Object empId) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = await prefs.getString('user');
    String? passwordId = await prefs.getString('passwordId');
    print(userId);
    print(passwordId);
    final response = await http.post(
      Uri.parse('http://hrmwebapi.lemeniz.com/api/Auth/Login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': userId,
        'password': passwordId,
      }),
    );

    if (response.statusCode == 200) {
      try {
        setState(() {
          jsonBody = jsonDecode(response.body);
        });

        print(jsonBody['userName']);
        // Safely access 'data' or use jsonBody if 'data' is not present
        final data = jsonBody['data'] ?? jsonBody;
        print(data);
        if (data != null) {
          return EmployeeDetails.fromJson(data);
        } else {
          throw Exception('Employee data is null');
        }
      } catch (e) {
        throw Exception('Failed to parse employee details: $e');
      }
    } else {
      throw Exception(
          'Failed to load employee details. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff2a3772),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<EmployeeDetails>(
        future: employeeDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No employee data found.'));
          } else {
            final details = snapshot.data!;
            return SingleChildScrollView(
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/no_profile.jpg'),
                        ),
                        const SizedBox(height: 20),
                        buildDetailRow('Name', jsonBody['actualName']),
                        buildDetailRow('Employee ID', jsonBody['userName']),
                        buildDetailRow('Designation', jsonBody['designation']),
                        buildDetailRow('Mobile No', jsonBody['phoneNumber']),
                        buildDetailRow('D.O.B', jsonBody['dob']),
                        buildDetailRow('Gender', jsonBody['gender']),
                        buildDetailRow('D.O.J', jsonBody['joiningDate']),
                        buildDetailRow('Email', jsonBody['email']),
                        buildDetailRow('role', jsonBody['role']),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

Widget buildDetailRows(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 3,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 5, child: Text(value)),
      ],
    ),
  );
}

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  List<dynamic> queryList = [];
  bool isLoading = true;
  String? errorMessage;

  // Replace this with your real token retrieval logic
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('apiToken'); // Or whatever key you use
  }

  @override
  void initState() {
    super.initState();
    fetchQueries();
  }

  Future<void> fetchQueries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url =
        Uri.parse("http://hrmwebapi.lemeniz.com/api/UserQuery/GetAllQuery");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization':
              'Bearer $token', // Add authorization header if needed
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming API returns a list directly, or adjust accordingly
        if (data is List) {
          setState(() {
            queryList = data;
            isLoading = false;
          });
        } else if (data is Map && data['queries'] != null) {
          // Example if data is wrapped in an object
          setState(() {
            queryList = data['queries'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Unexpected data format";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Failed to load queries: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching queries: $e";
        isLoading = false;
      });
    }
  }

  void navigateToAddQuery() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewQueryPage()),
    );
    if (result == true) {
      fetchQueries(); // Refresh list after submission
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Query List',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent[200],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: navigateToAddQuery,
            tooltip: "Add New Query",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : queryList.isEmpty
                  ? const Center(child: Text("No queries found."))
                  : ListView.builder(
                      itemCount: queryList.length,
                      itemBuilder: (context, index) {
                        final query = queryList[index];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Title:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(query['title'] ?? 'No Title'),
                                const SizedBox(height: 10),
                                Text(
                                  "Description:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(query['description'] ?? 'No Description'),
                                const SizedBox(height: 10),
                                Text(
                                  "Emp ID:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(query['createUser'] ?? ''),
                                const SizedBox(height: 10),
                                Text(
                                  "Created On:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(query['createdOn'] ?? ''),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class NewQueryPage extends StatefulWidget {
  const NewQueryPage({super.key});

  @override
  State<NewQueryPage> createState() => _NewQueryPageState();
}

class _NewQueryPageState extends State<NewQueryPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  File? selectedFile;

  Future<void> submitQuery() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      return;
    }

    // Prepare Base64-encoded image
    String? base64Image;
    if (selectedFile != null) {
      final bytes = await File(selectedFile!.path).readAsBytes();
      base64Image = base64Encode(bytes);
    }

    // Create request body
    final body = {
      'title': titleController.text,
      'description': descriptionController.text,
      if (base64Image != null) 'file': base64Image,
    };

    // Send POST request with JSON
    final response = await http.post(
      Uri.parse('http://hrmwebapi.lemeniz.com/api/UserQuery/CreateNewQuery'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      print('Error code: ${response.statusCode}');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to submit query: ${response.statusCode}')),
      );
    }
  }

  void pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Query'),
        backgroundColor: Colors.teal[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(selectedFile == null
                    ? 'Choose File'
                    : selectedFile!.path.split('/').last),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitQuery,
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppVersionPage extends StatelessWidget {
  const AppVersionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Version')),
      body: const Center(child: Text('App Version: 5.2')),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Widget buildNotificationBox({
    required String imagePath,
    required String title,
    required String message,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, width: 40, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(message,
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black54)),
                ],
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
      appBar: AppBar(title: const Text("Notifications")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildNotificationBox(
              imagePath: 'assets/birthday.png',
              title: "Birthday",
              message: "It's someone's special day!",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BirthdayPage()),
                );
              },
            ),
            buildNotificationBox(
              imagePath: 'assets/visitor.png',
              title: "Visitor Request",
              message: "It is a long established fact...",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VisitorPage()),
                );
              },
            ),
            buildNotificationBox(
              imagePath: 'assets/general.png',
              title: "General",
              message: "Get your best offer today!",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class BirthdayPage extends StatefulWidget {
  const BirthdayPage({super.key});

  @override
  State<BirthdayPage> createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<BirthdayPage> {
  List<dynamic> birthdayList = [];
  bool isLoading = true;
  String? loggedInEmpId;

  @override
  void initState() {
    super.initState();
    fetchBirthdayData();
    checkBirthday();
  }

  void checkBirthday() async {
    final prefs = await SharedPreferences.getInstance();

    bool birthday = prefs.getBool('birthday') ?? false;

    if (birthday == true) {
      await prefs.setBool('birthday', false);
    } else {
      return;
    }
  }

  Future<void> fetchBirthdayData() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiToken');
    loggedInEmpId = prefs.getString('user'); // assuming 'user' = employeeId

    const url =
        'http://hrmwebapi.lemeniz.com/api/Notification/GetBirthdayDetails';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Show current user's birthday first
        List<dynamic> sorted = List.from(data);
        sorted.sort((a, b) {
          if (a['employeeId'] == loggedInEmpId) return -1;
          if (b['employeeId'] == loggedInEmpId) return 1;
          return 0;
        });

        setState(() {
          birthdayList = sorted;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : birthdayList.isEmpty
                ? const Center(child: Text("No birthdays today."))
                : SafeArea(
                    child: Column(children: [
                    SizedBox(height: 10),
                    Row(children: [
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          // Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ));
                        },
                        child: Icon(Icons.arrow_back),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "🎂 Today's Birthdays",
                        style: TextStyle(fontSize: 21),
                      )
                    ]),
                    SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: birthdayList.length,
                        itemBuilder: (context, index) {
                          final birthday = birthdayList[index];
                          final isCurrentUser =
                              birthday['employeeId'] == loggedInEmpId;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            child: ListTile(
                              leading: const Icon(Icons.cake,
                                  color: Color(0xFFA971BC)),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isCurrentUser)
                                    const Text(
                                      "🎉 Happy Birthday to You!",
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  Text(
                                    birthday['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                  "Employee ID: ${birthday['employeeId']}"),
                              trailing: Text(birthday['date']),
                            ),
                          );
                        },
                      ),
                    )
                  ])));
  }
}

class VisitorPage extends StatefulWidget {
  const VisitorPage({super.key});

  @override
  State<VisitorPage> createState() => _VisitorPageState();
}

class _VisitorPageState extends State<VisitorPage> {
  List<dynamic> visitorData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVisitorRequests();
  }

  Future<void> fetchVisitorRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    final url = Uri.parse('http://hrmwebapi.lemeniz.com/api/Appointment/GetAppointment');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          visitorData = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('Error: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load visitor data')),
        );
      }
    } catch (e) {
      print('Exception: $e');
      setState(() => isLoading = false);
    }
  }

  Widget buildVisitorCards() {
    if (visitorData.isEmpty) {
      return const Center(child: Text("No visitor records found."));
    }

    return ListView.builder(
      itemCount: visitorData.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Allow embedding inside scroll views
      itemBuilder: (context, index) {
        final item = visitorData[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text("Sl. No: ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("id               : ${item['id'] ?? ''}"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Name        : ${item['name'] ?? ''}"),
                  ],
                ),
                Text("Company  : ${item['companyName'] ?? ''}"),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Mobile       : ${item['mobileNumber'] ?? ''}"),
                  ],
                ),
                Text("City            : ${item['city'] ?? ''}"),
                const SizedBox(height: 4),
                Text("Purpose    : ${item['purpose'] ?? ''}"),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("From         : ${item['checkInTime'] != null ? _formatDate(item['checkInTime']) : ''}"),
                  ],
                ),
                Text("To              : ${item['checkOutTime'] != null ? _formatDate(item['checkOutTime']) : ''}"),

              ],
            ),
          ),
        );
      },
    );
  }


  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  void onAddVisitor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppointmentPage()),
    );

    if (result == true) {
      fetchVisitorRequests(); // Refresh list after new entry
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Visitor',
            onPressed: onAddVisitor,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildVisitorCards(),
      ),
    );
  }
}

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> visitorTypes = [];
  List<dynamic> visitorPurposes = [];

  int? selectedVisitorTypeId;
  int? selectedVisitorPurposeId;

  final mobileController = TextEditingController();
  final nameController = TextEditingController();
  final companyController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();

  DateTime? fromDate;
  DateTime? toDate;

  bool isSubmitting = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
    fetchPhoneNumber();
  }

  Future<void> fetchPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    final visitorMobileUrl = Uri.parse('http://hrmwebapi.lemeniz.com/api/Appointment/GetVisitorMobileNumbers');


      final visitorMobileResponse = await http.get(visitorMobileUrl, headers: {
        'Authorization': 'Bearer $token',
      });

      if(visitorMobileResponse.statusCode == 200) {
        print('visitorMobileResponse: ${visitorMobileResponse.body}');
      } else {
        print('Error');
      }

  }



  Future<void> fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    final visitorTypeUrl = Uri.parse('http://hrmwebapi.lemeniz.com/api/Appointment/GetVisitorType');
    final visitorPurposeUrl = Uri.parse('http://hrmwebapi.lemeniz.com/api/Appointment/GetVisitorPurpose');

    try {
      final visitorTypeResponse = await http.get(visitorTypeUrl, headers: {
        'Authorization': 'Bearer $token',
      });

      final visitorPurposeResponse = await http.get(visitorPurposeUrl, headers: {
        'Authorization': 'Bearer $token',
      });

      if (visitorTypeResponse.statusCode == 200 &&
          visitorPurposeResponse.statusCode == 200) {
        setState(() {
          visitorTypes = jsonDecode(visitorTypeResponse.body);
          visitorPurposes = jsonDecode(visitorPurposeResponse.body);
          selectedVisitorTypeId = visitorTypes.first['id'];
          selectedVisitorPurposeId = visitorPurposes.first['id'];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load dropdown data");
      }
    } catch (e) {
      print('Dropdown Load Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both From and To dates')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';
    final url = Uri.parse('http://hrmwebapi.lemeniz.com/api/Appointment/Create');

    final body = {
      "visitorTypeId": selectedVisitorTypeId,
      "visitorPurposeId": selectedVisitorPurposeId,
      "name": nameController.text.trim(),
      "companyName": companyController.text.trim(),
      "mobileNumber": mobileController.text.trim(),
      "emailId": emailController.text.trim(),
      "city": cityController.text.trim(),
      "from": fromDate!.toIso8601String(),
      "to": toDate!.toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // return to list
      } else {
        print('Failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      print('Submit Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isFrom) {
            fromDate = fullDateTime;
          } else {
            toDate = fullDateTime;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime? dt) =>
      dt != null ? DateFormat('dd-MM-yyyy hh:mm a').format(dt) : '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment New')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedVisitorTypeId != 0 ? selectedVisitorTypeId : null,
                      decoration: const InputDecoration(labelText: 'View Template *'),
                      items: visitorTypes
                          .map((item) => DropdownMenuItem<int>(
                        value: item['id'],
                        child: Text(item['name']?.toString() ?? ''),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedVisitorTypeId = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedVisitorPurposeId != 0 ? selectedVisitorPurposeId : null,
                      decoration: const InputDecoration(labelText: 'Purpose *'),
                      items: visitorPurposes
                          .map((item) => DropdownMenuItem<int>(
                        value: item['id'],
                        child: Text(item['name']?.toString() ?? ''),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedVisitorPurposeId = val!;
                        });
                      },
                    ),
                  ),
                ],

              ),
              const SizedBox(height: 12),

              // Name & Mobile
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile Number *'),
                      validator: (value) =>
                      value!.isEmpty ? 'Mobile number is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (value) =>
                      value!.isEmpty ? 'Name is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Company & Email
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: companyController,
                      decoration:
                      const InputDecoration(labelText: 'Company Name *'),
                      validator: (value) =>
                      value!.isEmpty ? 'Company name is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Id'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // City
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 16),

              // From & To
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDateTime(context, true),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'From'),
                          controller: TextEditingController(
                            text: _formatDateTime(fromDate),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDateTime(context, false),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'To'),
                          controller: TextEditingController(
                            text: _formatDateTime(toDate),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submitForm,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}


class Menupage extends StatelessWidget {
  const Menupage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        backgroundColor: const Color(0xFF1A4C66), // Matches dark header color
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F4FB), // Light background
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        child: Column(
          children: [
            _buildMenuTile(
              icon: Icons.calendar_today,
              text: 'Holidays',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HolidayPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuTile(
              icon: Icons.people,
              text: 'Approver & Requestor',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ApproverPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuTile(
              icon: Icons.dashboard,
              text: 'Dashboard',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A4C66), // Icon circle background
          radius: 20,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// For drawer slide animation
Route _createDrawerRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const Menupage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0); // from left
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

class HolidayPage extends StatefulWidget {
  const HolidayPage({Key? key}) : super(key: key);

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  int selectedTabIndex = 0;
  List<Map<String, dynamic>> holidays = [];
  List<Map<String, dynamic>> npdList = [];
  List<Map<String, dynamic>> fiftyList = [];
  bool isLoading = true;
  Key listKey = UniqueKey();
  int selectedIndex = -1;
  int isFront = 0;

  void _swapCards(int index) {
    setState(() {
      isFront = index;
      selectedTabIndex = index;
      listKey = UniqueKey();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchHolidayData();
  }

  Widget _buildSecondCard({
    required List<Color> colors,
    required Color textColor,
  }) {
    return Container(
      width: 200,
      height: 95,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 6),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child:
                Icon(Icons.event_available_rounded, color: colors[0], size: 25),
          ),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NPD',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard({
    required List<Color> colors,
    required Color textColor,
  }) {
    return Container(
      width: 200,
      height: 80,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 6),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child:
                Icon(Icons.event_available_rounded, color: colors[0], size: 25),
          ),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoilday',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastCard({
    required List<Color> colors,
    required Color textColor,
  }) {
    return Container(
      width: 200,
      height: 90,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 6),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child:
                Icon(Icons.event_available_rounded, color: colors[0], size: 25),
          ),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('50:50',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get currentList {
    switch (selectedTabIndex) {
      case 1:
        return npdList;
      case 2:
        return fiftyList;
      default:
        return holidays;
    }
  }

  Future<void> fetchHolidayData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiToken');
    if (token == null) {
      print('Token not found!');
      return;
    }

    final url = Uri.parse(
        'http://hrmwebapi.lemeniz.com/api/Notification/GetOverallDashboardDetails');

    try {
      final response =
          await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          holidays = List<Map<String, dynamic>>.from(
            data['holidays'].map((item) => {
                  "description": item['description'],
                  "date": formatDate(item['date']),
                }),
          );
          npdList = List<Map<String, dynamic>>.from(
            data['npd'].map((item) => {
                  "description": item['description'],
                  "date": formatDate(item['date']),
                }),
          );
          fiftyList = List<Map<String, dynamic>>.from(
            data['fiftyFifties'].map((item) => {
                  "description": item['description'],
                  "date": formatDate(item['date']),
                }),
          );
          isLoading = false;
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String formatDate(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (e) {
      return rawDate;
    }
  }

  List<Widget> _buildCardStack() {
    List<Widget> cards = [];

    List<int> order = [0, 1, 2]; // 0 = Holiday, 1 = NPD, 2 = 50:50

    // Move selected to end (top-most)
    order.remove(isFront);
    order.add(isFront);

    // Offsets to prevent overlap
    const List<double> topOffsets = [40, 20, 0];
    const List<double> leftOffsets = [100, 50, 0];
    const List<double> scales = [0.9, 0.95, 1.0];

    for (int i = 0; i < order.length; i++) {
      int index = order[i];

      // Apply reverse offset logic so top card (isFront) has least offset
      cards.add(
        Positioned(
          top: topOffsets[i],
          left: leftOffsets[i],
          child: GestureDetector(
            onTap: () => _swapCards(index),
            child: Transform.scale(
              scale: scales[i],
              child: _buildCardByIndex(index),
            ),
          ),
        ),
      );
    }

    return cards;
  }

  Widget _buildCardByIndex(int index) {
    switch (index) {
      case 0:
        return _buildFrontCard(
          colors: [Color(0xFFFFB199), Color(0xFFFFEC61)],
          textColor: Colors.white,
        );
      case 1:
        return _buildSecondCard(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          textColor: Colors.white,
        );
      case 2:
        return _buildLastCard(
          colors: [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
          textColor: Colors.white,
        );
      default:
        return SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // const SizedBox(height: 12),
                // _buildHeaderCards(),
                // const SizedBox(height: 8),
                // _buildTableHeader(),

                Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    height: 160,
                    width: 400,
                    child: Stack(
                      children: _buildCardStack(),
                    ),
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOut,
                    key: listKey,
                    child: _buildAnimatedList(currentList),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderCards() {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildRollCard("Holiday", 0, [Color(0xFFFFB199), Color(0xFFFFEC61)],
              Colors.black),
          const SizedBox(width: 12),
          _buildRollCard(
              "NPD", 1, [Color(0xFF84FAB0), Color(0xFF8FD3F4)], Colors.black),
          const SizedBox(width: 12),
          _buildRollCard(
              "50:50", 2, [Color(0xFFFF6B6B), Color(0xFFFF8E8E)], Colors.white),
        ],
      ),
    );
  }

  Widget _buildRollCard(
      String title, int index, List<Color> colors, Color textColor) {
    bool isSelected = selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            selectedTabIndex = index;
            listKey = UniqueKey();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 260,
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(2, 6),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(Icons.event, color: colors.first, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.blueGrey.shade700,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Text('NAME', style: TextStyle(color: Colors.white)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text('DATE', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedList(List<Map<String, dynamic>> list) {
    return AnimationLimiter(
      key: ValueKey<int>(selectedTabIndex),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 700),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['description'] ?? '',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item['date']!,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ApproverPage extends StatefulWidget {
  const ApproverPage({super.key});

  @override
  State<ApproverPage> createState() => _ApproverPageState();
}

class _ApproverPageState extends State<ApproverPage> {
  List<List<String>> approverData = [];
  List<List<String>> requestData = [];
  int selectedIndex = -1;
  bool isFront = true;
  bool isApproverSelected = true;

  void _swapCards(String type) {
    if (type == 'approver') {
      setState(() {
        isFront = !isFront;
        selectedIndex = -1;
        isApproverSelected = false;
      });
    } else {
      setState(() {
        isFront = !isFront;
        selectedIndex = -1;
        isApproverSelected = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchApproverData();
    fetchRequesterData();
  }

  Future<void> fetchApproverData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    final response = await http.get(
      Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/Notification/GetOverallDashboardDetails'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      final Map<String, dynamic> approversMap = jsonMap['approvers'];

      final List<List<String>> approversList = approversMap.entries
          .map((entry) => [entry.key.toString(), entry.value.toString()])
          .toList();

      setState(() {
        approverData = approversList;
      });
    } else {
      throw Exception('Failed to load approver data');
    }
  }

  Future<void> fetchRequesterData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    final response = await http.get(
      Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/Notification/GetOverallDashboardDetails'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);
      final Map<String, dynamic> requestersMap = jsonMap['requesters'];

      final List<List<String>> requestersList = requestersMap.entries
          .map((entry) => [entry.key.toString(), entry.value.toString()])
          .toList();

      setState(() {
        requestData = requestersList;
      });
    } else {
      throw Exception('Failed to load requester data');
    }
  }

  Widget _buildFrontCard({
    required List<Color> colors,
    required Color textColor,
  }) {
    return Container(
      width: 300,
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 6),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child: Icon(Icons.approval_rounded, color: colors[0], size: 25),
          ),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('APPROVER',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 25,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard({
    required List<Color> colors,
    required Color textColor,
  }) {
    return Container(
      width: 300,
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 6),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child: Icon(Icons.request_page_rounded, color: colors[0], size: 25),
          ),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REQUESTER',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 25,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Approver & Requestor",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: CupertinoColors.activeBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              height: 140,
              width: 350,
              child: Stack(
                children: isFront
                    ? [
                        // Back card first
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 300),
                          top: 0,
                          left: 0,
                          child: GestureDetector(
                            onTap: () => _swapCards('request'),
                            child: AnimatedScale(
                              scale: 0.70,
                              duration: Duration(milliseconds: 300),
                              child: _buildBackCard(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                                textColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Front card second (drawn on top)
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 300),
                          top: 20,
                          left: 20,
                          child: GestureDetector(
                            onTap: () => _swapCards('approver'),
                            child: AnimatedScale(
                              scale: 0.70,
                              duration: Duration(milliseconds: 300),
                              child: _buildFrontCard(
                                colors: [Color(0xFFFFB199), Color(0xFFFFEC61)],
                                textColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : [
                        // Reverse order
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 300),
                          top: 20,
                          left: 20,
                          child: GestureDetector(
                            onTap: () => _swapCards('approver'),
                            child: AnimatedScale(
                              scale: 0.70,
                              duration: Duration(milliseconds: 300),
                              child: _buildFrontCard(
                                colors: [Color(0xFFFFB199), Color(0xFFFFEC61)],
                                textColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 300),
                          top: 0,
                          left: 0,
                          child: GestureDetector(
                            onTap: () => _swapCards('request'),
                            child: AnimatedScale(
                              scale: 0.70,
                              duration: Duration(milliseconds: 300),
                              child: _buildBackCard(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                                textColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ),

          // Container(
          //   margin: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey),
          //     borderRadius: BorderRadius.circular(6),
          //   ),
          //   child: Row(
          //     children: [
          //       // Expanded(
          //       //   child: GestureDetector(
          //       //     onTap: () {
          //       //       setState(() {
          //       //         isApproverSelected = true;
          //       //       });
          //       //     },
          //       //     child: Container(
          //       //       color: isApproverSelected ? Colors.green : Colors.white,
          //       //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       //       alignment: Alignment.center,
          //       //       child: Text(
          //       //         'APPROVER',
          //       //         style: TextStyle(
          //       //           color:
          //       //               isApproverSelected ? Colors.white : Colors.black,
          //       //           fontWeight: FontWeight.bold,
          //       //         ),
          //       //       ),
          //       //     ),
          //       //   ),
          //       // ),Expanded(
          //       //   child: GestureDetector(
          //       //     onTap: () {
          //       //       setState(() {
          //       //         isApproverSelected = true;
          //       //       });
          //       //     },
          //       //     child: Container(
          //       //       color: isApproverSelected ? Colors.green : Colors.white,
          //       //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       //       alignment: Alignment.center,
          //       //       child: Text(
          //       //         'APPROVER',
          //       //         style: TextStyle(
          //       //           color:
          //       //               isApproverSelected ? Colors.white : Colors.black,
          //       //           fontWeight: FontWeight.bold,
          //       //         ),
          //       //       ),
          //       //     ),
          //       //   ),
          //       // ),
          //       // Expanded(
          //       //   child: GestureDetector(
          //       //     onTap: () {
          //       //       setState(() {
          //       //         isApproverSelected = false;
          //       //       });
          //       //     },
          //       //     child: Container(
          //       //       color: !isApproverSelected ? Colors.green : Colors.white,
          //       //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       //       alignment: Alignment.center,
          //       //       child: Text(
          //       //         'REQUESTER',
          //       //         style: TextStyle(
          //       //           color:
          //       //               !isApproverSelected ? Colors.white : Colors.black,
          //       //           fontWeight: FontWeight.bold,
          //       //         ),
          //       //       ),
          //       //     ),
          //       //   ),
          //       // ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: isApproverSelected
                ? ApproverTable(data: approverData)
                : RequesterTable(data: requestData),
          ),
        ],
      ),
    );
  }
}

class ApproverTable extends StatelessWidget {
  final List<List<String>> data;

  const ApproverTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return _buildTable("", data);
  }
}

class RequesterTable extends StatelessWidget {
  final List<List<String>> data;

  const RequesterTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return _buildTable("", data);
  }
}

Widget _buildTable(String title, List<List<String>> data) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Header
              // Container(
              //   color: Colors.blueAccent,
              //   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              //   child: Row(
              //     children: const [
              //       SizedBox(
              //         width: 120,
              //         child: Text(
              //           'Employee ID',
              //           style: TextStyle(
              //             color: Colors.white,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ),
              //       SizedBox(
              //         width: 200,
              //         child: Text(
              //           'Name',
              //           style: TextStyle(
              //             color: Colors.white,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // Animated Rows
              AnimationLimiter(
                child: Column(
                  children: List.generate(data.length, (index) {
                    final entry = data[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 700),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(entry[0]),
                                ),
                                SizedBox(
                                  width: 200,
                                  child: Text(entry[1]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = fetchDashboardData();
  }

  Future<Map<String, dynamic>> fetchDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('apiToken');
    final response = await http.get(
      Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/Notification/GetOverallDashboardDetails'),
      headers: {'Authorization': 'Bearer $token'},
    );
    log(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  Widget _buildSummaryTable(
      String title, List<String> headers, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Table(
            border: TableBorder.symmetric(
              inside: const BorderSide(color: Colors.black12),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF0A3055)),
                children: headers
                    .map((h) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(h,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center),
                        ))
                    .toList(),
              ),
              TableRow(
                children: values
                    .map((v) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(v, textAlign: TextAlign.center),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveCard(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            color: const Color(0xFF0A3055),
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A3055),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final summary = data['summary'] ?? {};
          final training = data['trainingSummary'] ?? 0;
          final leave = data['leaveAvailableSummary'] ?? {};

          return AnimationLimiter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 500),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildSummaryTable("Absent Summary", [
                          "AB",
                          "HD",
                          "SP"
                        ], [
                          '${summary["absent"] ?? 0}',
                          '${summary["halfDayPresent"] ?? 0}',
                          '${summary["singlePunch"] ?? 0}',
                        ])),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildSummaryTable("Saturday Summary", [
                          "Worked",
                          "Pending"
                        ], [
                          '${summary["saturdayWorking"] ?? 0}',
                          '${summary["pendingSatrudayToWork"] ?? 0}',
                        ])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryTable("Training Summary", ["Training"],
                        ['${training.toString()}']),
                    const SizedBox(height: 24),
                    const Text("Leave Available Summary",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _buildLeaveCard("EL – Earned Leave",
                          '${leave["1"]?['noOfLeaveTaken'] ?? 0} / ${leave["1"]?['noOfLeaveAllocated'] ?? 0}'),
                      const SizedBox(width: 14),
                      _buildLeaveCard("SL–Sick/ML –Medical",
                          '${leave["2"]?['noOfLeaveTaken'] ?? 0} / ${leave["2"]?['noOfLeaveAllocated'] ?? 0}'),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _buildLeaveCard("CL – Casual Leave",
                          '${leave["3"]?['noOfLeaveTaken'] ?? 0} / ${leave["3"]?['noOfLeaveAllocated'] ?? 0}'),
                      const SizedBox(width: 14),
                      _buildLeaveCard("Comp off",
                          '${leave["4"]?['noOfLeaveTaken'] ?? 0} / ${leave["4"]?['noOfLeaveAllocated'] ?? 0}'),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _buildLeaveCard("Marriage Leave",
                          '${leave["5"]?['noOfLeaveTaken'] ?? 0} / ${leave["5"]?['noOfLeaveAllocated'] ?? 0}'),
                      const SizedBox(width: 14),
                      _buildLeaveCard("Paternity Leave",
                          '${leave["6"]?['noOfLeaveTaken'] ?? 0} / ${leave["6"]?['noOfLeaveAllocated'] ?? 0}'),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _buildLeaveCard("Condolence",
                          '${leave["7"]?['noOfLeaveTaken'] ?? 0} / ${leave["7"]?['noOfLeaveAllocated'] ?? 0}'),
                      const Spacer(),
                    ]),
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

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  Future<Map<String, String>> getEmployeeInfo() async {
    // Dummy data for demonstration
    await Future.delayed(const Duration(seconds: 1));
    return {
      'empId': 'AT0626',
      'empName': 'DHARANI KUMAR B',
      'designation': 'TMO',
    };
  }

  Future<List<dynamic>?> fetchAttendancePunch(
    String empId,
    String month,
    String year,
    String token, // add token parameter
  ) async {
    final service = AttendanceService();
    return await service.fetchAttendancePunch(
      empId: empId,
      month: month,
      year: year,
      token: token, // pass token here
    );
  }

  @override
  Widget build(BuildContext context) {
    const token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJBVDA2MjkiLCJqdGkiOiJmYzkxY2EwOC03ZWViLTRiYWYtOTE1OC04NjcyMTdkMDA4MzAiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjFjMTZjNGI4LTBjZWYtNDAxMy05NDYxLThiMjI4ZjEwMDkzNCIsImh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3dzLzIwMDUvMDUvaWRlbnRpdHkvY2xhaW1zL25hbWUiOiJBVDA2MjkiLCJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvY2xhaW1zL3JvbGUiOlsiRW1wbG95ZWVBVCIsIkVtcGxveWVlIiwiRGFzaGJvYXJkIiwiTGVhdmVQZXJtaXNzaW9uUmVxdWVzdCJdLCJleHAiOjE3NDczOTM5NTgsImlzcyI6IkhSTSIsImF1ZCI6IkhSTUFwcFVzZXJzIn0.uERmzKdLduPAY8PnFGfmg6NYiFmn29uj2hHC01OWdLQ'; // Replace with actual token
    return FutureBuilder(
      future: Future.wait([
        getEmployeeInfo(),
        fetchAttendancePunch(
            'AT0626', '05', '2025', token), // Use March 2025 + pass token
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final List<dynamic> data = snapshot.data as List<dynamic>;

        final Map<String, String> empInfo = Map<String, String>.from(data[0]);
        final List<dynamic> punchDetails =
            data[1] != null ? List<dynamic>.from(data[1]) : [];

        return YourAttendanceUI(
          empId: empInfo['empId']!,
          name: empInfo['empName']!,
          designation: empInfo['designation']!,
          punchData: punchDetails,
        );
      },
    );
  }
}

class YourAttendanceUI extends StatefulWidget {
  const YourAttendanceUI(
      {super.key,
      this.empId = '',
      this.name = '',
      this.designation = '',
      this.punchData = const [],
      this.genderColor = '',
      this.barColor = 0});
  final String empId;
  final String name;
  final String designation;
  final List<dynamic> punchData;
  final String genderColor;
  final int barColor;

  @override
  State<YourAttendanceUI> createState() => _YourAttendanceUIState();
}

class _YourAttendanceUIState extends State<YourAttendanceUI> {
  String? selectedYear;
  late String selectedMonth;
  bool _isLoading = true;
  String? empId;
  String? apiToken;
  DateTime focusedDay = DateTime.utc(2025, 5, 1);
  Map<DateTime, Color> statusDots = {};

  get bottomNavigationBar => null;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
      fetchAttendance();
    });
  }

  Widget buildDropdown(
      String selectedValue, List<String> items, Function(String?) onChanged) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F4787),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            dropdownColor: const Color(0xFF0A3055),
            iconEnabledColor: Colors.white,
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Center(
                    child: Text(value,
                        style: const TextStyle(color: Colors.white))),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Map<DateTime, Color> getStatusColorMap(Map<String, dynamic> attendance) {
    Map<DateTime, Color> statusDots = {};
    attendance.forEach((dayStr, status) {
      final int day = int.tryParse(dayStr.toString()) ?? 0;
      final DateTime date = DateTime(int.parse(selectedYear!),
          int.parse(getMonthNumber(selectedMonth)), day);

      Map<String, String> colorThemeDetail = {
        "PR": "#008000",
        "AB": "#ff0000",
        "OD": "#74bb5e",
        "CO": "#6b94b0",
        "HO": "#db0592",
        "LE": "#4663a9",
        "HD": "#e67b10",
        "NPD": "#773c3e",
        "WO": "#7e4d90",
        "FF": "#deb887",
        "BT": "#03fcdb",
        "SP": "#0c0c9b",
        "FUD": "#D3D3D3" // optional
      };

      Color _hexToColor(String hex) {
        if (hex.isEmpty) return Colors.transparent;
        hex = hex.replaceAll("#", "");
        if (hex.length == 6) {
          hex = "FF$hex";
        }
        return Color(int.parse(hex, radix: 16));
      }

      if (colorThemeDetail.containsKey(status)) {
        statusDots[date] = _hexToColor(colorThemeDetail[status]!);
      } else {
        statusDots[date] = Colors.grey;
      }
    });
    return statusDots;
  }

  String getMonthNumber(String monthName) {
    const monthMap = {
      'January': '01',
      'February': '02',
      'March': '03',
      'April': '04',
      'May': '05',
      'June': '06',
      'July': '07',
      'August': '08',
      'September': '09',
      'October': '10',
      'November': '11',
      'December': '12',
    };
    return monthMap[monthName]!;
  }

  void updateFocusedDay(String year, String month) {
    final yearInt = int.parse(year);
    final monthInt = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ].indexOf(month) +
        1;
    print('===> ${yearInt}');
    print('===> ${monthInt}');
    setState(() {
      focusedDay = DateTime.utc(
          yearInt, monthInt, 1); // Set the first day of the selected month
    });
  }

  Future<void> fetchAttendance() async {
    print('starting');
    DateTime now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    String? empNo = await prefs.getString('userName');
    String? Token = await prefs.getString('apiToken');
    setState(() {
      empId = empNo;
      apiToken = Token;
      selectedYear = now.year.toString();
      selectedMonth = DateFormat.MMMM().format(now);
      focusedDay = DateTime.utc(int.parse(selectedYear!), now.month, 1);
    });
    try {
      var attendance = await AttendanceServices().fetchAttendancePunch(
        empId: empId!,
        month: getMonthNumber(selectedMonth),
        year: selectedYear!,
        token: Token!,
      );
      print(attendance?['colorThemeDetail']);
      setState(() {
        statusDots = getStatusColorMap(attendance?['attendance']);
      });
      print('Attendance Punch: $attendance');
    } catch (e) {
      print('Error fetching attendance punch: $e');
    }
  }

  Future<void> updateAttendance(String year) async {
    final prefs = await SharedPreferences.getInstance();
    String? Token = await prefs.getString('apiToken');
    print('Updating ${year}');
    try {
      var attendance = await AttendanceServices().fetchAttendancePunch(
        empId: empId!,
        month: getMonthNumber(selectedMonth),
        year: year,
        token: Token!,
      );
      final Map<String, dynamic> attendanceData = attendance?[1] ?? {};
      print(attendanceData);
      // statusDots =
      setState(() {
        statusDots = getStatusColorMap(attendance?['attendance']);
      });
      print('Attendance Punch: $attendance');
    } catch (e) {
      print('Error fetching attendance punch: $e');
    }
  }

  Future<void> updateMonthAttendance(String month) async {
    final prefs = await SharedPreferences.getInstance();
    String? Token = await prefs.getString('apiToken');
    print('Updating ${month}');
    try {
      var attendance = await AttendanceServices().fetchAttendancePunch(
        empId: empId!,
        month: getMonthNumber(month),
        year: selectedYear!,
        token: Token!,
      );
      final Map<String, dynamic> attendanceData = attendance?[1] ?? {};
      print(attendanceData);
      setState(() {
        statusDots = getStatusColorMap(attendance?['attendance']);
      });
      print('Attendance Punch: $attendance');
    } catch (e) {
      print('Error fetching attendance punch: $e');
    }
  }

  Future<void> updateMonthAndYearAttendance(String year, String month) async {
    final prefs = await SharedPreferences.getInstance();
    String? Token = await prefs.getString('apiToken');
    print('Updating ${month}');
    print('Updating ${year}');
    try {
      var attendance = await AttendanceServices().fetchAttendancePunch(
        empId: empId!,
        month: month,
        year: year,
        token: Token!,
      );
      setState(() {
        statusDots = getStatusColorMap(attendance?['attendance']);
      });
      print('Attendance Punch: $attendance');
      print('Attendance Punch: $statusDots');
    } catch (e) {
      print('Error fetching attendance punch: $e');
    }
  }

  // Helper to convert hex string to Color
  Color hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) {
      hex = "FF$hex"; // Add full opacity if not specified
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    // These would come from your API response
    final Map<String, String> namedThemeDetail = {
      "PR": "Present",
      "AB": "Absent",
      "OD": "On Duty",
      "CO": "Comp off",
      "HO": "Festival or National Holiday",
      "LE": "Leaves",
      "HD": "Half Day Present",
      "NPD": "NPD",
      "WO": "Week off",
      "FF": "Fifty Fifty",
      "BT": "Business Travel",
      "SP": "Single Punch"
    };

    final Map<String, String> colorThemeDetail = {
      "PR": "#008000",
      "AB": "#ff0000",
      "OD": "#74bb5e",
      "CO": "#6b94b0",
      "HO": "#db0592",
      "LE": "#4663a9",
      "HD": "#e67b10",
      "NPD": "#773c3e",
      "WO": "#7e4d90",
      "FF": "#deb887",
      "BT": "#03fcdb",
      "SP": "#0c0c9b",
      "FUD": ""
    };

    Widget _drawerItem({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(icon, color: Colors.blue.shade800),
            ),
            title: Text(label),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: onTap,
          ),
        ),
      );
    }

    // Combine them into a list of name + color pairs
    final List<Map<String, dynamic>> attendanceLegend = namedThemeDetail.entries
        .where((e) => colorThemeDetail[e.key]?.isNotEmpty ?? false)
        .map((e) => {
              'label': e.value,
              'color': hexToColor(colorThemeDetail[e.key]!),
            })
        .toList();

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("My Attendance", style: TextStyle(color: Colors.white)),
            Spacer(),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_open),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
        backgroundColor: Color(widget.barColor),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerItem(
                      icon: Icons.calendar_today,
                      label: 'Holidays',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HolidayPage()),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.compare_arrows,
                      label: 'Approver & Requestor',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ApproverPage()),
                        );
                      },
                    ),
                    _drawerItem(
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DashboardPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(widget.genderColor),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.empId} - ${widget.name}",
                              style: const TextStyle(
                                  fontSize: 19,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${widget.designation}",
                              style: const TextStyle(
                                  fontSize: 19,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  buildDropdown(
                    selectedYear!,
                    ['2023', '2024', '2025', '2026'],
                    (String? newValue) {
                      setState(() {
                        selectedYear = newValue!;
                      });
                      updateFocusedDay(selectedYear!, selectedMonth);
                      updateAttendance(selectedYear!);
                    },
                  ),
                  const SizedBox(width: 12),
                  buildDropdown(
                    selectedMonth,
                    [
                      'January',
                      'February',
                      'March',
                      'April',
                      'May',
                      'June',
                      'July',
                      'August',
                      'September',
                      'October',
                      'November',
                      'December'
                    ],
                    (String? newValue) {
                      setState(() {
                        selectedMonth = newValue!;
                      });
                      updateFocusedDay(selectedYear!, selectedMonth);
                      updateMonthAttendance(selectedMonth);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: focusedDay,
                  pageJumpingEnabled: false,
                  pageAnimationEnabled: false,
                  availableGestures: AvailableGestures.none,
                  calendarStyle: CalendarStyle(
                    markerDecoration:
                        const BoxDecoration(shape: BoxShape.circle),
                    markersAlignment: Alignment.bottomCenter,
                    defaultTextStyle: const TextStyle(color: Colors.black),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, _) {
                      final DateTime normalizedDate =
                          DateTime(date.year, date.month, date.day);
                      final DateTime today = DateTime.now();
                      final DateTime normalizedToday =
                          DateTime(today.year, today.month, today.day);

                      final bool isFuture =
                          normalizedDate.isAfter(normalizedToday);

                      if (statusDots.containsKey(normalizedDate)) {
                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: statusDots[
                                normalizedDate], // Color based on status
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isFuture ? Colors.black : Colors.white,
                            ),
                          ),
                        );
                      }
                      return null; // Default rendering for other dates
                    },
                    todayBuilder: (context, date, _) {
                      final DateTime normalizedDate =
                          DateTime(date.year, date.month, date.day);

                      if (statusDots.containsKey(normalizedDate)) {
                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: statusDots[normalizedDate],
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.blue,
                                width: 1.5), // Optional highlight
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      // Highlight today normally if not in statusDots
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    leftChevronVisible: false,
                    rightChevronVisible: false,
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.black),
                    weekendStyle: TextStyle(color: Colors.red),
                  ),
                  selectedDayPredicate: (day) => false,
                  onDaySelected: (selectedDay, focusedDay) {},
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: attendanceLegend.map((entry) {
                    return Container(
                      width: 100, // Fixed width for all boxes
                      height: 100, // Fixed height for uniformity
                      margin: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              entry['label'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              color: entry['color'],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            )

            // const Padding(
            //   padding: EdgeInsets.only(bottom: 16.0),
            //   child: Text(
            //     "For details of daily attendance, please contact your branch",
            //     style: TextStyle(
            //       color: Colors.grey,
            //       fontSize: 12,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavBar(context, widget.barColor),
    );
  }
}

Widget buildBottomNavBar(BuildContext context, int barColor) {
  return SizedBox(
    height: 50,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Color(barColor),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
        ),
        // home button
        Positioned(
          bottom: 20,
          left: 40,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF21465B),
                ),
                child: IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 4),
              const CircleAvatar(radius: 4, backgroundColor: Colors.white),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 40,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
              icon: const Icon(Icons.person, color: Color(0xFF21465B)),
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
              },
            ),
          ),
        ),
        Positioned(
          top: -1,
          left: MediaQuery.of(context).size.width / 2 - 60,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21465B),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Text("SOS",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}

List<Map<String, dynamic>> convertDayWiseToList(
    Map<String, dynamic> dayWiseDetails) {
  return dayWiseDetails.entries.map((entry) {
    final int day = int.parse(entry.key);
    final date = DateTime(2025, 3, day); // month/year could be dynamic
    return {
      'date': date.toIso8601String(),
      'startTime': entry.value['startTime'],
      'endTime': entry.value['endTime'],
    };
  }).toList();
}

class AttendanceService {
  Future<List<dynamic>?> fetchAttendancePunch({
    required String empId,
    required String month,
    required String year,
    required String token,
  }) async {
    final String url =
        'http://hrmwebapi.lemeniz.com/api/Attendance/GetEmployeeAttendancePunch?month=$month&year=$year';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: ApiHeaders.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Attendance Data: $data");
        print('===> ${data['attendance']}');
        return data;
      } else {
        print('Failed to fetch attendance. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching attendance punch: $e');
      return null;
    }
  }
}

class AttendanceServices {
  Future<Map<String, dynamic>?> fetchAttendancePunch({
    required String empId,
    required String month,
    required String year,
    required String token,
  }) async {
    final String url =
        'http://hrmwebapi.lemeniz.com/api/Attendance/GetEmployeeAttendancePunch?month=$month&year=$year';
    print(empId);
    print(month);
    print(year);
    print(token);
    print(url);
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: ApiHeaders.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Attendance Data: $data");
        print('===> ${data['attendance']}');
        return Map<String, dynamic>.from(data);
      } else {
        print('Failed to fetch attendance. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching attendance punch: $e');
      return null;
    }
  }
}

class AlertPage extends StatefulWidget {
  final String name;

  const AlertPage({super.key, required this.name});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  List<dynamic> alertData = [];
  File? _capturedImage;
  String? punchStatus;
  String? formattedDate;
  String? formattedTime;
  bool? isLoggedIn;

  @override
  void initState() {
    _cameraController?.dispose();
    super.initState();
    fetchAllLogs();
    checkPunch();
    checkRegister();
  }

  void checkRegister() async {
     isLoggedIn = await getBool('isRegister');
    print('Logged in: $isLoggedIn');
  }

  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> registerFirst(String base64Image, String punchStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    // Get current date and time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy').format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);

    // Request location permission and get current position
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Construct request body
    Map<String, String> body = {
      "Remarks": "Face recognized - $punchStatus punch",
      "Date": formattedDate,
      "Time": formattedTime,
      "Punch": punchStatus,
      "File": base64Image,
      "Mime": "image/jpeg",
      "Lat": position.latitude.toString(),
      "Lng": position.longitude.toString(),
    };

    final response = await http.post(
      Uri.parse('http://hrmwebapi.lemeniz.com/api/Attendance/AddPunch'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('✅ Punch Registered: ${response.body}');
      await saveBool('isRegister', true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(capturedImage: _capturedImage!),
        ),
      );
    } else {
      print('❌ Punch Failed: ${response.statusCode} - ${response.body}');
    }
  }



  Future<void> registerPunch(String base64Image, String punchStatus) async {
    if(isLoggedIn == false) {
      print('isLoggedIn == true');
      registerFirst(base64Image,punchStatus);
    } else if (isLoggedIn == true) {
      print('isLoggedIn == false');
      verifyPhoto(base64Image);
    }


  }


  Future<void> verifyPhoto(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';

    print('imagePath : $imagePath');

    Map<String,String> body = {
      "File": imagePath
    };

    final response = await http.post(
      Uri.parse('http://hrmwebapi.lemeniz.com/api/Attendance/VerifyImage'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    bool isMatch = data['match'];

    if (isMatch == true) {
      registerFirst(imagePath,punchStatus!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo Unmatched! Please Try Again'),
          backgroundColor: Colors.red,
        ),
      );
      print("Verification Failed: ${response.statusCode}");
    }
  }

  Future<void> checkPunch() async {
    final prefs = await SharedPreferences.getInstance();
    String? Token = await prefs.getString('apiToken');
    const String apiUrl =
        "http://hrmwebapi.lemeniz.com/api/Attendance/GetPunchDetail";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $Token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        log('data: $data');

        Map<String, dynamic> lastEntry = data.last;

        // Print the whole last object
        print("Last Entry: ${lastEntry['punch']}");

        if (lastEntry['punch'] == 'IN' || lastEntry['punch'] == 'In') {
          setState(() {
            punchStatus = 'OUT';
            DateTime parsedDateTime = DateTime.parse(lastEntry['punchTime']);

            formattedDate = DateFormat('dd-MM-yyyy').format(parsedDateTime);
            formattedTime = DateFormat('hh:mm a').format(parsedDateTime);
          });
        } else if (lastEntry['punch'] == 'OUT' || lastEntry['punch'] == 'Out') {
          setState(() {
            punchStatus = 'IN';
            DateTime parsedDateTime = DateTime.parse(lastEntry['punchTime']);

            formattedDate = DateFormat('dd-MM-yyyy').format(parsedDateTime);
            formattedTime = DateFormat('hh:mm a').format(parsedDateTime);
          });
        }
      } else {
        print("❌ Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }

  Future<void> requestCameraPermissions() async {
    await [
      Permission.camera,
      Permission.photos, // for iOS
      Permission.storage, // Android only, may be ignored on Android 13+
    ].request();
  }

  Future<void> fetchAllLogs() async {
    List<LogEntry> logs = await LogDatabase.instance.getLogs();
    setState(() {
      alertData = logs
          .map((log) => {
                'date': '${log.date}\n${log.time}',
                'name': widget.name,
                'latitude': log.latitude,
                'longitude': log.longitude,
              })
          .toList();
    });
  }

  Future<String?> pickImageAndConvertToBase64() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera); // or gallery

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      return base64Encode(bytes);
    }

    return null;
  }

  Future<void> verifyFaceImage() async {
    final imageBase64 = await pickImageAndConvertToBase64();
    if (imageBase64 == null) {
      print("Image not selected.");
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('apiToken'); // Ensure token is saved after login

    final url =
        Uri.parse('http://hrmwebapi.lemeniz.com/api/Attendance/VerifyImage');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "File": imageBase64,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print('Face verified successfully: ${response.body}');
      // Handle result here
    } else {
      print('Failed to verify face. Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  }

  Future<void> _openCamera(String punchStatus) async {
    await requestCameraPermissions();
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);
      final inputImage = InputImage.fromFile(imageFile);

      final faceDetector = FaceDetector(
        options:
            FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected. Please try again.')),
        );
        return;
      }

      _capturedImage = imageFile;
      if (!mounted) return;
      if (await imageFile.exists()) {
        _capturedImage = imageFile;

        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        print('BaseImage: $base64Image');

        // if (!mounted) return;
        registerPunch(base64Image, punchStatus);

      } else {
        print("Captured image does not exist.");
      }
    } catch (e) {
      print("Camera error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }



  void _openMap(String latitude, String longitude) async {
    final Uri googleMapUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

    try {
      await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("Failed to launch map: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Alert", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F4787),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(children: [Container(height: 150)]),
            const SizedBox(height: 30),

            // --- "I Am Alert" Camera Box ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _openCamera(punchStatus!);
                    },
                    child: Column(
                      children: [
                        Text(
                          "Punch",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 15),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              center: Alignment(-0.3, -0.3),
                              radius: 0.8,
                              colors: [
                                Color(0xFFE0E0E0), // light gray center
                                Color(0xFFB0B0B0), // darker edge
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              punchStatus ?? 'IN',
                              style: TextStyle(
                                color: (punchStatus ?? 'IN') == 'IN'
                                    ? Colors.green
                                    : (punchStatus == 'OUT' ? Colors.red : Colors.black),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                                children: [
                                  const TextSpan(text: 'Last Attendance Marked : '),
                                  TextSpan(
                                    text: punchStatus == 'IN'
                                        ? 'OUT'
                                        : punchStatus == 'OUT'
                                        ? 'IN'
                                        : punchStatus ?? '',
                                    style: TextStyle(
                                      color: punchStatus == 'IN'
                                          ? Colors.red
                                          : punchStatus == 'OUT'
                                          ? Colors.green
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(' (${formattedDate} : ${formattedTime})')


                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Panic Alert Table ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: alertData.isEmpty
                  ? const Center(child: Text("No panic alerts found."))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 35,
                        headingRowColor:
                            MaterialStateProperty.all(const Color(0xFFF464BB)),
                        headingTextStyle: const TextStyle(color: Colors.white),
                        columns: const [
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("EmpName")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: alertData.map((alert) {
                          return DataRow(cells: [
                            DataCell(Text(alert["date"]!)),
                            DataCell(Text(alert["name"]!)),
                            DataCell(
                              InkWell(
                                onTap: () {
                                  final latitude = alert["latitude"];
                                  final longitude = alert["longitude"];
                                  if (latitude != null && longitude != null) {
                                    _openMap(latitude.toString(),
                                        longitude.toString());
                                  }
                                },
                                child: Row(
                                  children: const [
                                    Icon(Icons.remove_red_eye,
                                        color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text("View",
                                        style: TextStyle(color: Colors.blue)),
                                  ],
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _cameraController {
  static void dispose() {}
}

class ApiHeaders {
  static Map<String, String> getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}

class LogPage extends StatefulWidget {
  final String name;

  const LogPage({super.key, required this.name});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with TickerProviderStateMixin {
  String? empId;
  String? empName;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  int selectedMonthIndex = DateTime.now().month;
  late String selectedMonth;

  List<Map<String, dynamic>> punchLogs = [];
  List<Map<String, dynamic>> animatedLogs = [];
  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];

  @override
  void initState() {
    super.initState();
    selectedMonth = months[selectedMonthIndex - 1];
    fetchDetails(selectedMonthIndex, DateTime.now().year);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String getWeekdayFromDate(DateTime date) {
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return weekdays[date.weekday % 7];
  }

  Future<void> fetchDetails(int month, int year) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('apiToken');
    if (token == null) return;

    empId = prefs.getString('userName') ?? empId;
    empName = prefs.getString('empName') ?? widget.name;

    final String url =
        'http://hrmwebapi.lemeniz.com/api/Attendance/GetRawPunchDetails?month=$month&year=$year';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: ApiHeaders.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Clean up
          for (final c in _controllers) {
            c.dispose();
          }
          _controllers.clear();
          _animations.clear();
          punchLogs.clear();
          animatedLogs.clear();

          setState(() {}); // show blank

          for (var punch in data) {
            String dateTime = punch['swipeDateTime'];
            DateTime dt = DateTime.parse(dateTime);

            punchLogs.add({
              'date': dt.day.toString().padLeft(2, '0'),
              'day': getWeekdayFromDate(dt),
              'time': dateTime.substring(11, 19),
              'status': punch['punch'],
              'color': punch['punch'].toLowerCase() == 'in' ? 'green' : 'red',
              'location': punch['readerName'] ?? 'Unknown',
            });
          }

          // Descending order (latest first)
          punchLogs = punchLogs.reversed.toList();

          for (int i = 0; i < punchLogs.length; i++) {
            final controller = AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 500),
            );
            final animation = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOut));

            _controllers.add(controller);
            _animations.add(animation);
          }

          for (int i = 0; i < punchLogs.length; i++) {
            await Future.delayed(const Duration(milliseconds: 250));
            if (!mounted) return;
            _controllers[i].forward();
            setState(() {
              animatedLogs.add(punchLogs[i]);
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching log data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Activity Log", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F4787),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_open, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blueAccent],
                  ),
                ),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              _drawerItem(
                icon: Icons.calendar_today,
                label: 'Holidays',
                onTap: () {},
              ),
              _drawerItem(
                icon: Icons.compare_arrows,
                label: 'Approver & Requestor',
                onTap: () {},
              ),
              _drawerItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4787),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMonth,
                        dropdownColor: const Color(0xFF0F4787),
                        iconEnabledColor: Colors.white,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: months.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Center(
                                child: Text(month,
                                    style:
                                        const TextStyle(color: Colors.white))),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMonth = value;
                              selectedMonthIndex = months.indexOf(value) + 1;
                            });
                            fetchDetails(
                                selectedMonthIndex, DateTime.now().year);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    fetchDetails(selectedMonthIndex, DateTime.now().year);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4787),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child:
                      const Text('View', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: animatedLogs.length,
              itemBuilder: (context, index) {
                final log = animatedLogs[index];
                final animation = _animations[index];

                return SlideTransition(
                  position: animation,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3))
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(log['date'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              Text(log['day'],
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Employee ID : ${empId ?? 'N/A'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Name : ${widget.name}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _pill(log['time'], const Color(0xFF0F4787)),
                                  const SizedBox(width: 8),
                                  _pill(
                                      log['status'],
                                      log['color'] == 'green'
                                          ? Colors.green
                                          : Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(log['location'],
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue.shade800),
          ),
          title: Text(label),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      ),
    );
  }
}

class ManualPunchPage extends StatefulWidget {
  const ManualPunchPage({super.key});

  @override
  _ManualPunchPageState createState() => _ManualPunchPageState();
}

class _ManualPunchPageState extends State<ManualPunchPage> {
  // Sample API URL (change this to your actual API URL)
  final String apiUrl = 'https://your-api-url.com/manual-punch';
  final String employeeDetailsUrl = 'https://your-api-url.com/employee-details';

  bool isLoading = false;
  String? scheduleMessage;

  @override
  void initState() {
    super.initState();
    _fetchScheduleDetails();
  }

  // Fetch schedule details from the API
  Future<void> _fetchScheduleDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(employeeDetailsUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          scheduleMessage = "Schedule details fetched successfully";
        });
      } else {
        setState(() {
          scheduleMessage = "Failed to fetch schedule details";
        });
      }
    } catch (e) {
      setState(() {
        scheduleMessage = "Error fetching schedule details";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Submit manual punch data to the API
  Future<void> _submitManualPunch(String punchType) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'employee_id': '0000451053',
          'punch_type': punchType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Punch submitted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit punch")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting punch: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Manual Punch", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F4787),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  // Week Tabs
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     _buildDateTab("WED", "26-06-2024", isSelected: true),
                  //     _buildDateTab("TUE", "27-06-2024"),
                  //     _buildDateTab("FRI", "28-06-2024"),
                  //     _buildDateTab("SAT", "29-06-2024"),
                  //   ],
                  // ),
                  const SizedBox(height: 24),

                  // Employee Info
                  const Text(
                    " DHARANI KUMAR B",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  // const Text(
                  //   "033718, Hanon Automotive System India\nAI - SRI , CCs - Melrosepuram post Kelakaranai Village,\nMaraimalai Nagar , Chengalpattu.",
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(fontSize: 13, color: Colors.black87),
                  // ),
                  const SizedBox(height: 24),

                  // Duty Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _DutyDetailRow(
                            label: "POST", value: "FRONT OFF 1_8_8_6"),
                        SizedBox(height: 8),
                        _DutyDetailRow(label: "SHIFT", value: "A"),
                        SizedBox(height: 8),
                        _DutyDetailRow(label: "START", value: "07.00"),
                        SizedBox(height: 8),
                        _DutyDetailRow(label: "END", value: "15.00"),
                        SizedBox(height: 8),
                        _DutyDetailRow(label: "SORANK", value: "LADY_GUARD"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success Message
                  if (scheduleMessage != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scheduleMessage!,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),

                  // Manual Punch Buttons
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _submitManualPunch("IN"),
                        child: const Text("Punch In"),
                      ),
                      ElevatedButton(
                        onPressed: () => _submitManualPunch("OUT"),
                        child: const Text("Punch Out"),
                      ),
                    ],
                  )
                ],
              ),
            ),
      backgroundColor: const Color(0xFFF5F5F5),

      // Custom Curved Bottom Navigation Bar with SOS
      bottomNavigationBar: SizedBox(
        height: 50,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background bar
            Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xfff67ea6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
            ),

            // Home Button (left)
            Positioned(
              bottom: 20,
              left: 40,
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF21465B),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.home, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  const CircleAvatar(radius: 4, backgroundColor: Colors.white),
                ],
              ),
            ),

            // Profile Button (right)
            Positioned(
              bottom: 20,
              right: 40,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.person, color: Color(0xFF21465B)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilePage(
                                genderPhoto: '',
                              )),
                    );
                  },
                ),
              ),
            ),

            // SOS Button (center)
            Positioned(
              top: -1,
              left: MediaQuery.of(context).size.width / 2 - 60,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21465B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: const Text("SOS",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTab(String day, String date, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0F4787) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0F4787)),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DutyDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DutyDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label :",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}

// Replace with your actual token handling
// const String token =
//     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJBVDAwOTkiLCJqdGkiOiI2ZDI0M2RiNi0zNTc2LTQzNDktYmEyYy1jMGFiMmI3ZTMxYTMiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjExY2MzNGM0LTI5ZTgtNDFmMS1iNmI4LTU4YTgzZDAyNzk0YSIsImh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3dzLzIwMDUvMDUvaWRlbnRpdHkvY2xhaW1zL25hbWUiOiJBVDAwOTkiLCJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvY2xhaW1zL3JvbGUiOlsiRW1wbG95ZWVBVCIsIkVtcGxveWVlIiwiVHJhaW5pbmdNYW5hZ2VtZW50IiwiRGFzaGJvYXJkIiwiTGVhdmVQZXJtaXNzaW9uUmVxdWVzdCIsIlZpc2l0b3JNYW5hZ2VtZW50Il0sImV4cCI6MTc0Njc4OTY1OSwiaXNzIjoiSFJNIiwiYXVkIjoiSFJNQXBwVXNlcnMifQ.dcsZ2sZOe2yBcfX59jAiZ1AcCk3_KiHb17DMblm9ozY';

class ApplyLeavePage extends StatefulWidget {
  final String employeeId;
  final String token;

  const ApplyLeavePage({
    Key? key,
    required this.employeeId,
    required this.token,
  }) : super(key: key);

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;
  String _halfDaySession = "1st Half";
  int _selectedLeaveTypeId = 3;
  File? _selectedFile;
  int availableLeave = 10;
  List<Map<String, dynamic>> approvers = [];
  String? selectedApproverId;

  final Map<int, String> leaveTypes = {
    1: 'Casual Leave',
    2: 'Earned Leave',
    3: 'Sick Leave / Medical Leave',
    4: 'Comp Off',
    5: 'Marriage Leave',
    6: 'Paternity Leave',
    7: 'Condolence Leave',
  };

  @override
  void initState() {
    super.initState();
    fetchApprovers();
  }

  Future<void> fetchApprovers() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = await prefs.getString('apiToken');
    print('Token : $token');
    final response = await http.get(
      Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/Leave/GetAllApprover?empid=${widget.employeeId}'),
      headers: {'Authorization': 'Bearer ${token}'},
    );
    print(response);
    print(widget.token);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print(data);
      setState(() {
        approvers = data.map<Map<String, dynamic>>((item) {
          return {"id": item["userId"], "name": item["userName"]};
        }).toList();
        if (approvers.isNotEmpty) {
          selectedApproverId = approvers[0]["id"];
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load approvers")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  int _calculateLeaveDays() {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 0;
  }

  Future<void> applyLeave() async {
    final prefs = await SharedPreferences.getInstance();
    String? tokenApi = prefs.getString('apiToken');

    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null ||
        selectedApproverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final int leaveDays = _calculateLeaveDays();

    if (leaveDays > 1 && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please attach a file for more than 1 day leave")),
      );
      return;
    }

    final url =
        Uri.parse('http://hrmwebapi.lemeniz.com/api/Leave/AddLeaveEntry');

    final mimeType =
        _selectedFile != null ? _selectedFile!.path.split('.').last : null;

    final Map<String, dynamic> payload = {
      "Reason": _reasonController.text.trim(),
      "From": DateFormat("dd-MM-yyyy").format(_startDate!),
      "To": DateFormat("dd-MM-yyyy").format(_endDate!),
      "LeaveTypeId": _selectedLeaveTypeId,
      "IsHalfDay": _isHalfDay,
      "HalfDayPart":
          _isHalfDay ? (_halfDaySession == "1st Half" ? 1 : 2) : null,
      "ApproverUserId": selectedApproverId,
      "File": "", // ignore or base64 string if required
      "Mime": mimeType ?? '',
      "CreditRequestId": null
    };

    print(payload);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $tokenApi',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      final List<String> history = prefs.getStringList('leave_history') ?? [];
      history.add(jsonEncode({
        "reason": _reasonController.text,
        "from": _startDate.toString(),
        "to": _endDate.toString(),
        "type": leaveTypes[_selectedLeaveTypeId],
        "days": leaveDays,
        "approver": approvers.firstWhere(
          (a) => a['id'] == selectedApproverId,
          orElse: () => {"name": "Unknown"},
        )['name'],
        "status": "Pending"
      }));
      await prefs.setStringList('leave_history', history);

      Navigator.pop(context);
    } else {
      print('Failed: ${response.statusCode}');
      print('Response: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${response.statusCode}\n${response.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Leave")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Available Leave: $availableLeave",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                    labelText: 'Reason *', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Reason required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedLeaveTypeId,
                decoration: const InputDecoration(
                    labelText: 'Leave Type *', border: OutlineInputBorder()),
                items: leaveTypes.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child:
                        Text('${entry.key == 3 ? "SL – " : ""}${entry.value}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLeaveTypeId = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(_startDate == null
                          ? "From"
                          : "${_startDate!.day.toString().padLeft(2, '0')}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.year}"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(_endDate == null
                          ? "To"
                          : "${_endDate!.day.toString().padLeft(2, '0')}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.year}"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _isHalfDay,
                    onChanged: (val) => setState(() => _isHalfDay = val),
                  ),
                  const Text("Is Half Day"),
                ],
              ),
              if (_isHalfDay)
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("1st Half"),
                        value: "1st Half",
                        groupValue: _halfDaySession,
                        onChanged: (val) =>
                            setState(() => _halfDaySession = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("2nd Half"),
                        value: "2nd Half",
                        groupValue: _halfDaySession,
                        onChanged: (val) =>
                            setState(() => _halfDaySession = val!),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedApproverId,
                isExpanded: true, // Ensures full width in case names are long
                decoration: const InputDecoration(
                  labelText: 'Select Approver *',
                  border: OutlineInputBorder(),
                ),
                items: approvers.map((approver) {
                  return DropdownMenuItem<String>(
                    value: approver['id'],
                    child: Text(approver['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedApproverId = val!;
                  });
                },
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Please select an approver'
                    : null,
              ),
              if (_calculateLeaveDays() > 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text("Upload File (Max 100KB):"),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Choose File"),
                    ),
                    if (_selectedFile != null)
                      Text("Selected: ${_selectedFile!.path.split('/').last}"),
                  ],
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await applyLeave(); // call your leave submission logic
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LeaveHistoryPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Create",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Back"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Select an Option',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.check_circle_outline),
                                    title: const Text('Permission'),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // if needed to close a bottom sheet
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PermissionListPage()),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.work_outline),
                                    title: const Text('On Duty'),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // Close bottom sheet if necessary
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const OnDutyListPage()),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                        Icons.business_center_outlined),
                                    title: const Text('Business Travel'),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // Close modal if needed
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const BusinessTravelListPage()),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.credit_score_outlined),
                                    title: const Text('Comp. Off Credit'),
                                    onTap: () {
                                      Navigator.pop(
                                          context); // Close modal if present
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const CreditRequestPageListPage()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: const Text("Others"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _permissionOnController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  Future<void> submitPermissionRequest() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('apiToken');
      final userId = prefs.getString('userId');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      final url = Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/Permission/AddPermissionEntry');
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "Reason": _reasonController.text,
        "PermissionOn": _permissionOnController.text,
        "From": _fromController.text,
        "To": _toController.text,
        "ApproverUserId": userId,
      });

      print(body);

      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          // Store response if needed
          prefs.setString('lastPermissionRequest', body); // optional
          var bodyInfo = prefs.getString('lastPermissionRequest'); // optional
          print(bodyInfo);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission requested successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to permission list page after success
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PermissionListPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed: ${response.reasonPhrase} ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _permissionOnController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Permission")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "The 2-hour permission, available once every 3 months.",
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                  hintText: "Enter reason",
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _permissionOnController,
                decoration: const InputDecoration(
                  labelText: "Permission on",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('dd-MM-yyyy').format(pickedDate);
                    _permissionOnController.text = formattedDate;
                  }
                },
                validator: (value) =>
                    value!.isEmpty ? 'Permission date is required' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: "From",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'From time is required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: "To",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'To time is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: submitPermissionRequest,
                    child: const Text("Create"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("Back to List"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionListPage extends StatefulWidget {
  const PermissionListPage({super.key});

  @override
  State<PermissionListPage> createState() => _PermissionListPageState();
}

class _PermissionListPageState extends State<PermissionListPage> {
  late Future<List<dynamic>> _permissionList;

  @override
  void initState() {
    super.initState();
    _permissionList = fetchPermissionList();
  }

  Future<List<dynamic>> fetchPermissionList() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken');

    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse(
        'http://hrmwebapi.lemeniz.com/api/Permission/GetAllPermission');
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to load permissions');
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (_) {
      return 'Invalid date';
    }
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final parsedDate = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(parsedDate);
    } catch (_) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Permission List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Permission',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _permissionList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final permissionList = snapshot.data!;

          if (permissionList.isEmpty) {
            return const Center(child: Text("No permission entries found."));
          }

          return ListView.builder(
            itemCount: permissionList.length,
            itemBuilder: (context, index) {
              final item = permissionList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(item['title'] ?? 'No Reason'),
                  subtitle: Text(
                    "Date: ${formatDate(item['createdOn'])}\n"
                    "From: ${formatDateTime(item['startOn'])} - To: ${formatDateTime(item['endOn'])}",
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OnDutyPage extends StatefulWidget {
  const OnDutyPage({super.key});

  @override
  State<OnDutyPage> createState() => _OnDutyPageState();
}

class _OnDutyPageState extends State<OnDutyPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _onDutyOnController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  Future<void> submitOnDutyRequest() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('apiToken');
      final userId = prefs.getString('userId');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token not found. Please login again.")),
        );
        return;
      }

      final url =
          Uri.parse("http://hrmwebapi.lemeniz.com/api/OnDuty/AddOnDutyEntry");
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "Reason": _reasonController.text,
        "From": _fromController.text,
        "To": _toController.text,
        "OnDutyOn": _onDutyOnController.text,
        "ApproverUserId": userId,
      });

      print(body);

      try {
        final response = await http.post(url, headers: headers, body: body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("On Duty request submitted successfully!")),
          );

          // Navigate to OnDutyListPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnDutyListPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Failed to submit: ${response.body} (${response.statusCode})")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request On Duty")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason *",
                  border: OutlineInputBorder(),
                  hintText: "Enter reason",
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _onDutyOnController,
                decoration: const InputDecoration(
                  labelText: "On Duty On *",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('dd-MM-yyyy').format(pickedDate);
                    _onDutyOnController.text = formattedDate;
                  }
                },
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: "From *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: "To *",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: submitOnDutyRequest,
                    child: const Text("Create"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("Back to List"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnDutyListPage extends StatefulWidget {
  const OnDutyListPage({super.key});

  @override
  State<OnDutyListPage> createState() => _OnDutyListPageState();
}

class _OnDutyListPageState extends State<OnDutyListPage> {
  List<dynamic> _onDutyList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchOnDutyList();
  }

  Future<void> fetchOnDutyList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('apiToken');

      if (token == null) {
        setState(() {
          _error = "Token not found. Please login again.";
          _isLoading = false;
        });
        return;
      }

      final url =
          Uri.parse("http://hrmwebapi.lemeniz.com/api/OnDuty/GetAllOnDuty");
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _onDutyList = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              "Failed to load data: ${response.statusCode} ${response.body}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _isLoading = false;
      });
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (_) {
      return 'Invalid date';
    }
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'N/A';
    try {
      final parsedDate = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(parsedDate);
    } catch (_) {
      return 'Invalid date';
    }
  }

  Widget buildList() {
    if (_onDutyList.isEmpty) {
      return const Center(child: Text("No On Duty entries found."));
    }

    return ListView.builder(
      itemCount: _onDutyList.length,
      itemBuilder: (context, index) {
        final entry = _onDutyList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text("Reason: ${entry['title'] ?? ''}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("On Duty On: ${formatDate(entry['createdOn'])}"),
                Text(
                    "From: ${formatDateTime(entry['startOn'])} To: ${formatDateTime(entry['endOn'])}"),
                Text("Status: ${entry['leaveEntryStatus'] ?? 'Pending'}"),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("On Duty List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New On Duty Request',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OnDutyPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: fetchOnDutyList,
                  child: buildList(),
                ),
    );
  }
}

class BusinessTravelPage extends StatefulWidget {
  const BusinessTravelPage({super.key});

  @override
  State<BusinessTravelPage> createState() => _BusinessTravelPageState();
}

class _BusinessTravelPageState extends State<BusinessTravelPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  Future<void> _pickDateTime(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        controller.text = DateFormat("dd-MM-yyyy").format(dateTime);
      }
    }
  }

  Future<void> submitBusinessTravel() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('apiToken');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token or User ID not found.")),
        );
        return;
      }

      final url = Uri.parse(
          "http://hrmwebapi.lemeniz.com/api/BusinessTravel/AddBusinessTravelEntry");

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "Reason": _reasonController.text,
        "From": _fromController.text,
        "To": _toController.text,
        "ApproverUserId": userId,
      });

      print(body);

      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Business travel request submitted successfully!")),
          );
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BusinessTravelListPage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to submit: ${response.body}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Business Travel")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason *",
                  border: OutlineInputBorder(),
                  hintText: "Enter reason for business travel",
                ),
                validator: (value) =>
                    value!.isEmpty ? "Reason is required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: "From *",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _pickDateTime(_fromController),
                validator: (value) =>
                    value!.isEmpty ? "From date/time is required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: "To *",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _pickDateTime(_toController),
                validator: (value) =>
                    value!.isEmpty ? "To date/time is required" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: submitBusinessTravel,
                    child: const Text("Create"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text("Back to List"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BusinessTravelListPage extends StatefulWidget {
  const BusinessTravelListPage({super.key});

  @override
  State<BusinessTravelListPage> createState() => _BusinessTravelListPageState();
}

class _BusinessTravelListPageState extends State<BusinessTravelListPage> {
  List<dynamic> travelList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBusinessTravelList();
  }

  Future<void> fetchBusinessTravelList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('apiToken');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token or User ID missing.")),
        );
        return;
      }

      final url = Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/BusinessTravel/GetAllBusinessTravel');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          travelList = data ?? [];
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e")),
      );
      setState(() => isLoading = false);
    }
  }

  String formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd MM yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  Widget buildTravelItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(item['title'] ?? 'No Reason'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: ${formatDate(item['startOn'] ?? '')}"),
            Text("To: ${formatDate(item['endOn'] ?? '')}"),
            Text("Status: ${item['leaveEntryStatus'] ?? 'Pending'}"),
          ],
        ),
        isThreeLine: true,
        leading: const Icon(Icons.business_center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Business Travel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Business Travel',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BusinessTravelPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : travelList.isEmpty
                ? const Center(child: Text("No business travel entries found."))
                : ListView.builder(
                    itemCount: travelList.length,
                    itemBuilder: (context, index) {
                      return buildTravelItem(travelList[index]);
                    },
                  ),
      ),
    );
  }
}

class CreditRequestPage extends StatefulWidget {
  const CreditRequestPage({super.key});

  @override
  State<CreditRequestPage> createState() => _CreditRequestPageState();
}

class _CreditRequestPageState extends State<CreditRequestPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _creditRequestOnController =
      TextEditingController();
  String? shiftType; // This maps to CreditRequestId

  Future<void> submitCreditRequest() async {
    if (_formKey.currentState!.validate() && shiftType != null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('apiToken');
      final userId = prefs.getString('userId');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token not found. Please login again.")),
        );
        return;
      }

      final url = Uri.parse(
          "http://hrmwebapi.lemeniz.com/api/CreditRequest/AddCreditRequestEntry");

      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = jsonEncode({
        "Reason": _reasonController.text,
        "CreditRequestOn": _creditRequestOnController.text,
        "CreditRequestId": shiftType,
        "ApproverUserId": userId,
      });

      print(body);

      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Credit request submitted successfully!")),
          );
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreditRequestPageListPage(),
              ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${response.body}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } else if (shiftType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a shift type.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Credit Request")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: "Reason *",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Reason is required"
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _creditRequestOnController,
                decoration: const InputDecoration(
                  labelText: "Credit Request On *",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    String formattedDate =
                        DateFormat('dd-MM-yyyy').format(pickedDate);
                    _creditRequestOnController.text = formattedDate;
                  }
                },
                validator: (value) =>
                    value!.isEmpty ? "Date is required" : null,
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text("Shift Continue"),
                value: "SC",
                groupValue: shiftType,
                onChanged: (value) => setState(() => shiftType = value),
              ),
              RadioListTile<String>(
                title: const Text("NPD"),
                value: "NPD",
                groupValue: shiftType,
                onChanged: (value) => setState(() => shiftType = value),
              ),
              RadioListTile<String>(
                title: const Text("50:50"),
                value: "FF",
                groupValue: shiftType,
                onChanged: (value) => setState(() => shiftType = value),
              ),
              RadioListTile<String>(
                title: const Text("Week-off(Sat/Sun)"),
                value: "WO",
                groupValue: shiftType,
                onChanged: (value) => setState(() => shiftType = value),
              ),
              RadioListTile<String>(
                title: const Text("Festival or National Holiday"),
                value: "HO",
                groupValue: shiftType,
                onChanged: (value) => setState(() => shiftType = value),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: submitCreditRequest,
                    child: const Text("Create"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("Back to List"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CreditRequestPageListPage extends StatefulWidget {
  const CreditRequestPageListPage({super.key});

  @override
  State<CreditRequestPageListPage> createState() =>
      _CreditRequestPageListPageState();
}

class _CreditRequestPageListPageState extends State<CreditRequestPageListPage> {
  List<dynamic> travelList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCreditRequestPageList();
  }

  Future<void> fetchCreditRequestPageList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('apiToken');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token or User ID missing.")),
        );
        return;
      }

      final url = Uri.parse(
          'http://hrmwebapi.lemeniz.com/api/CreditRequest/GetAllCreditRequest');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          travelList = data ?? [];
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e")),
      );
      setState(() => isLoading = false);
    }
  }

  String formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  Widget buildTravelItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(item['title'] ?? 'No Reason'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: ${formatDate(item['startOn'] ?? '')}"),
            Text("To: ${formatDate(item['endOn'] ?? '')}"),
            Text("Status: ${item['leaveEntryStatus'] ?? 'Pending'}"),
          ],
        ),
        isThreeLine: true,
        leading: const Icon(Icons.business_center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit RequestPage List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Credit Request',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreditRequestPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : travelList.isEmpty
                ? const Center(
                    child: Text("No CreditRequestPage entries found."))
                : ListView.builder(
                    itemCount: travelList.length,
                    itemBuilder: (context, index) {
                      return buildTravelItem(travelList[index]);
                    },
                  ),
      ),
    );
  }
}

class LeaveHistoryPage extends StatefulWidget {
  const LeaveHistoryPage({Key? key}) : super(key: key);

  @override
  State<LeaveHistoryPage> createState() => _LeaveHistoryPageState();
}

class _LeaveHistoryPageState extends State<LeaveHistoryPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> fullLeaveHistory = [];
  List<Map<String, dynamic>> animatedLeaveHistory = [];
  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaveHistory();
  }

  Future<void> fetchLeaveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenApi = prefs.getString('apiToken');

    if (tokenApi == null) {
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse('http://hrmwebapi.lemeniz.com/api/Leave/GetAllLeave');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $tokenApi',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      for (final c in _controllers) {
        c.dispose();
      }
      _controllers.clear();
      _animations.clear();

      fullLeaveHistory =
          data.cast<Map<String, dynamic>>().reversed.toList(); // descending

      // Create controllers for animations
      for (int i = 0; i < fullLeaveHistory.length; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        );

        final animation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

        _controllers.add(controller);
        _animations.add(animation);
      }

      setState(() {
        animatedLeaveHistory.clear(); // Show empty screen first
        isLoading = false;
      });

      // Show one by one with delay
      for (int i = 0; i < fullLeaveHistory.length; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        _controllers[i].forward();
        setState(() {
          animatedLeaveHistory.add(fullLeaveHistory[i]);
        });
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load leave history.')),
      );
    }
  }

  Future<void> cancelLeave(String leaveId) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenApi = prefs.getString('apiToken');
    if (tokenApi == null) return;

    final url = Uri.parse('http://hrmwebapi.lemeniz.com/api/Leave/CancelLeave');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $tokenApi',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"id": leaveId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Leave cancelled successfully."),
            backgroundColor: Colors.green),
      );
      fetchLeaveHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to cancel leave."),
            backgroundColor: Colors.red),
      );
    }
  }

  String formatDate(String date) {
    final parsed = DateTime.tryParse(date);
    return parsed == null
        ? date
        : "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leave History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Apply Leave',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplyLeavePage(
                    employeeId: 'empid', // replace dynamically
                    token: 'apiToken', // replace dynamically
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : animatedLeaveHistory.isEmpty
              ? const Center(child: Text("No leave applications found."))
              : ListView.builder(
                  itemCount: animatedLeaveHistory.length,
                  itemBuilder: (context, index) {
                    final entry = animatedLeaveHistory[index];
                    final status = entry['leaveEntryStatus'] ?? 'Pending';

                    return SlideTransition(
                      position: _animations[index],
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${entry['leaveType'] ?? 'N/A'} (${entry['days'] ?? 0} day${(entry['days'] ?? 0) > 1 ? 's' : ''})",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 10),
                                    Table(
                                      columnWidths: const {
                                        0: IntrinsicColumnWidth(),
                                        1: FlexColumnWidth(),
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            const Text("Reason:",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(entry['title'] ?? 'N/A'),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            const Text("From:",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(formatDate(
                                                entry['startOn'] ?? '')),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            const Text("To:",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(formatDate(
                                                entry['endOn'] ?? '')),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            const Text("Approver:",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(
                                                entry['approvedUserRealName'] ??
                                                    'N/A'),
                                          ],
                                        ),
                                        TableRow(
                                          children: [
                                            const Text("Status:",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(status),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (status.toLowerCase() == 'pending') ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          icon: const Icon(Icons.cancel,
                                              color: Colors.red),
                                          label: const Text("Cancel",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                          onPressed: () {
                                            final leaveId =
                                                entry['id']?.toString() ?? '';
                                            if (leaveId.isNotEmpty)
                                              cancelLeave(leaveId);
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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

class BiometricPage extends StatefulWidget {
  const BiometricPage({Key? key}) : super(key: key);

  @override
  State<BiometricPage> createState() => _BiometricPageState();
}

class _BiometricPageState extends State<BiometricPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String _authStatus = 'Please authenticate using fingerprint';

  Future<void> _authenticate() async {
    setState(() {
      _authStatus = 'Authenticating...';
    });

    try {
      final bool canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _authStatus = 'Biometric authentication not supported.';
        });
        return;
      }

      final bool authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      final prefs = await SharedPreferences.getInstance();

      if (authenticated) {
        refreshToken();
        setState(() {
          _authStatus = 'Authentication successful';
        });

        await prefs.setBool('isBiometricEnabled', true);

        bool birthday = prefs.getBool('birthday') ?? false;

        if (birthday == true) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BirthdayPage()),
            );
          }
        } else {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } else {
        setState(() {
          _authStatus = 'Authentication failed';
        });

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } on PlatformException catch (e) {
      setState(() {
        _authStatus = 'Error: ${e.message}';
      });
    }
  }

  Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? FcmToken = await prefs.getString('FcmToken');
    print('FcmToken : $FcmToken');
    final userId = prefs.getString('user');
    final password = prefs.getString('passwordId');
    final response = await http.post(
      Uri.parse('http://hrmwebapi.lemeniz.com/api/Auth/Login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'username': userId, 'password': password, 'FcmToken': FcmToken}),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      print("Body : ${response.body}");
      final responseBody = json.decode(response.body);
      await prefs.setString('apiToken', responseBody['accessToken']);
      String refreshId = await prefs.getString('apiToken')!;
      print('RefreshId : $refreshId');
    } else {
      print('its not working');
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      _authenticate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('Fingerprint Authentication',
                  style: TextStyle(fontSize: 22)),
              const SizedBox(height: 10),
              Text(_authStatus, textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.lock_open),
                label: const Text('Retry Authentication'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  Future<void> logoutUser(context) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenApi = prefs.getString('apiToken');
    final userId = prefs.getString('user');

    if (tokenApi == null) return;

    final url = Uri.parse('http://hrmwebapi.lemeniz.com/api/Auth/Logout');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $tokenApi',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "Username": userId,
      }),
    );

    if (response.statusCode == 200) {
      await prefs.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully logout"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to logout!!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logout")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                print('logout');
                logoutUser(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Button background color
                foregroundColor: Colors.white, // Text color
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Logout'),
            ),
          ),

          const SizedBox(height: 150),
          // Bottom box with thank you GIF
          Container(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/thank you.gif',
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

// class PanicAlertPage extends StatelessWidget {
//   final String name;
//   final String designation;
//   final double? lat;
//   final double? lon;
//
//   const PanicAlertPage({
//     super.key,
//     required this.name,
//     required this.designation,
//     this.lat,
//     this.lon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final DateTime now = DateTime.now();
//     final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
//     final String formattedTime = DateFormat('hh:mm:ss a').format(now);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Panic Alert"),
//         backgroundColor: const Color(0xFF21465B),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Center(
//                   child: Text(
//                     'Alert Sent Successfully!',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 _buildInfoLine("Name", name),
//                 _buildInfoLine("Designation", designation),
//                 _buildInfoLine("Latitude", lat?.toStringAsFixed(6) ?? 'Unavailable'),
//                 _buildInfoLine("Longitude", lon?.toStringAsFixed(6) ?? 'Unavailable'),
//                 _buildInfoLine("Date", formattedDate),
//                 _buildInfoLine("Time", formattedTime),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoLine(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         "$label: $value",
//         style: const TextStyle(fontSize: 18, color: Colors.black87),
//       ),
//     );
//   }
// }

class PendingPage extends StatefulWidget {
  @override
  _PendingPageState createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage>
    with TickerProviderStateMixin {
  List<dynamic> fullPendingList = [];
  List<dynamic> animatedPendingList = [];

  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];

  bool isLoading = true;
  String? tokenApi;

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }



  @override
  void initState() {
    super.initState();
    loadTokenAndFetchData();
  }

  Future<void> loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    tokenApi = prefs.getString('apiToken') ?? '';
    await fetchPendingData();
  }

  Future<void> fetchPendingData() async {
    final url = Uri.parse(
        'http://hrmwebapi.lemeniz.com/api/LeaveApproval/GetPendingRequest');

    final Map<String, dynamic> requestBody = {
      "EmployeeCategoryId": null,
      "EmployeeId": "",
      "LeaveEntryTypeId": "",
      "LeaveTypeId": 0,
      "Date": ""
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $tokenApi',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      for (final c in _controllers) {
        c.dispose();
      }
      _controllers.clear();
      _animations.clear();

      fullPendingList = data;

      for (int i = 0; i < fullPendingList.length; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        );

        final animation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

        _controllers.add(controller);
        _animations.add(animation);
      }

      setState(() {
        animatedPendingList.clear(); // Empty list initially
        isLoading = false;
      });

      for (int i = 0; i < fullPendingList.length; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        _controllers[i].forward();
        setState(() {
          animatedPendingList.add(fullPendingList[i]);
        });
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load pending data')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }



  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending List")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : animatedPendingList.isEmpty
          ? const Center(child: Text("No pending requests"))
          : ListView.builder(
        itemCount: animatedPendingList.length,
        itemBuilder: (context, index) {
          final item = animatedPendingList[index];
          final animation = _animations[index];

          return SlideTransition(
            position: animation,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              elevation: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${item['employeeId']} - ${item['id']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LeaveDetailsPage(
                                      leaveData: item,
                                      requestId: item['id'],
                                      actionButton: 'true',
                                    ),
                              ),
                            );
                          },
                          child: const Text("Details"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      children: [
                        _buildTableRow("Reason       :", item['title'] ??
                            'N/A'),
                        _buildTableRow(
                            "Type            :", item['leaveEntryType'] ??
                            'N/A'),
                        _buildTableRow("Leave On     :", formatDateTime(
                            item['startOn'] ?? '')),
                        _buildTableRow("Created On  :", formatDateTime(
                            item['createdOn'] ?? '')),
                        _buildTableRow("Leave Type  :", item['leaveType'] ??
                            'N/A'),
                      ],
                    ),
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

TableRow _buildTableRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(value),
      ),
    ],
  );
}

class LeaveDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? leaveData;
  String? actionButton;

  LeaveDetailsPage({
    Key? key,
    this.leaveData,
    required requestId,
    this.actionButton,
  }) : super(key: key);

  @override
  State<LeaveDetailsPage> createState() => _LeaveDetailsState();
}

class _LeaveDetailsState extends State<LeaveDetailsPage> {
  String selectedAction = 'Approve';
  final TextEditingController _remarksController = TextEditingController();
  String? tokenApi;
  int? approverType;

  List<dynamic> rawPunchList = [];
  bool showRawPunch = false;

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  void initState() {
    super.initState();
    loadTokenAndFetchData();
  }

  Future<void> loadTokenAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    tokenApi = prefs.getString('apiToken') ?? '';
    await fetchPendingData();

    if (widget.leaveData?['leaveEntryType'] == 'Credit Request') {
      showRawPunch = true;
      await fetchRawPunchData(widget.leaveData!['id']);
    }
  }

  Future<void> fetchPendingData() async {
    final url = Uri.parse(
        'http://hrmwebapi.lemeniz.com/api/LeaveApproval/GetLeaveDetails?id=${widget.leaveData!['id']}');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $tokenApi',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        approverType = jsonDecode(response.body)['id'];
      });
    }
  }

  Future<void> fetchRawPunchData(int id) async {
    final url = Uri.parse(
        'http://hrmwebapi.lemeniz.com/api/LeaveApproval/GetRawPunchDetails?id=${widget.leaveData!['id']}');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $tokenApi',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        rawPunchList = data;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load punch data")),
      );
    }
  }

  Future<void> fetchPendingApprove(String approverType) async {
    final url = Uri.parse(
        'http://hrmwebapi.lemeniz.com/api/LeaveApproval/PendingApproval');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $tokenApi',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "SelectedIds": [widget.leaveData!['id']],
        "ActionId": approverType,
        "Remarks": selectedAction == 'Reject'
            ? _remarksController.text.trim()
            : "Approved by manager"
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approverType == 'A'
              ? "Approved Successfully"
              : "Rejected Successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error"), backgroundColor: Colors.red),
      );
    }
  }

  void handleSubmit() {
    if (selectedAction == 'Approve') {
      fetchPendingApprove('A');
    } else if (selectedAction == 'Reject') {
      final remarks = _remarksController.text.trim();
      if (remarks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter remarks for rejection")),
        );
        return;
      }
      fetchPendingApprove('R');
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveData = widget.leaveData ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("Leave Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Employee ID  : ${leaveData['employeeId'] ?? ''}"),
            Text("Name             : ${leaveData['createUserRealName'] ?? ''}"),
            Text("Reason          : ${leaveData['title'] ?? 'null'}"),
            Text("Leave On       : ${formatDateTime(leaveData['startOn'] ?? '')}"),
            Text("Type               : ${leaveData['leaveEntryType'] ?? 'null'}"),
            Text("Remarks        : ${leaveData['remarks'] ?? 'null'}"),
            Text("Created On    : ${formatDateTime(leaveData['createdOn'] ?? '')}"),

            const SizedBox(height: 20),
            if (widget.actionButton == 'true') ...[
              const Text("Select Action:"),
              Row(
                children: [
                  Radio<String>(
                    value: 'Approve',
                    groupValue: selectedAction,
                    onChanged: (value) =>
                        setState(() => selectedAction = value!),
                  ),
                  const Text("Approve"),
                  Radio<String>(
                    value: 'Reject',
                    groupValue: selectedAction,
                    onChanged: (value) =>
                        setState(() => selectedAction = value!),
                  ),
                  const Text("Reject"),
                ],
              ),
              if (selectedAction == 'Reject') ...[
                const SizedBox(height: 10),
                const Text("Remarks",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter remarks for rejection",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: handleSubmit,
                  icon: const Icon(Icons.send),
                  label: const Text("Submit"),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (showRawPunch && rawPunchList.isNotEmpty) ...[
              const Text("Raw Punch Details",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rawPunchList.length,
                itemBuilder: (context, index) {
                  final log = rawPunchList[index];
                  final swipeTime = log['swipeDateTime']?.toString();
                  final DateTime? dateTime = swipeTime != null
                      ? DateTime.tryParse(swipeTime)?.toLocal()
                      : null;

                  final date = dateTime != null
                      ? DateFormat('id').format(dateTime)
                      : '1';
                  final day = dateTime != null
                      ? DateFormat('EEE').format(dateTime)
                      : '1';
                  final time = swipeTime;
                  final status = log['punch'] ?? 'N/A';
                  final location = log['location'] ?? '';
                  final color =
                      (status == 'In' 'Out') ? Colors.red : Colors.green;
                  final empId = log['employeeId']?.toString() ?? '';
                  final empName = log['name']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(date,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              Text(day,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Employee ID : $empId",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("Name : $empName",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _pill(time!, const Color(0xFF0F4787)),
                                  const SizedBox(width: 8),
                                  _pill(status, color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(location,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class ApprovedPage extends StatefulWidget {
  @override
  State<ApprovedPage> createState() => _ApprovedPageState();
}

class _ApprovedPageState extends State<ApprovedPage>
    with TickerProviderStateMixin {
  List<dynamic> fullApprovedList = [];
  List<dynamic> animatedApprovedList = [];

  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];

  bool isLoading = true;

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchApprovedLeaves();
  }

  Future<void> fetchApprovedLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';
    final url =
        Uri.parse('http://hrmwebapi.lemeniz.com/api/LeaveApproval/GetApproved');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      data.sort((a, b) {
        DateTime dateA = DateTime.parse(a['startOn']);
        DateTime dateB = DateTime.parse(b['startOn']);
        return dateA.compareTo(dateB); // Ascending
      });

      for (final c in _controllers) {
        c.dispose();
      }
      _controllers.clear();
      _animations.clear();

      fullApprovedList = data;

      for (int i = 0; i < fullApprovedList.length; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        );
        final animation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

        _controllers.add(controller);
        _animations.add(animation);
      }

      setState(() {
        animatedApprovedList.clear(); // Show empty page first
        isLoading = false;
      });

      for (int i = 0; i < fullApprovedList.length; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        _controllers[i].forward();
        setState(() {
          animatedApprovedList.add(fullApprovedList[i]);
        });
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load approved leaves')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Approved List")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : animatedApprovedList.isEmpty
              ? const Center(child: Text("No approved leaves found"))
              : ListView.builder(
                  itemCount: animatedApprovedList.length,
                  itemBuilder: (context, index) {
                    final item = animatedApprovedList[index];
                    final animation = _animations[index];

                    return SlideTransition(
                        position: animation,
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row with ID and Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${item['employeeId']} - ${item['id']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    ElevatedButton(
                                      child: const Text("Details"),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LeaveDetailsPage(
                                              leaveData: item,
                                              requestId: null,
                                              actionButton: 'false',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Table content
                                Table(
                                  columnWidths: const {
                                    0: IntrinsicColumnWidth(),
                                    1: FlexColumnWidth(),
                                  },
                                  children: [
                                    _buildTableRows("Reason        :", item['title'] ?? 'N/A'),
                                    _buildTableRows("Type             :", item['leaveEntryType'] ?? 'N/A'),
                                    _buildTableRows("Leave On      :", formatDateTime(item['startOn'] ?? '')),
                                    _buildTableRows("Created On   :", formatDateTime(item['createdOn'] ?? '')),
                                    _buildTableRows("Leave Type   :", item['leaveType'] ?? 'null'),
                                  ],

                                ),
                              ],
                            ),
                          ),
                        ));
                  },
                ),
    );
  }
}

TableRow _buildTableRows(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(value),
      ),
    ],
  );
}

class RejectedPage extends StatefulWidget {
  @override
  State<RejectedPage> createState() => _RejectedPageState();
}

class _RejectedPageState extends State<RejectedPage>
    with TickerProviderStateMixin {
  List<dynamic> fullRejectedList = [];
  List<dynamic> animatedRejectedList = [];
  List<AnimationController> _controllers = [];
  List<Animation<Offset>> _animations = [];

  bool isLoading = true;

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRejectedLeaves();
  }

  Future<void> fetchRejectedLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('apiToken') ?? '';
    final url =
        Uri.parse('http://hrmwebapi.lemeniz.com/api/LeaveApproval/GetRejected');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      // Sort ascending by date
      data.sort((a, b) {
        DateTime dateA = DateTime.parse(a['startOn']);
        DateTime dateB = DateTime.parse(b['startOn']);
        return dateA.compareTo(dateB);
      });

      // Dispose old animations
      for (final c in _controllers) {
        c.dispose();
      }
      _controllers.clear();
      _animations.clear();

      fullRejectedList = data;

      for (int i = 0; i < fullRejectedList.length; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        );
        final animation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // from right
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ));

        _controllers.add(controller);
        _animations.add(animation);
      }

      setState(() {
        animatedRejectedList.clear(); // start with empty
        isLoading = false;
      });

      // One-by-one delayed animation
      for (int i = 0; i < fullRejectedList.length; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        _controllers[i].forward();
        setState(() {
          animatedRejectedList.add(fullRejectedList[i]);
        });
      }
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load rejected leaves')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rejected List")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : animatedRejectedList.isEmpty
              ? const Center(child: Text("No rejected leaves found"))
              : ListView.builder(
                  itemCount: animatedRejectedList.length,
                  itemBuilder: (context, index) {
                    final item = animatedRejectedList[index];
                    final animation = _animations[index];

                    return SlideTransition(
                      position: animation,
                      child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          elevation: 3,
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row with ID and button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item['employeeId']} - ${item['id']}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      ElevatedButton(
                                        child: const Text("Details"),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => LeaveDetailsPage(
                                                leaveData: item,
                                                requestId: null,
                                                actionButton: 'false',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Table format rows
                                  Table(
                                    columnWidths: const {
                                      0: IntrinsicColumnWidth(),
                                      1: FlexColumnWidth(),
                                    },
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    children: [
                                      _buildTableRowes("Reason         :", item['title'] ?? 'N/A'),
                                      _buildTableRowes("Type             :", item['leaveEntryType'] ?? 'N/A'),
                                      _buildTableRowes("Leave On     :", formatDateTime(item['startOn'] ?? '')),
                                      _buildTableRowes("Created On  :", formatDateTime(item['createdOn'] ?? '')),
                                      _buildTableRowes("Leave Type  :", item['leaveType'] ?? 'N/A'),
                                    ],

                                  ),
                                ],
                              ),
                            ),
                          )),
                    );
                  },
                ),
    );
  }
}

TableRow _buildTableRowes(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(value),
      ),
    ],
  );
}
