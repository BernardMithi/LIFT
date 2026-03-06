import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/workout/widgets/log_set_sheet.dart';
import 'package:lift/shared/models/machine.dart';
import 'package:lift/shared/models/workout_set_entry.dart';
import 'package:lift/shared/widgets/surfaces.dart';

class MachineScreen extends StatefulWidget {
  const MachineScreen({super.key, required this.machine});

  final Machine machine;

  @override
  State<MachineScreen> createState() => _MachineScreenState();
}

class _MachineScreenState extends State<MachineScreen> {
  final List<WorkoutSetEntry> _sets = [];
  Timer? _restTimer;
  int _restRemaining = 0;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _openLogSetSheet() async {
    final last = _sets.isNotEmpty ? _sets.last : null;
    final draft = await showLogSetSheet(
      context,
      initialWeightKg: last?.weightKg ?? widget.machine.lastWeightKg,
      initialReps: last?.reps ?? widget.machine.lastReps,
      initialRestSeconds:
          last?.restSecondsPlanned ?? widget.machine.defaultRestSeconds,
    );

    if (draft == null) return;

    setState(() {
      _sets.add(
        WorkoutSetEntry(
          setNumber: _sets.length + 1,
          weightKg: draft.weightKg,
          reps: draft.reps,
          createdAt: DateTime.now(),
          restSecondsPlanned: draft.restSeconds,
        ),
      );
    });
    _startRestTimer(draft.restSeconds);
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restRemaining <= 1) {
        timer.cancel();
        setState(() => _restRemaining = 0);
        return;
      }
      setState(() => _restRemaining -= 1);
    });
  }

  void _adjustRest(int delta) {
    if (_restRemaining <= 0) return;
    setState(() => _restRemaining = (_restRemaining + delta).clamp(0, 3600));
  }

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final machine = widget.machine;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              machine.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              machine.machineCode,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const PhosphorIcon(PhosphorIconsRegular.info, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _MachineHero(machine: machine),
              const SizedBox(height: 12),
              SectionBoundary(
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Last time',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          machine.lastUsedLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatPill(
                          label: 'Top set',
                          value:
                              '${machine.lastWeightKg.toStringAsFixed(0)} kg x ${machine.lastReps}',
                        ),
                        const SizedBox(width: 8),
                        _StatPill(label: 'Zone', value: machine.zone),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_restRemaining > 0) ...[
                _RestTimerStrip(
                  remaining: _formatSeconds(_restRemaining),
                  onAddThirty: () => _adjustRest(30),
                  onSkip: () => setState(() => _restRemaining = 0),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SectionBoundary(
                  borderRadius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_sets.length} set${_sets.length == 1 ? '' : 's'} logged',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child:
                            _sets.isEmpty
                                ? Center(
                                  child: Text(
                                    'No sets yet.\nTap Log Set to start.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  itemCount: _sets.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final set = _sets[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: kAccentColor.withValues(
                                                alpha: 0.10,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${set.setNumber}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${set.weightKg.toStringAsFixed(1)} kg x ${set.reps}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${set.restSecondsPlanned}s rest',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _sets.isEmpty
                                      ? null
                                      : () {
                                        final last = _sets.last;
                                        setState(() {
                                          _sets.add(
                                            WorkoutSetEntry(
                                              setNumber: _sets.length + 1,
                                              weightKg: last.weightKg,
                                              reps: last.reps,
                                              createdAt: DateTime.now(),
                                              restSecondsPlanned:
                                                  last.restSecondsPlanned,
                                            ),
                                          );
                                        });
                                        _startRestTimer(
                                          last.restSecondsPlanned,
                                        );
                                      },
                              child: const Text('Repeat last'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: kAccentColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: _openLogSetSheet,
                              child: const Text('Log Set'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MachineHero extends StatelessWidget {
  const _MachineHero({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: Image.network(
              machine.imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                    ),
                  ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      machine.muscleGroups
                          .map((group) => _DarkChip(label: group))
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RestTimerStrip extends StatelessWidget {
  const _RestTimerStrip({
    required this.remaining,
    required this.onAddThirty,
    required this.onSkip,
  });

  final String remaining;
  final VoidCallback onAddThirty;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kAccentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined, color: kAccentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest Timer',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  remaining,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onAddThirty, child: const Text('+30s')),
          TextButton(onPressed: onSkip, child: const Text('Skip')),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
