import 'package:flutter/material.dart';
import 'user_properties_screen.dart';

class ProprietaireDashboard extends StatelessWidget {
  const ProprietaireDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardItems = [
      DashboardItem(Icons.home, "Mes Logements", Colors.indigo),
      DashboardItem(Icons.how_to_reg, "Candidatures", Colors.orange),
      DashboardItem(Icons.group, "Colocations", Colors.teal),
      DashboardItem(Icons.attach_money, "Paiements", Colors.green),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Propriétaire')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: dashboardItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final item = dashboardItems[index];
            return DashboardCard(item: item);
          },
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
