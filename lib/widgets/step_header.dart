import 'package:flutter/material.dart';

class StepHeader extends StatelessWidget {
  final int step; // étape actuelle (1 à 4)

  const StepHeader({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStep(
          icon: Icons.list_alt,
          label: "Type",
          currentStep: step,
          stepNumber: 1,
        ),
        _buildLine(step > 1),
        _buildStep(
          icon: Icons.place,
          label: "Départ",
          currentStep: step,
          stepNumber: 2,
        ),
        _buildLine(step > 2),
        _buildStep(
          icon: Icons.flag,
          label: "Destination",
          currentStep: step,
          stepNumber: 3,
        ),
        _buildLine(step > 3),
        _buildStep(
          icon: Icons.check_circle,
          label: "Résumé",
          currentStep: step,
          stepNumber: 4,
        ),
      ],
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required int currentStep,
    required int stepNumber,
  }) {
    bool isActive = currentStep == stepNumber;
    bool isDone = currentStep > stepNumber;

    Color bgColor;
    Color iconColor;

    if (isDone) {
      bgColor = Colors.green;
      iconColor = Colors.white;
    } else if (isActive) {
      bgColor = Colors.blue;
      iconColor = Colors.white;
    } else {
      bgColor = Colors.grey.shade300;
      iconColor = Colors.black54;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive || isDone ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
    );
  }
}
