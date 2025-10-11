import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../community/post_list_page.dart';
import '../../community/saved_posts_page.dart';
import '../../../providers/community_provider.dart';
import '../../../theme/theme.dart';
import '../../../l10n/app_localizations.dart';


class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {

  @override
  void initState() {
    super.initState();
    
    // Load data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final communityProvider = context.read<CommunityProvider>();
    
    // Load posts for community feed
    communityProvider.loadPosts(refresh: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: Text(t.t('community')),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              // Navigate to saved posts page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedPostsPage(),
                ),
              );
            },
            tooltip: t.t('saved_posts'),
          ),
          // Hide moderation entry point on user side
        ],
      ),
      body: const PostListPage(),
    );
  }
}