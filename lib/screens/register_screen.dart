import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_button.dart';


class RegisterScreen extends StatefulWidget {
@override
_RegisterScreenState createState() => _RegisterScreenState();
}


class _RegisterScreenState extends State<RegisterScreen> {
final _emailCtrl = TextEditingController();
final _pwdCtrl = TextEditingController();
final _usernameCtrl = TextEditingController();
bool _loading = false;
String? _error;


@override
Widget build(BuildContext context) {
final auth = Provider.of<AuthService>(context, listen: false);
return Scaffold(
appBar: AppBar(title: Text('Register')),
body: Padding(
padding: EdgeInsets.all(16),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
TextField(controller: _usernameCtrl, decoration: InputDecoration(labelText: 'Username')),
SizedBox(height: 12),
TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email')),
SizedBox(height: 12),
TextField(controller: _pwdCtrl, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
SizedBox(height: 18),
if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
SizedBox(height: 12),
_loading
? CircularProgressIndicator()
: GradientButton(
child: Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
onTap: () async {
setState(() { _loading = true; _error = null; });
final res = await auth.register(_emailCtrl.text.trim(), _pwdCtrl.text.trim(), _usernameCtrl.text.trim());
setState(() { _loading = false; });
if (res != null) setState(() { _error = res; });
else Navigator.pop(context);
},
),
],
),
),
);
}
}