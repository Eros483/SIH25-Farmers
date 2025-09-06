import 'package:flutter/material.dart';

class ManualInput extends StatefulWidget {
  const ManualInput({super.key});

  @override
  State<ManualInput> createState() => _ManualInputState();
}

class _ManualInputState extends State<ManualInput>
    with SingleTickerProviderStateMixin {
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();
  final _phController = TextEditingController();

  void _openInputDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Manual Input",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter Soil Inputs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nController,
                    decoration:
                        const InputDecoration(labelText: "Nitrogen (N)"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _pController,
                    decoration:
                        const InputDecoration(labelText: "Phosphorus (P)"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _kController,
                    decoration:
                        const InputDecoration(labelText: "Potassium (K)"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _phController,
                    decoration: const InputDecoration(labelText: "Soil pH"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitInputs,
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  void _submitInputs() {
    final n = _nController.text;
    final p = _pController.text;
    final k = _kController.text;
    final ph = _phController.text;

    if (n.isEmpty || p.isEmpty || k.isEmpty || ph.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all values")),
      );
      return;
    }

    Navigator.of(context).pop(); // close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Inputs submitted: N=$n, P=$p, K=$k, pH=$ph")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openInputDialog,
      child: const Text(
        "Enter input manually",
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
