import 'package:flutter/material.dart';

// Needs hardware
class IoTButton extends StatelessWidget {
  const IoTButton({super.key});

  void _showComingSoonMessage(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text("Coming soon, please enter inputs manually"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.sensors, color: Colors.white),
        label: const Text("IoT Sensors"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.green,
        ),
        onPressed: () => _showComingSoonMessage(context),
      ),
    );
  }
}
