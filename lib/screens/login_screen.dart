import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_button.dart';
class LoginScreen extends StatefulWidget {
@override
_LoginScreenState createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
final _emailCtrl = TextEditingController();
final _pwdCtrl = TextEditingController();
bool _loading = false;
String? _error;


@override
Widget build(BuildContext context) {
final auth = Provider.of<AuthService>(context, listen: false);
return Scaffold(
appBar: AppBar(title: Text('Login')),
body: Padding(
padding: EdgeInsets.all(16),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email')),
SizedBox(height: 12),
TextField(controller: _pwdCtrl, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
SizedBox(height: 18),
if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
SizedBox(height: 12),
_loading
? CircularProgressIndicator()
: GradientButton(
child: Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
onTap: () async {
setState(() { _loading = true; _error = null; });
final res = await auth.login(_emailCtrl.text.trim(), _pwdCtrl.text.trim());
setState(() { _loading = false; });
if (res != null) setState(() { _error = res; });
},
),
SizedBox(height: 12),
TextButton(
onPressed: () => Navigator.pushNamed(context, '/register'),
child: Text('Create an account'),
)
],
),
),
);
}
}