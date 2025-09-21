import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/fermentation_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/fermentation_log.dart';
import '../../fermentation/new_log_page.dart';
import '../../fermentation/log_detail_page.dart';

class FermentationTab extends StatefulWidget {
  const FermentationTab({super.key});

  @override
  State<FermentationTab> createState() => _FermentationTabState();
}

class _FermentationTabState extends State<FermentationTab> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  FermentationMethod? _methodFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize fermentation provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final fermentationProvider = context.read<FermentationProvider>();
      if (authProvider.currentUser != null) {
        fermentationProvider.watch(authProvider.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Fermentation Tracker', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.timelapse)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            Tab(text: 'All', icon: Icon(Icons.list)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () => _showNewLogPage(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogsList(FermentationStatus.active),
          _buildLogsList(FermentationStatus.done),
          _buildLogsList(null),
        ],
      ),
    );
  }

  Widget _buildLogsList(FermentationStatus? statusFilter) {
    return Consumer<FermentationProvider>(
      builder: (context, provider, child) {
        if (provider.myLogs.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        // Filter logs based on status and search query
        var filteredLogs = provider.myLogs.where((log) {
          final matchesStatus = statusFilter == null || log.status == statusFilter;
          final matchesSearch = _searchQuery.isEmpty || 
            log.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
          final matchesMethod = _methodFilter == null || log.method == _methodFilter;
          
          return matchesStatus && matchesSearch && matchesMethod;
        }).toList();

        // Sort by creation date (newest first)
        filteredLogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search fermentation logs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => setState(() => _searchQuery = ''),
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            
            // Logs list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  return _buildLogCard(context, log);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(FermentationStatus? statusFilter) {
    String message;
    IconData icon;
    
    if (statusFilter == FermentationStatus.active) {
      message = 'No active fermentations';
      icon = Icons.timelapse;
    } else if (statusFilter == FermentationStatus.done) {
      message = 'No completed fermentations';
      icon = Icons.check_circle;
    } else {
      message = 'No fermentation logs yet';
      icon = Icons.science;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first fermentation journey!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showNewLogPage(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Fermentation Log'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, FermentationLog log) {
    final progress = log.stages.isEmpty
        ? 0.0
        : (log.currentStage / log.stages.length).clamp(0.0, 1.0);
    final isOverdue = log.status == FermentationStatus.active && 
      log.stages.isNotEmpty && 
      log.currentStage < log.stages.length &&
      log.startAt.add(Duration(days: log.stages[log.currentStage].day)).isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showLogDetail(context, log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      log.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(log.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Method and start date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.method.name,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Started ${_formatDate(log.startAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              if (log.recipeId != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.restaurant_menu, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Linked to recipe',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Progress bar
              if (log.status == FermentationStatus.active) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverdue ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${log.currentStage}/${log.stages.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Current stage info
              if (log.status == FermentationStatus.active && log.stages.isNotEmpty && log.currentStage < log.stages.length) ...[
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning : Icons.timelapse,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isOverdue 
                          ? 'OVERDUE: ${log.stages[log.currentStage].label}'
                          : 'Next: ${log.stages[log.currentStage].label}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.stages[log.currentStage].action,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              
              // Photos count
              if (log.photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.photo_library, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${log.photos.length} photo${log.photos.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(FermentationStatus status) {
    switch (status) {
      case FermentationStatus.active:
        return Colors.blue;
      case FermentationStatus.done:
        return Colors.green;
      case FermentationStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;
    
    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showNewLogPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewLogPage()),
    );
  }

  void _showLogDetail(BuildContext context, FermentationLog log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LogDetailPage(),
        settings: RouteSettings(arguments: {'id': log.id}),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Logs'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Method filter
              const Text('Method:', style: TextStyle(fontWeight: FontWeight.w600)),
              RadioListTile<FermentationMethod?>(
                title: const Text('All'),
                value: null,
                groupValue: _methodFilter,
                onChanged: (value) => setDialogState(() => _methodFilter = value),
              ),
              RadioListTile<FermentationMethod?>(
                title: const Text('FFJ'),
                value: FermentationMethod.ffj,
                groupValue: _methodFilter,
                onChanged: (value) => setDialogState(() => _methodFilter = value),
              ),
              RadioListTile<FermentationMethod?>(
                title: const Text('FPJ'),
                value: FermentationMethod.fpj,
                groupValue: _methodFilter,
                onChanged: (value) => setDialogState(() => _methodFilter = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _methodFilter = null;
                });
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}