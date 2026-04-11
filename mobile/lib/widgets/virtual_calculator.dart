import 'package:flutter/material.dart';

class VirtualCalculator extends StatefulWidget {
  const VirtualCalculator({super.key});

  @override
  State<VirtualCalculator> createState() => _VirtualCalculatorState();
}

class _VirtualCalculatorState extends State<VirtualCalculator> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onDigitPressed(String digit) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else if (_display.length < 12) {
        _display += digit;
      }
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = operator;
      _shouldResetDisplay = true;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;
    double secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      +case '+': result = _firstOperand! + secondOperand; break;
      -case '-': result = _firstOperand! - secondOperand; break;
      *case '*': result = _firstOperand! * secondOperand; break;
      /case '/': result = secondOperand != 0 ? _firstOperand! / secondOperand : 0; break;
    }

    setState(() {
      _display = result.toString();
      if (_display.endsWith('.0')) {
        _display = _display.substring(0, _display.length - 2);
      }
      if (_display.length > 12) {
        _display = _display.substring(0, 12);
      }
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _display,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 32,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildButton('C', color: Colors.redAccent, onPressed: _clear),
              _buildButton('/', color: Colors.orangeAccent, onPressed: () => _onOperatorPressed('/')),
              _buildButton('*', color: Colors.orangeAccent, onPressed: () => _onOperatorPressed('*')),
              _buildButton('DEL', color: Colors.grey, onPressed: () {
                setState(() {
                  if (_display.length > 1) {
                    _display = _display.substring(0, _display.length - 1);
                  } else {
                    _display = '0';
                  }
                });
              }),
              _buildButton('7', onPressed: () => _onDigitPressed('7')),
              _buildButton('8', onPressed: () => _onDigitPressed('8')),
              _buildButton('9', onPressed: () => _onDigitPressed('9')),
              _buildButton('-', color: Colors.orangeAccent, onPressed: () => _onOperatorPressed('-')),
              _buildButton('4', onPressed: () => _onDigitPressed('4')),
              _buildButton('5', onPressed: () => _onDigitPressed('5')),
              _buildButton('6', onPressed: () => _onDigitPressed('6')),
              _buildButton('+', color: Colors.orangeAccent, onPressed: () => _onOperatorPressed('+')),
              _buildButton('1', onPressed: () => _onDigitPressed('1')),
              _buildButton('2', onPressed: () => _onDigitPressed('2')),
              _buildButton('3', onPressed: () => _onDigitPressed('3')),
              _buildButton('=', color: Colors.blueAccent, onPressed: _calculate),
              _buildButton('0', onPressed: () => _onDigitPressed('0')),
              _buildButton('.', onPressed: () => _onDigitPressed('.')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, {Color? color, void Function()? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.grey[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
