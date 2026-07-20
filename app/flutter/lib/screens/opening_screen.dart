import 'package:flutter/material.dart';

import '../widgets/primary_button.dart';

class OpeningScreen extends StatelessWidget {
  const OpeningScreen({
    required this.onStart,
    required this.onOpenDeveloperDashboard,
    super.key,
  });

  final VoidCallback onStart;
  final VoidCallback onOpenDeveloperDashboard;

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
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atlas E0',
                            style: textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Toda decisão revela alguma coisa.',
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Uma sala pequena. Alguns sinais. Nenhuma resposta pronta.',
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF57544D),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 36),
                          PrimaryButton(
                            label: 'Começar',
                            icon: Icons.arrow_forward,
                            onPressed: onStart,
                          ),
                          const SizedBox(height: 18),
                          TextButton.icon(
                            onPressed: onOpenDeveloperDashboard,
                            icon: const Icon(Icons.data_object, size: 18),
                            label: const Text('Dev'),
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
