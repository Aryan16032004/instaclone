import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/upload_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _uploadService = UploadService();
  
  // Profile Data
  String _name = '';
  String _username = '';
  String _bio = '';
  String _gender = 'Keep secret';
  String _birthday = '';
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase.from('profiles').select().eq('id', userId).single();
    setState(() {
      _name = data['name'] ?? '';
      _username = data['username'] ?? '';
      _bio = data['bio'] ?? '';
      _gender = data['gender'] ?? 'Keep secret';
      _birthday = data['birthday'] ?? '';
      _avatarUrl = data['avatar_url'];
      _isLoading = false;
    });
  }

  // --- 1. PHOTO EDIT MODAL (Matches screenshot) ---
  void _showPhotoOptions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                  ),
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.cyan, // Blue check color
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  )
                ],
              ),
              const SizedBox(height: 20),
              
              // Small avatars (Simulated history)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) => Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600]),
                    ),
                    const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, color: Colors.white, size: 12))
                  ],
                )),
              ),
              const SizedBox(height: 20),
              const Text("Please choose a photo with high defination face", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                title: const Center(child: Text("Choose from Album", style: TextStyle(fontWeight: FontWeight.bold))),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const Divider(),
              ListTile(
                title: const Center(child: Text("Shoot", style: TextStyle(fontWeight: FontWeight.bold))),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const Divider(),
              ListTile(
                title: const Center(child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold))),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close dialog
    final file = await _uploadService.pickImage();
    if (file != null) {
      // Upload Logic
      final userId = _supabase.auth.currentUser!.id;
      await _uploadService.updateProfilePic(userId, File(file.path));
      _loadProfile(); // Refresh
    }
  }

  // --- 2. EDIT FIELD PAGE (For Name/Bio) ---
  void _editField(String title, String currentValue, int maxLength, Function(String) onSave) {
    final ctrl = TextEditingController(text: currentValue);
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title == 'Bio' ? 'Sign in' : title), // Screenshot says "Sign in" for Bio??
        actions: [
          TextButton(onPressed: () async {
            onSave(ctrl.text);
            await _supabase.from('profiles').update({title.toLowerCase(): ctrl.text}).eq('id', _supabase.auth.currentUser!.id);
            if (mounted) { _loadProfile(); Navigator.pop(context); }
          }, child: const Text("Save", style: TextStyle(color: Colors.grey)))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title == 'Bio') ...[
              Center(child: CircleAvatar(radius: 40, backgroundColor: Colors.grey, backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null)),
              const SizedBox(height: 10),
              const Center(child: Text("Edit photo", style: TextStyle(color: Colors.white, fontSize: 12))),
              const SizedBox(height: 20),
              Text("@$_username", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
            ],
            
            Text(title == 'Bio' ? "Introduce yourself!" : "Enter $title", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              maxLength: maxLength,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: title == 'Bio' ? "A good bio makes you stand out!" : "",
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                counterStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.grey, Colors.grey]), // Disabled look per screenshot
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            )
          ],
        ),
      ),
    )));
  }

  // --- 3. DATE PICKER ---
  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final dateStr = "${picked.year}-${picked.month}-${picked.day}";
      await _supabase.from('profiles').update({'birthday': dateStr}).eq('id', _supabase.auth.currentUser!.id);
      _loadProfile();
    }
  }

  // --- 4. GENDER PICKER ---
  void _selectGender() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("What's your gender?", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
            ]),
            const SizedBox(height: 10),
            _genderOption("Male"),
            const SizedBox(height: 10),
            _genderOption("Female"),
            const SizedBox(height: 10),
            _genderOption("Keep secret"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Save"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _genderOption(String label) {
    final isSelected = _gender == label;
    return GestureDetector(
      onTap: () async {
        await _supabase.from('profiles').update({'gender': label}).eq('id', _supabase.auth.currentUser!.id);
        _loadProfile();
        if(mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.black, fontSize: 16)),
            const Spacer(),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Colors.black : Colors.grey)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Edit profile", style: TextStyle(color: Colors.white)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Save", style: TextStyle(color: Colors.grey)))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 10),
                  const Text("Edit photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Fields
            _buildListTile("@$_username", isHeader: true),
            const Divider(color: Colors.white10),
            _buildListTile("Name", value: _name, onTap: () => _editField("Name", _name, 20, (v) => setState(() => _name = v))),
            const Divider(color: Colors.white10),
            _buildListTile("Bio", value: _bio.isEmpty ? "0/30" : _bio, isGrey: _bio.isEmpty, onTap: () => _editField("Bio", _bio, 30, (v) => setState(() => _bio = v))),
            const Divider(color: Colors.white10),
            _buildListTile("Birthday", value: _birthday, icon: Icons.calendar_today, onTap: _selectDate),
            const Divider(color: Colors.white10),
            _buildListTile("Gender", value: _gender, onTap: _selectGender),
            const Divider(color: Colors.white10),
            _buildListTile("Avatar Frame", value: "Setting >", onTap: () {}), // Placeholder for frame logic
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String label, {String? value, bool isHeader = false, bool isGrey = false, IconData? icon, VoidCallback? onTap}) {
    if (isHeader) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
      );
    }
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value ?? "", style: TextStyle(color: isGrey ? Colors.grey : Colors.white, fontSize: 15)),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: Colors.grey, size: 16)],
          if (onTap != null && icon == null) const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}