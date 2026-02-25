import 'package:flutter/material.dart';
import 'package:xoolibeut_livreur/providers/livreur_provider.dart';
import 'package:xoolibeut_livreur/services/livraison_service.dart';
import '../models/livraison.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class LivreurDashboardProScreen extends StatelessWidget {
  final LivraisonService livraisonService;

  const LivreurDashboardProScreen({super.key, required this.livraisonService});

  Widget proCard({
    required String title,
    required String value,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 18, color: Colors.grey),
              if (icon != null) const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget monthlyChart(List<int> values) {
    final months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];

    final maxValue =
        (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b)) + 5;

    // Pour gérer quelle barre est touchée
    int touchedIndex = -1;

    return StatefulBuilder(
      builder: (context, setState) {
        return BarChart(
          BarChartData(
            maxY: maxValue.toDouble(),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(), // affiche entier
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                });
              },
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: 5,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      months[value.toInt()],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(12, (index) {
              final isTouched = index == touchedIndex;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index].toDouble(),
                    width: isTouched ? 20 : 16, // barre plus large si touchée
                    borderRadius: BorderRadius.circular(8),
                    color: isTouched ? Colors.orangeAccent : Colors.blueAccent,
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Récupération du numéroLivreur depuis le Provider
    final numeroLivreur = Provider.of<LivreurProvider>(
      context,
      listen: false,
    ).numeroLivreur;
    if (numeroLivreur == null) {
      return const Scaffold(
        body: Center(child: Text("Numéro de livreur introuvable")),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Activité"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<LivreurDashboard>(
        future: livraisonService.dashbordLivreur(
          numeroLivreur, // remplace par vrai numéro
          // remplace par vrai token
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Aucune donnée disponible"));
          }

          final dashboard = snapshot.data!;

          // ⚡ Ici tu peux utiliser ton code existant
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: proCard(
                        title: "Aujourd’hui",
                        value: dashboard.jour.toString(),
                        icon: Icons.today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: proCard(
                        title: "Ce mois",
                        value: dashboard.mois.toString(),
                        icon: Icons.calendar_month,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: proCard(
                        title: "Cette année",
                        value: dashboard.annee.toString(),
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: proCard(
                        title: "Total",
                        value: dashboard.total.toString(),
                        icon: Icons.inventory,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  "Livraisons par mois",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: monthlyChart(dashboard.livraisonsParMois),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
