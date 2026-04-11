import 'package:flutter/material.dart';

class NumericalKeypad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  const NumericalKeypad({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  void _onKeyPress(String value) {
    controller.text += value;
  }

  void _onBackspace() {
    if (controller.text.isNotEmpty) {
      controller.text = controller.text.substring(0, controller.text.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSubmitted,
                child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ),
            ],
          ),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            padding: const EdgeInsets.only(bottom: 24),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBackspace() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.backspace_outlined, color: Colors.redAccent),
      ),
    );
  }
}
