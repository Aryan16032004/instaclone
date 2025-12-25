import 'package:flutter/material.dart';
import 'package:flutter_prj/services/gift_service.dart';
import 'package:flutter_prj/services/wallet_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GiftPanel extends StatefulWidget {
  final String recipientUserId;
  final String? liveRoomId;
  final String? postId;
  final VoidCallback? onGiftSent;

  const GiftPanel({
    super.key,
    required this.recipientUserId,
    this.liveRoomId,
    this.postId,
    this.onGiftSent,
  });

  @override
  State<GiftPanel> createState() => _GiftPanelState();
}

class _GiftPanelState extends State<GiftPanel>
    with SingleTickerProviderStateMixin {
  final GiftService _giftService = GiftService();
  final WalletService _walletService = WalletService();

  List<Map<String, dynamic>> _gifts = [];
  List<String> _categories = [];
  bool _isLoading = true;
  int _myBalance = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final gifts = await _giftService.getGifts();
    final categories = await _giftService.getGiftCategories();
    final wallet = await _walletService.getMyWallet();

    setState(() {
      _gifts = gifts;
      _categories = ['all', ...categories];
      _myBalance = wallet?['balance'] ?? 0;
      _tabController = TabController(length: _categories.length, vsync: this);
      _isLoading = false;
    });
  }

  Future<void> _sendGift(Map<String, dynamic> gift) async {
    final giftCost = gift['coin_cost'] as int;

    if (_myBalance < giftCost) {
      _showMessage('Insufficient balance!', isError: true);
      return;
    }

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Send Gift?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Send ${gift['name']} for $giftCost coins?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe91e63),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _giftService.sendGift(
      toUserId: widget.recipientUserId,
      giftId: gift['id'],
      liveRoomId: widget.liveRoomId,
      postId: widget.postId,
    );

    if (success) {
      _showMessage('Gift sent successfully!');
      setState(() => _myBalance -= giftCost);
      widget.onGiftSent?.call();
    } else {
      _showMessage('Failed to send gift', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isLoading) _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildGiftGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Send Gift',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFe91e63), Color(0xFF9c27b0)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _myBalance.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFe91e63), Color(0xFF9c27b0)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: _categories.map((category) {
          return Tab(text: category.toUpperCase());
        }).toList(),
      ),
    );
  }

  Widget _buildGiftGrid() {
    return TabBarView(
      controller: _tabController,
      children: _categories.map((category) {
        final filteredGifts = category == 'all'
            ? _gifts
            : _gifts.where((g) => g['category'] == category).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredGifts.length,
          itemBuilder: (context, index) {
            return _buildGiftItem(filteredGifts[index]);
          },
        );
      }).toList(),
    );
  }

  Widget _buildGiftItem(Map<String, dynamic> gift) {
    final name = gift['name'] as String;
    final iconUrl = gift['icon_url'] as String;
    final cost = gift['coin_cost'] as int;
    final canAfford = _myBalance >= cost;

    return GestureDetector(
      onTap: canAfford ? () => _sendGift(gift) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAfford
                ? const Color(0xFFe91e63).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: canAfford ? 1.0 : 0.4,
              child: CachedNetworkImage(
                imageUrl: iconUrl,
                width: 40,
                height: 40,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(
                  Icons.card_giftcard,
                  size: 40,
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: canAfford ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: canAfford
                      ? Colors.amber
                      : Colors.amber.withOpacity(0.4),
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  cost.toString(),
                  style: TextStyle(
                    color: canAfford
                        ? Colors.amber
                        : Colors.amber.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
