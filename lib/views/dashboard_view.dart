import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'documents_view.dart';
import 'forum_view.dart';
import 'reviews_view.dart';
import 'store_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _index = 0;
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    const tabs = [
      DocumentsView(),
      ForumView(),
      ReviewsView(),
      StoreView(),
    ];

    return StreamBuilder<UserModel?>(
      stream: _db.userStream(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mạng Xã Hội Sinh Viên'),
            actions: [
              if (user != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Chip(
                      avatar: const Icon(Icons.stars, size: 18, color: Colors.amber),
                      label: Text('${user.points} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () => AuthService().signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Column(
            children: [
              if (user != null)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    '${user.name} • ${user.msv.isNotEmpty ? user.msv : 'SV'} • ${user.university}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ),
              Expanded(child: IndexedStack(index: _index, children: tabs)),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.folder), label: 'Tài liệu'),
              NavigationDestination(icon: Icon(Icons.forum), label: 'Chém gió'),
              NavigationDestination(icon: Icon(Icons.rate_review), label: 'Review'),
              NavigationDestination(icon: Icon(Icons.store), label: 'Cửa hàng'),
            ],
          ),
        );
      },
    );
  }
}