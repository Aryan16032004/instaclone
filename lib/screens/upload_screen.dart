import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/upload_service.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_button.dart';


class UploadScreen extends StatefulWidget {
@override
_UploadScreenState createState() => _UploadScreenState();
}


class _UploadScreenState extends State<UploadScreen> {
File? _file;
bool _isVideo = false;
final _captionCtrl = TextEditingController();
bool _loading = false;


final _up = UploadService();


@override
Widget build(BuildContext context) {
	final auth = Provider.of<AuthService>(context, listen: false);
return Scaffold(
appBar: AppBar(title: Text('Upload')),
body: Padding(
padding: EdgeInsets.all(16),
child: Column(
children: [
if (_file != null) Container(height: 200, child: Center(child: Text(_isVideo ? 'Video selected' : 'Image selected'))),
SizedBox(height: 12),
TextField(controller: _captionCtrl, decoration: InputDecoration(labelText: 'Caption')),
SizedBox(height: 12),
Row(children: [
Expanded(child: ElevatedButton(onPressed: () async { final x = await _up.pickImage(); if (x != null) setState(() { _file = File(x.path); _isVideo = false; }); }, child: Text('Pick Image'))),
SizedBox(width: 8),
Expanded(child: ElevatedButton(onPressed: () async { final x = await _up.pickVideo(); if (x != null) setState(() { _file = File(x.path); _isVideo = true; }); }, child: Text('Pick Video'))),
]),
SizedBox(height: 12),
_loading ? CircularProgressIndicator() : GradientButton(child: Text('Upload'), onTap: () async {
if (_file == null) return;
setState(() { _loading = true; });
	final url = await _up.uploadFile(_file!, _isVideo ? 'videos' : 'images');
	await _up.createPostDoc(userId: auth.user!.id, mediaUrl: url, isVideo: _isVideo, caption: _captionCtrl.text.trim());
setState(() { _loading = false; _file = null; _captionCtrl.clear(); });
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded')));
}),
],
),
),
);
}
}