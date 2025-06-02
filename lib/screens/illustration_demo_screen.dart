import 'package:flutter/material.dart';
import 'package:ms_undraw/ms_undraw.dart';
import 'package:wall_e/utils/undraw_illustrations.dart';

class IllustrationDemoScreen extends StatelessWidget {
  const IllustrationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WALL-E Illustrations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onboarding Illustrations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            UndrawIllustrations.welcome,
            const SizedBox(height: 16),
            UndrawIllustrations.environmentalCare,
            
            const SizedBox(height: 32),
            const Text(
              'Empty States',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            UndrawIllustrations.emptyBox,
            const SizedBox(height: 16),
            UndrawIllustrations.noData,
            
            const SizedBox(height: 32),
            const Text(
              'Success & Error States',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                UndrawIllustrations.success,
                UndrawIllustrations.error,
              ],
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Feature Illustrations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            UndrawIllustrations.recycling,
            const SizedBox(height: 16),
            UndrawIllustrations.wasteSorting,
            const SizedBox(height: 16),
            UndrawIllustrations.environmentalProtection,
            
            const SizedBox(height: 32),
            const Text(
              'Loading State',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            UndrawIllustrations.loading,
            
            const SizedBox(height: 32),
            const Text(
              'Custom Illustration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            UndrawIllustrations.custom(
              illustration: UnDrawIllustration.welcome,
              color: Theme.of(context).primaryColor,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
} 