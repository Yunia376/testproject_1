import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  SettingsPage({required this.onThemeChanged});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
    widget.onThemeChanged(isDark);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Pengaturan'),
    ),
    body: ListView(
      children: [
        ListTile(
          title: Text('About Me'),
          subtitle: Text('Informasi tentang aplikasi ini.'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Container(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        'Aplikasi Keuangan oleh Wahyu Agung versi Testing.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SwitchListTile(
          title: Text('Mode Malam'),
          value: _isDarkMode,
          onChanged: _toggleTheme,
        ),
      ],
    ),
  );
}
}
