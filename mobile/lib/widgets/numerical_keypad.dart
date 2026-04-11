import 'package:flutter/material.dart';

class NumericalKeypad extends StatelessWidget {
  final ValueChanged<String>? onKeyPress;
  final VoidCallback? onSubmitted;
  final TextEditingController? controller;

  const NumericalKeypad({
    super.key,
    this.onKeyPress,
    this.onSubmitted,
    this.controller,
  });

  void _onKeyPress(String value) {
    if (onKeyPress != null) {
      onKeyPress!(value);
    } else if (controller != null) {
      controller!.text += value;
    }
  }

  void _onBackspace() {
    if (onKeyPress != null) {
      onKeyPress!('DEL');
    } else if (controller != null && controller!.text.isNotEmpty) {
      controller!.text = controller!.text.substring(0, controller!.text.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text('NUMERICAL INPUT', style: TextStyle(color: Color(0xFF8B949E), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
              ),
              TextButton(
                onPressed: onSubmitted,
                child: const Text('SUBMIT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1), letterSpacing: 1.1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _buildKey('1'), _buildKey('2'), _buildKey('3'),
              _buildKey('4'), _buildKey('5'), _buildKey('6'),
              _buildKey('7'), _buildKey('8'), _buildKey('9'),
              _buildKey('.'), _buildKey('0'), _buildBackspace(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBackspace() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.2)),
        ),
        child: const Icon(Icons.backspace_outlined, color: Color(0xFFF43F5E), size: 24),
      ),
    );
  }
}
