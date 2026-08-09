import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/db_helper.dart';

void main() {
  runApp(const InfluenzaApp());
}

// ─── Theme Mode Storage ────────────────────────────────────────────────
const String _themeKey = 'theme_mode';

// ─── App Root ───────────────────────────────────────────────────────────
class InfluenzaApp extends StatefulWidget {
  const InfluenzaApp({super.key});

  @override
  State<InfluenzaApp> createState() => _InfluenzaAppState();
}

class _InfluenzaAppState extends State<InfluenzaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_themeKey) ?? 2;
    final modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    if (mounted) setState(() => _themeMode = modes[idx]);
  }

  void setThemeMode(ThemeMode mode) {
    final modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final idx = modes.indexOf(mode);
    SharedPreferences.getInstance().then((p) => p.setInt(_themeKey, idx));
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Influenza',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: const AuthScreen(),
    );
  }
}

// ─── Auth Screen ───────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  static const _validId = 'ADMIN123';
  static const _validPass = '123ADMIN';

  void _login() {
    setState(() => _error = null);
    final id = _idCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (id.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter both ID and Passcode.');
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (id == _validId && pass == _validPass) {
        final app = context.findAncestorStateOfType<_InfluenzaAppState>()!;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => MainScreen(onThemeChanged: app.setThemeMode),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut), child: child),
          ),
        );
      } else {
        setState(() {
          _error = 'Invalid ID or Passcode. Please try again.';
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary, cs.tertiary, cs.primaryContainer],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Card(
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                      child: Icon(Icons.shield_rounded, size: 48, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(height: 20),
                    Text('Influenza', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Sign in to continue', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _idCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'ID',
                        hintText: 'Enter your ID',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Passcode',
                        hintText: 'Enter your passcode',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: cs.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w500, fontSize: 13))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _login,
                        icon: _loading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.onPrimary))
                            : const Icon(Icons.login_rounded),
                        label: Text(_loading ? 'Authenticating...' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('v0.0.1  |  Under Development',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main Screen (Bottom Nav) ──────────────────────────────────────────
class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainScreen({super.key, required this.onThemeChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const HomeTab(),
          DatabaseTab(key: ValueKey('db')),
          SettingsTab(onThemeChanged: widget.onThemeChanged),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: 'Database'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── Home Tab ───────────────────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final List<Map<String, String>> _flows = [
    {'name': 'Flow 1', 'status': 'Active'},
    {'name': 'Flow 2', 'status': 'Draft'},
    {'name': 'Flow 3', 'status': 'Active'},
  ];

  void _createFlow() {
    final count = _flows.length + 1;
    setState(() {
      _flows.insert(0, {'name': 'Flow $count', 'status': 'Draft'});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createFlow,
        icon: const Icon(Icons.add),
        label: const Text('Create Flow'),
      ),
      body: _flows.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_tree_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No flows yet', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Tap the button below to create one.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _flows.length,
              itemBuilder: (context, index) {
                final flow = _flows[index];
                final isActive = flow['status'] == 'Active';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                        child: Icon(Icons.account_tree, color: isActive ? Colors.green : Colors.orange, size: 22),
                      ),
                      title: Text(flow['name']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text('Created just now', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isActive ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          flow['status']!,
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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

// ─── Database Tab ───────────────────────────────────────────────────────
class DatabaseTab extends StatefulWidget {
  const DatabaseTab({super.key});

  @override
  State<DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<DatabaseTab> {
  final _db = DatabaseHelper.instance;
  List<UserRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final records = await _db.getAllRecords();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      final jsonList = list.map((e) => e as Map<String, dynamic>).toList();
      await _db.importFromJson(jsonList);
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${jsonList.length} records')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _exportJson() async {
    try {
      final data = await _db.exportToJson();
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final result = await FilePicker.platform.saveFile(
        fileName: 'influenza_export.json',
        bytes: utf8.encode(jsonStr),
      );
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _browseStorage() => _importJson();

  Future<void> _deleteRecord(int id) async {
    await _db.deleteRecord(id);
    _refresh();
  }

  void _showEditDialog(UserRecord record) {
    final emailCtrl = TextEditingController(text: record.email);
    final passCtrl = TextEditingController(text: record.password);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Record'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final updated = record.copyWith(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
              await _db.updateRecord(updated);
              Navigator.pop(ctx);
              _refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Delete all records? This cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteAllRecords();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database'),
        centerTitle: true,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Import / Export buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importJson,
                    icon: const Icon(Icons.upload_file_outlined, size: 20),
                    label: const Text('Import JSON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportJson,
                    icon: const Icon(Icons.download_outlined, size: 20),
                    label: const Text('Export JSON'),
                  ),
                ),
              ],
            ),
          ),
          // Record count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _records.isEmpty ? 'No records' : '${_records.length} record${_records.length == 1 ? '' : 's'}',
                style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Records list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text('No records found', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Import a JSON file to get started.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final r = _records[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: cs.primaryContainer,
                                      child: Text(
                                        r.email.isNotEmpty ? r.email[0].toUpperCase() : '?',
                                        style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.email, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(
                                            r.password,
                                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, size: 20, color: cs.primary),
                                      onPressed: () => _showEditDialog(r),
                                      tooltip: 'Edit',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                                      onPressed: () => _deleteRecord(r.id!),
                                      tooltip: 'Delete',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Browse Storage button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _browseStorage,
                  icon: const Icon(Icons.folder_open_outlined, size: 20),
                  label: const Text('Browse Storage', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tab ───────────────────────────────────────────────────────
class SettingsTab extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const SettingsTab({super.key, required this.onThemeChanged});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  int _selectedIndex = 2; // System default

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final idx = p.getInt(_themeKey) ?? 2;
      if (mounted) setState(() => _selectedIndex = idx);
    });
  }

  void _onChanged(int? val) {
    if (val == null) return;
    final modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    setState(() => _selectedIndex = val);
    widget.onThemeChanged(modes[val]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: cs.primary),
                      const SizedBox(width: 12),
                      Text('Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Light
                  RadioListTile<int>(
                    value: 0,
                    groupValue: _selectedIndex,
                    onChanged: _onChanged,
                    title: const Text('Light'),
                    secondary: const Icon(Icons.light_mode_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // Dark
                  RadioListTile<int>(
                    value: 1,
                    groupValue: _selectedIndex,
                    onChanged: _onChanged,
                    title: const Text('Dark'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // System
                  RadioListTile<int>(
                    value: 2,
                    groupValue: _selectedIndex,
                    onChanged: _onChanged,
                    title: const Text('System'),
                    secondary: const Icon(Icons.auto_mode_outlined),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // About card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('Version 0.0.1 (Under Development)'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: const Text('Tech Stack'),
                  subtitle: const Text('Flutter 3.27.4 / Dart 3.6.2 / SQLite'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
