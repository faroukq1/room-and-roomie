// // main.dart
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(RoomAndRoomieApp());
// }
//
// class RoomAndRoomieApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'ROOM & ROOMIE',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: HomePage(),
//     );
//   }
// }
//
// // 1. Home Page with Navigation Bar and Listings
// class HomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ROOM & ROOMIE'),
//         centerTitle: true,
//       ),
//       body: ListView(
//         padding: EdgeInsets.all(16),
//         children: List.generate(6, (index) => ListingCard()),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         items: [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
//           BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Inbox'),
//           BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
//         ],
//       ),
//     );
//   }
// }
//
// class ListingCard extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('7000 DA près de Annaba',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             SizedBox(height: 8),
//             Text('2 chambres / 1 salle de bain / 1 salon'),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // 2. Login Page
// class LoginPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Login")),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(decoration: InputDecoration(labelText: 'Email')),
//             TextField(
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(onPressed: () {}, child: Text('Login')),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // 3. Sign-Up Page
// class SignUpPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Sign-Up")),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(decoration: InputDecoration(labelText: 'Username')),
//             TextField(decoration: InputDecoration(labelText: 'Email')),
//             TextField(
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             TextField(
//               decoration: InputDecoration(labelText: 'Confirm Password'),
//               obscureText: true,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(onPressed: () {}, child: Text('Sign-Up')),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // 4. Profile Page
// class ProfilePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Profile")),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Name'),
//             TextField(),
//             SizedBox(height: 10),
//             Text('Email'),
//             TextField(),
//             SizedBox(height: 10),
//             Text('Password'),
//             TextField(obscureText: true),
//             SizedBox(height: 20),
//             ElevatedButton(onPressed: () {}, child: Text('Edit Profile')),
//             ElevatedButton(onPressed: () {}, child: Text('Payment Details')),
//             TextButton(onPressed: () {}, child: Text('Log out')),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // 5. Filter Page (Price and Rooms)
// class FilterPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Filters")),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Text('Price Range'),
//             TextField(decoration: InputDecoration(labelText: 'Minimum')),
//             TextField(decoration: InputDecoration(labelText: 'Maximum')),
//             SizedBox(height: 20),
//             Text('Rooms'),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: List.generate(4, (index) {
//                 return ChoiceChip(label: Text('${index + 1}'), selected: false);
//               }),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(onPressed: () {}, child: Text('Confirm')),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // 6. Favorites Page
// class FavoritesPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Favorites")),
//       body: Center(
//         child: Text("Login to see your favorites lists"),
//       ),
//     );
//   }
// }
//
// // 7. Messaging Page
// class MessagingPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Messages")),
//       body: ListView(
//         padding: EdgeInsets.all(16),
//         children: [
//           Text(
//               "Cool ! Et du coup, comment ça se passe ici ? Y’a des règles à savoir?",
//               style: TextStyle(fontSize: 16)),
//           SizedBox(height: 12),
//           Text(
//               "Pas vraiment, on essaie juste de garder les espaces communs propres et de se tenir au courant si on invite du monde",
//               style: TextStyle(color: Colors.grey[700])),
//           SizedBox(height: 20),
//           TextField(decoration: InputDecoration(labelText: 'Type here...')),
//         ],
//       ),
//     );
//   }
// }
