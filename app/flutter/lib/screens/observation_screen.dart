import 'package:flutter/material.dart';

import '../models/experience_state_summary.dart';
import '../widgets/primary_button.dart';

class ObservationScreen extends StatelessWidget {
  const ObservationScreen({
    required this.summary,
    required this.observations,
    required this.onRestart,
    super.key,
  });

  final ExperienceStateSummary summary;
  final List<String> observations;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'O que observamos',
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${summary.totalInteractions} interações registradas nesta sessão.',
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF57544D),
                            ),
                          ),
                          const SizedBox(height: 28),
                          ...observations.map(
                            (observation) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Text(
                                    observation,
                                    style: textTheme.bodyLarge?.copyWith(
                                      height: 1.38,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PrimaryButton(
                              label: 'Recomeçar',
                              icon: Icons.refresh,
                              onPressed: onRestart,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
