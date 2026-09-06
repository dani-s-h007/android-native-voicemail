import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.voicemail/channel');
  bool _isClassMode = false;

  bool _isScheduleEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isClassMode = prefs.getBool('class_mode') ?? false;
      _isScheduleEnabled = prefs.getBool('schedule_enabled') ?? false;
      
      final startHour = prefs.getInt('start_hour') ?? 9;
      final startMin = prefs.getInt('start_min') ?? 0;
      _startTime = TimeOfDay(hour: startHour, minute: startMin);
      
      final endHour = prefs.getInt('end_hour') ?? 10;
      final endMin = prefs.getInt('end_min') ?? 0;
      _endTime = TimeOfDay(hour: endHour, minute: endMin);
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.sms,
      Permission.contacts,
      Permission.accessNotificationPolicy,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      try {
        await platform.invokeMethod('requestRole');
        await platform.invokeMethod('requestAnswerCalls');
        await platform.invokeMethod('requestDndAccess');
      } on PlatformException catch (e) {
        debugPrint("Failed to request role: '${e.message}'.");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions are required for Class Mode')),
      );
    }
  }

  Future<void> _updateSchedule() async {
    if (_isScheduleEnabled) {
      final now = DateTime.now();
      
      var startDt = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
      if (startDt.isBefore(now)) startDt = startDt.add(const Duration(days: 1));
      
      var endDt = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);
      if (endDt.isBefore(startDt)) endDt = endDt.add(const Duration(days: 1));

      try {
        await platform.invokeMethod('setSchedule', {
          'startTime': startDt.millisecondsSinceEpoch,
          'endTime': endDt.millisecondsSinceEpoch,
          'isRepeating': true,
        });
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      try {
        await platform.invokeMethod('cancelSchedule');
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> _toggleSchedule(bool value) async {
    if (value) {
      await _requestPermissions();
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('schedule_enabled', value);
    setState(() {
      _isScheduleEnabled = value;
    });
    
    await _updateSchedule();
  }
  
  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (isStart) {
          _startTime = picked;
          prefs.setInt('start_hour', picked.hour);
          prefs.setInt('start_min', picked.minute);
        } else {
          _endTime = picked;
          prefs.setInt('end_hour', picked.hour);
          prefs.setInt('end_min', picked.minute);
        }
      });
      await _updateSchedule();
    }
  }

  Future<void> _toggleClassMode(bool value) async {
    if (value) {
      await _requestPermissions();
    }
    
    try {
      await platform.invokeMethod('setDndMode', {'enable': value});
    } on PlatformException catch (e) {
      debugPrint("Failed to set DND mode: '${e.message}'.");
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('class_mode', value);
    setState(() {
      _isClassMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Mode Voicemail'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                _isClassMode ? Icons.school : Icons.school_outlined,
                size: 100,
                color: _isClassMode ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                _isClassMode ? 'Class Mode is ON' : 'Class Mode is OFF',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'When Class Mode is ON, incoming calls are rejected silently and an automated SMS is sent.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              Transform.scale(
                scale: 2.0,
                child: Switch(
                  value: _isClassMode,
                  onChanged: _toggleClassMode,
                  activeColor: Colors.green,
                ),
              ),
              const SizedBox(height: 40),
              SwitchListTile(
                title: const Text('Enable Auto Schedule'),
                subtitle: const Text('Automatically toggle Class Mode at specific times'),
                value: _isScheduleEnabled,
                onChanged: _toggleSchedule,
              ),
              if (_isScheduleEnabled) ...[
                ListTile(
                  title: const Text('Start Time'),
                  trailing: Text(_startTime.format(context)),
                  onTap: () => _selectTime(true),
                ),
                ListTile(
                  title: const Text('End Time'),
                  trailing: Text(_endTime.format(context)),
                  onTap: () => _selectTime(false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
