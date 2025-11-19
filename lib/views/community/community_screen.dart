import 'package:flutter/material.dart';
import '../../models/support_group.dart';
import 'support_groups_tab.dart';
import 'resources_tab.dart';
import 'success_stories_tab.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.groups),
              text: 'Support Groups',
            ),
            Tab(
              icon: Icon(Icons.library_books),
              text: 'Resources',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Success Stories',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SupportGroupsTab(),
          ResourcesTab(),
          SuccessStoriesTab(),
        ],
      ),
    );
  }
}