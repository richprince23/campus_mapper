// import 'package:campus_mapper/features/Explore/pages/location_detail_screen.dart';
// import 'package:flutter/material.dart';

// class SearchResultsScreen extends StatefulWidget {
//   final String query;

//   SearchResultsScreen({required this.query});

//   @override
//   _SearchResultsScreenState createState() => _SearchResultsScreenState();
// }

// class _SearchResultsScreenState extends State<SearchResultsScreen> {
//   bool isGrid = false;
//   double maxDistance = 1000;

//   final results = List.generate(
//       6,
//       (i) => {
//             'name': 'Coffee Spot $i',
//             'rating': '4.${5 - i}',
//             'distance': '${100 * (i + 1)}m',
//             'photo': 'https://placehold.co/600x4000',
//           });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Results for '${widget.query}'"),
//         actions: [
//           IconButton(
//               icon: Icon(isGrid ? Icons.list : Icons.grid_view),
//               onPressed: () {
//                 setState(() => isGrid = !isGrid);
//               }),
//           IconButton(
//               icon: Icon(Icons.filter_list),
//               onPressed: () => _openFilters(context)),
//         ],
//       ),
//       body: isGrid
//           ? GridView.count(
//               padding: EdgeInsets.all(16),
//               crossAxisCount: 2,
//               mainAxisSpacing: 12,
//               crossAxisSpacing: 12,
//               childAspectRatio: 0.8,
//               children: results.map((loc) => LocationCard(loc)).toList(),
//             )
//           : ListView(
//               padding: EdgeInsets.all(16),
//               children: results.map((loc) => LocationCard(loc)).toList(),
//             ),
//     );
//   }

//   void _openFilters(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setModalState) => Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text("Distance: ${maxDistance.toInt()}m"),
//               Slider(
//                 value: maxDistance,
//                 min: 100,
//                 max: 2000,
//                 onChanged: (val) => setModalState(() => maxDistance = val),
//               ),
//               SizedBox(height: 8),
//               ElevatedButton(
//                 child: Text("Apply"),
//                 onPressed: () {
//                   Navigator.pop(context);
//                   // Apply filter logic here
//                 },
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget LocationCard(Map<String, String> loc) {
//     return Card(
//       child: ListTile(
//         leading: Image.network(loc['photo']!,
//             width: 60, height: 60, fit: BoxFit.cover),
//         title: Text(loc['name']!),
//         subtitle: Text("⭐ ${loc['rating']} • 📍 ${loc['distance']}"),
//         trailing: Icon(Icons.chevron_right),
//         onTap: () {
//           Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => LocationDetailScreen(name: loc['name']!),
//               ));
//         },
//       ),
//     );
//   }
// }
