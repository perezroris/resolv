import 'package:flutter/material.dart';

import 'job_summary.dart';

class EstimateFields extends StatelessWidget {
  const EstimateFields({
    super.key,
    required this.amount,
    required this.unit,
    required this.onUnitChanged,
  });
  final TextEditingController amount;
  final PriceUnit unit;
  final ValueChanged<PriceUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Valor estimado (opcional)',
          prefixText: r'R$ ',
          hintText: '0,00',
          helperText: 'Em branco, fica a combinar.',
        ),
        validator: (input) =>
            (input ?? '').trim().isNotEmpty &&
                Estimate.parseCents(input!) == null
            ? 'Informe um valor positivo, como 80,00.'
            : null,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<PriceUnit>(
        initialValue: unit,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Forma de cobrança'),
        items: [
          for (final item in PriceUnit.values)
            DropdownMenuItem(value: item, child: Text(item.label)),
        ],
        onChanged: (item) {
          if (item != null) onUnitChanged(item);
        },
      ),
    ],
  );
}
