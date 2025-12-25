import 'package:flutter/material.dart';
import 'package:flutter_prj/services/wallet_service.dart';

class CoinIndicator extends StatefulWidget {
  final VoidCallback? onTap;

  const CoinIndicator({super.key, this.onTap});

  @override
  State<CoinIndicator> createState() => _CoinIndicatorState();
}

class _CoinIndicatorState extends State<CoinIndicator>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  int _balance = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadBalance();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Listen to wallet updates
    _walletService.streamWalletBalance().listen((wallet) {
      if (wallet != null && mounted) {
        final newBalance = wallet['balance'] as int;
        if (newBalance != _balance) {
          _controller.forward().then((_) => _controller.reverse());
        }
        setState(() => _balance = newBalance);
      }
    });
  }

  Future<void> _loadBalance() async {
    final wallet = await _walletService.getMyWallet();
    if (wallet != null && mounted) {
      setState(() => _balance = wallet['balance'] as int);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFe91e63), Color(0xFF9c27b0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFe91e63).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                _balance.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
