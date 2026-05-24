import 'package:flutter/material.dart';

import '../config/cities.dart';
import '../theme/app_theme.dart';

class CityField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const CityField({
    super.key,
    required this.controller,
    this.label = 'City / District',
    this.hint = 'Mumbai, Delhi, Pune…',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AppColors.text2,
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<String>(
          optionsBuilder: (text) {
            if (text.text.isEmpty) return indianCities;
            return indianCities.where(
              (c) => c.toLowerCase().contains(text.text.toLowerCase()),
            );
          },
          onSelected: (v) => controller.text = v,
          fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(hintText: hint),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => onSubmitted(),
            );
          },
        ),
      ],
    );
  }
}
