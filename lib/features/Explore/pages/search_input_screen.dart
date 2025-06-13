// import 'package:campus_mapper/features/Explore/pages/location_detail_screen.dart';
// import 'package:campus_mapper/features/Explore/pages/searc_results_screen.dart';
// import 'package:flutter/material.dart';

// class SearchInputScreen extends StatefulWidget {
//   @override
//   _SearchInputScreenState createState() => _SearchInputScreenState();
// }

// class _SearchInputScreenState extends State<SearchInputScreen> {
//   String query = "";
//   final suggestions = [
//     'Coffee Bean',
//     'Café Campus',
//     'Coffee Shops',
//     'Café Hallway'
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final filtered = suggestions
//         .where((s) => s.toLowerCase().contains(query.toLowerCase()))
//         .toList();

//     return Scaffold(
//       appBar: AppBar(
//           title: TextField(
//         autofocus: true,
//         onChanged: (v) => setState(() => query = v),
//         decoration: InputDecoration(hintText: 'Search...'),
//       )),
//       body: ListView.builder(
//         itemCount: filtered.length,
//         itemBuilder: (context, i) {
//           final text = filtered[i];
//           return ListTile(
//             title: Text(text),
//             trailing: text.toLowerCase().contains('shop') ||
//                     text.toLowerCase().contains('café')
//                 ? TextButton(
//                     child: Text("View all"),
//                     onPressed: () {
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => SearchResultsScreen(query: query),
//                           ));
//                     })
//                 : null,
//             onTap: () {
//               Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => LocationDetailScreen(name: text),
//                   ));
//             },
//           );
//         },
//       ),
//     );
//   }
// }
