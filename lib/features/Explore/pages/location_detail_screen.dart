import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ContextDetailScreen extends StatelessWidget {
  final String name;

  ContextDetailScreen({required this.name});

  @override
  Widget build(BuildContext context) {
    final related = ['Place A', 'Place B', 'Place C'];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          CachedNetworkImage(
              imageUrl: 'https://placehold.co/600x400.png',
              height: 200,
              fit: BoxFit.cover),
          SizedBox(height: 16),
          Text(name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Noise: Low • WiFi: Strong • Open: 24hrs"),
          SizedBox(height: 12),
          Text(
              "Great for focused studying. Students rate it highly for quiet and comfortable atmosphere."),
          SizedBox(height: 20),
          Text("Also popular for studying",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ...related.map((e) => ListTile(
                title: Text(e),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              )),
        ],
      ),
    );
  }
}
