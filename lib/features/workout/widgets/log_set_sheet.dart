import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/models/workout_set_entry.dart';

Future<LogSetDraft?> showLogSetSheet(
  BuildContext context, {
  required double initialWeightKg,
  required int initialReps,
  required int initialRestSeconds,
}) {
  return showModalBottomSheet<LogSetDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LogSetSheet(
        initialWeightKg: initialWeightKg,
        initialReps: initialReps,
        initialRestSeconds: initialRestSeconds,
      );
    },
  );
}

class _LogSetSheet extends StatefulWidget {
  const _LogSetSheet({
    required this.initialWeightKg,
    required this.initialReps,
    required this.initialRestSeconds,
  });

  final double initialWeightKg;
  final int initialReps;
  final int initialRestSeconds;

  @override
  State<_LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends State<_LogSetSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late int _restSeconds;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeightKg.toStringAsFixed(1),
    );
    _repsController = TextEditingController(
      text: widget.initialReps.toString(),
    );
    _restSeconds = widget.initialRestSeconds;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _adjustWeight(double delta) {
    final current = double.tryParse(_weightController.text) ?? 0;
    _weightController.text = (current + delta).clamp(0, 999).toStringAsFixed(1);
  }

  void _adjustReps(int delta) {
    final current = int.tryParse(_repsController.text) ?? 0;
    _repsController.text = (current + delta).clamp(0, 99).toString();
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    if (weight == null || reps == null || (weight <= 0 && reps <= 0)) {
      return;
    }
    Navigator.pop(
      context,
      LogSetDraft(weightKg: weight, reps: reps, restSeconds: _restSeconds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Log set',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InputTile(
                    label: 'Weight (kg)',
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputTile(
                    label: 'Reps',
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickButton(label: '+2.5kg', onTap: () => _adjustWeight(2.5)),
                _QuickButton(label: '+5kg', onTap: () => _adjustWeight(5)),
                _QuickButton(label: '-2.5kg', onTap: () => _adjustWeight(-2.5)),
                _QuickButton(label: '+1 rep', onTap: () => _adjustReps(1)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Rest timer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  [60, 90, 120, 150]
                      .map(
                        (seconds) => ChoiceChip(
                          label: Text(
                            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                          ),
                          selected: _restSeconds == seconds,
                          selectedColor: kAccentColor.withValues(alpha: 0.14),
                          side: BorderSide(
                            color:
                                _restSeconds == seconds
                                    ? kAccentColor
                                    : Colors.grey.shade300,
                          ),
                          onSelected:
                              (_) => setState(() => _restSeconds = seconds),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                child: const Text('Save set + start rest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.label,
    required this.controller,
    required this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
