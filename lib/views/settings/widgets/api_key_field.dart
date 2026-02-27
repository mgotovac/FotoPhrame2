import 'package:flutter/material.dart';

class ApiKeyField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? hint;

  const ApiKeyField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? 'Enter API key',
        border: const OutlineInputBorder(),
        suffixIcon: value != null && value!.isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
      onChanged: onChanged,
      obscureText: true,
    );
  }
}
