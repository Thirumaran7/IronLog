
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestTimerButton extends StatelessWidget {
  const RestTimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Rest timer',
      icon: const Icon(Icons.timer_outlined),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (_) => const RestTimerDialog(),
        );
      },
    );
  }
}

class RestTimerDialog extends StatefulWidget {
  final bool autoStart;

  const RestTimerDialog({
    super.key,
    this.autoStart = false,
  });

  @override
  State<RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<RestTimerDialog> {
  Timer? ticker;

  int selectedSeconds = 90;
  int remainingSeconds = 90;

  bool isRunning = false;
  DateTime? endTime;

  static const List<int> presets = [30, 60, 90, 120];

  @override
  void initState() {
    super.initState();

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          startTimer();
        }
      });
    }
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (selectedSeconds <= 0) return 0.0;

    return (remainingSeconds / selectedSeconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void selectPreset(int seconds) {
    ticker?.cancel();

    setState(() {
      selectedSeconds = seconds;
      remainingSeconds = seconds;
      isRunning = false;
      endTime = null;
    });
  }

  void startTimer() {
    if (!mounted || isRunning) return;

    if (remainingSeconds <= 0) {
      resetTimer();
    }

    endTime = DateTime.now().add(
      Duration(seconds: remainingSeconds),
    );

    setState(() {
      isRunning = true;
    });

    ticker?.cancel();

    ticker = Timer.periodic(
      const Duration(milliseconds: 250),
          (_) => updateTimer(),
    );
  }

  void updateTimer() {
    if (endTime == null || !mounted) return;

    final difference = endTime!.difference(DateTime.now());

    final newRemaining = difference.inMilliseconds <= 0
        ? 0
        : (difference.inMilliseconds / 1000).ceil();

    if (newRemaining <= 0) {
      ticker?.cancel();

      setState(() {
        remainingSeconds = 0;
        isRunning = false;
        endTime = null;
      });

      SystemSound.play(SystemSoundType.alert);
      return;
    }

    if (newRemaining != remainingSeconds) {
      setState(() {
        remainingSeconds = newRemaining;
      });
    }
  }

  void pauseTimer() {
    if (!isRunning) return;

    updateTimer();

    if (!mounted) return;

    ticker?.cancel();

    setState(() {
      isRunning = false;
      endTime = null;
    });
  }

  void resetTimer() {
    ticker?.cancel();

    setState(() {
      remainingSeconds = selectedSeconds;
      isRunning = false;
      endTime = null;
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finished = remainingSeconds == 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1D21),
      title: const Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: Colors.orange,
          ),
          SizedBox(width: 10),
          Text('Rest Timer'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose rest duration',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: presets.map((seconds) {
                final selected = selectedSeconds == seconds;

                return ChoiceChip(
                  label: Text('${seconds}s'),
                  selected: selected,
                  selectedColor: Colors.orange,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: isRunning
                      ? null
                      : (_) => selectPreset(seconds),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 172,
                    height: 172,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      backgroundColor: Colors.white12,
                      color: finished
                          ? Colors.greenAccent
                          : Colors.orange,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 37,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        finished
                            ? 'REST COMPLETE'
                            : isRunning
                            ? 'RESTING'
                            : 'READY',
                        style: TextStyle(
                          color: finished
                              ? Colors.greenAccent
                              : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isRunning ? pauseTimer : startTimer,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                    ),
                    icon: Icon(
                      isRunning
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      isRunning ? 'Pause' : 'Start',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: resetTimer,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
