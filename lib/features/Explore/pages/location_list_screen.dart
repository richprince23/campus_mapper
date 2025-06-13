import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_mapper/features/Explore/pages/location_detail_screen.dart';
import 'package:flutter/material.dart';

class FullCategoryScreen extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;

  FullCategoryScreen({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              leading: CachedNetworkImage(
                  imageUrl: item['photo']!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover),
              title: Text(item['name']!),
              subtitle: Text(item['info']!),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContextDetailScreen(name: item['name']!),
                    ));
              },
            ),
          );
        },
      ),
    );
  }
}
