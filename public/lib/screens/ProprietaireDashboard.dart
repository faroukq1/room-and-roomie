import 'package:flutter/material.dart';
import 'user_properties_screen.dart';
import 'ProprietairePaymentsScreen.dart';
import 'ProprietaireColocsScreen.dart';

class ProprietaireDashboard extends StatelessWidget {
  const ProprietaireDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardItems = [
      DashboardItem(Icons.home, "Mes Logements", Colors.indigo),
      DashboardItem(Icons.group, "Colocations", Colors.teal),
      DashboardItem(Icons.attach_money, "Paiements", Colors.green),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Propriétaire')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: SizedBox.expand(
                child: DashboardCard(item: dashboardItems[0]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SizedBox.expand(
                child: DashboardCard(item: dashboardItems[1]),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SizedBox.expand(
                child: DashboardCard(item: dashboardItems[2]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardItem {
  final IconData icon;
  final String title;
  final Color color;

  DashboardItem(this.icon, this.title, this.color);
}

class DashboardCard extends StatelessWidget {
  final DashboardItem item;

  const DashboardCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: item.color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (item.title == "Mes Logements") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserPropertiesScreen(),
              ),
            );
          } else if (item.title == "Paiements") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProprietairePaymentsScreen(),
              ),
            );
          } else if (item.title == "Colocations") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProprietaireColocsScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${item.title} clicked!')));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 40, color: item.color),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
