import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_lock_service.dart';

enum PinMode { verify, create, confirm }

class PinLockScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;

  const PinLockScreen({
    super.key,
    this.mode = PinMode.verify,
    this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String _firstPin = '';
  late PinMode _currentMode;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _processPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _processPin() async {
    final lockService = Provider.of<AppLockService>(context, listen: false);

    if (_currentMode == PinMode.verify) {
      bool valid = await lockService.verifyPin(_enteredPin);
      if (valid) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'Incorrect PIN. Please try again.';
        });
      }
    } else if (_currentMode == PinMode.create) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _currentMode = PinMode.confirm;
      });
    } else if (_currentMode == PinMode.confirm) {
      if (_enteredPin == _firstPin) {
        await lockService.setPin(_enteredPin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Security PIN set successfully!')),
          );
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        }
      } else {
        setState(() {
          _enteredPin = '';
          _firstPin = '';
          _currentMode = PinMode.create;
          _errorMessage = 'PINs do not match. Enter a new PIN.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = 'Enter PIN';
    if (_currentMode == PinMode.create) titleText = 'Create 4-Digit PIN';
    if (_currentMode == PinMode.confirm) titleText = 'Confirm Your PIN';

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.lock_rounded, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              titleText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentMode == PinMode.verify
                  ? 'Enter your 4-digit security PIN to access billing data'
                  : 'Set a passcode to secure your invoices & database',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],

            const Spacer(),

            // Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 70), // Empty space
                      _buildKeypadButton('0'),
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 28),
                          onPressed: _onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String val) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 2,
          backgroundColor: Theme.of(context).cardColor,
        ),
        onPressed: () => _onKeyPress(val),
        child: Text(
          val,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
