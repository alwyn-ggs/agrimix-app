import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_analytics_service.dart';
import '../../models/notification_analytics.dart';
import '../../theme/theme.dart';

class NotificationAnalyticsPage extends StatefulWidget {
  const NotificationAnalyticsPage({super.key});

  @override
  State<NotificationAnalyticsPage> createState() => _NotificationAnalyticsPageState();
}

class _NotificationAnalyticsPageState extends State<NotificationAnalyticsPage> {
  final NotificationAnalyticsService _analyticsService = NotificationAnalyticsService();
  NotificationAnalytics? _analytics;
  NotificationPerformanceSummary? _performanceSummary;
  List<Map<String, dynamic>> _engagementTrends = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  final String _selectedGranularity = 'daily';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    try {
      final analytics = await _analyticsService.getUserAnalytics(currentUser.uid);
      final now = DateTime.now();
      final startDate = _getStartDateForPeriod(now, _selectedPeriod);
      
      final performanceSummary = await _analyticsService.getPerformanceSummary(
        currentUser.uid,
        startDate: startDate,
        endDate: now,
      );
      
      final engagementTrends = await _analyticsService.getEngagementTrends(
        currentUser.uid,
        startDate: startDate,
        endDate: now,
        granularity: _selectedGranularity,
      );

      setState(() {
        _analytics = analytics;
        _performanceSummary = performanceSummary;
        _engagementTrends = engagementTrends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load analytics');
    }
  }

  DateTime _getStartDateForPeriod(DateTime now, String period) {
    switch (period) {
      case 'day':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      case 'year':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_analytics == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load analytics'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAnalytics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: NatureColors.natureBackground,
      appBar: AppBar(
        title: const Text('Notification Analytics'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: NatureColors.pureWhite,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _isLoading = true;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'day', child: Text('Last 24 Hours')),
              PopupMenuItem(value: 'week', child: Text('Last 7 Days')),
              PopupMenuItem(value: 'month', child: Text('Last 30 Days')),
              PopupMenuItem(value: 'year', child: Text('Last Year')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildEngagementChart(),
            const SizedBox(height: 24),
            _buildPerformanceMetrics(),
            const SizedBox(height: 24),
            _buildNotificationTypesChart(),
            const SizedBox(height: 24),
            _buildHourlyDistributionChart(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Total Sent',
            value: _analytics!.totalNotificationsSent.toString(),
            icon: Icons.send,
            color: NatureColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Open Rate',
            value: '${(_analytics!.openRate * 100).toStringAsFixed(1)}%',
            icon: Icons.visibility,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: NatureColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: NatureColors.mediumGray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    if (_engagementTrends.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No engagement data available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engagement Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _engagementTrends.length) return const Text('');
                          final data = _engagementTrends[value.toInt()];
                          final date = data['date'] as String;
                          return Text(
                            _formatDateLabel(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _engagementTrends.asMap().entries.map((entry) {
                        final data = entry.value;
                        return FlSpot(
                          entry.key.toDouble(),
                          (data['openRate'] as double) * 100,
                        );
                      }).toList(),
                      isCurved: true,
                      color: NatureColors.primaryGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: NatureColors.primaryGreen.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_performanceSummary == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'Open Rate',
                    value: '${(_performanceSummary!.openRate * 100).toStringAsFixed(1)}%',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'Click Rate',
                    value: '${(_performanceSummary!.clickRate * 100).toStringAsFixed(1)}%',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'Dismiss Rate',
                    value: '${(_performanceSummary!.dismissRate * 100).toStringAsFixed(1)}%',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPerformanceMetric(
                    title: 'Engagement Score',
                    value: '${_performanceSummary!.engagementScore.toStringAsFixed(0)}/100',
                    color: _getEngagementScoreColor(_performanceSummary!.engagementScore),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getEngagementScoreColor(_performanceSummary!.engagementScore).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getEngagementScoreColor(_performanceSummary!.engagementScore).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getEngagementScoreIcon(_performanceSummary!.engagementScore),
                    color: _getEngagementScoreColor(_performanceSummary!.engagementScore),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Performance: ${_performanceSummary!.performanceRating}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getEngagementScoreColor(_performanceSummary!.engagementScore),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: NatureColors.mediumGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypesChart() {
    if (_analytics!.notificationsByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications by Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _analytics!.notificationsByType.entries.map((entry) {
                    final colors = [
                      NatureColors.primaryGreen,
                      Colors.blue,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.teal,
                    ];
                    final colorIndex = _analytics!.notificationsByType.keys.toList().indexOf(entry.key);
                    final color = colors[colorIndex % colors.length];
                    
                    return PieChartSectionData(
                      color: color,
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                ..._analytics!.notificationsByType.entries.map((entry) {
                final colors = [
                  NatureColors.primaryGreen,
                  Colors.blue,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                  Colors.teal,
                ];
                final colorIndex = _analytics!.notificationsByType.keys.toList().indexOf(entry.key);
                final color = colors[colorIndex % colors.length];
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getNotificationTypeTitle(entry.key),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }),
            ],
        )],
        ),
      ),
    );
  }

  Widget _buildHourlyDistributionChart() {
    if (_analytics!.notificationsByHour.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _analytics!.notificationsByHour.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          return Text(
                            '$hour:00',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _analytics!.notificationsByHour.entries.map((entry) {
                    return BarChartGroupData(
                      x: int.parse(entry.key),
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: NatureColors.primaryGreen,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_analytics!.recentEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._analytics!.recentEvents.take(10).map((event) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getEventColor(event.type),
                  child: Icon(
                    _getEventIcon(event.type),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(_getEventTitle(event.type)),
                subtitle: Text(
                  '${_getNotificationTypeTitle(event.notificationType)} • ${_formatRelativeTime(event.timestamp)}',
                ),
                trailing: Text(
                  _formatTime(event.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(String date) {
    final parts = date.split(' ');
    if (parts.length > 1) {
      return parts[1]; // Return time part for hourly
    }
    return date.split('-').last; // Return day for daily
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getEngagementScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.red;
    return Colors.grey;
  }

  IconData _getEngagementScoreIcon(double score) {
    if (score >= 80) return Icons.trending_up;
    if (score >= 60) return Icons.trending_flat;
    if (score >= 40) return Icons.trending_down;
    return Icons.warning;
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'sent':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'opened':
        return Colors.orange;
      case 'clicked':
        return Colors.purple;
      case 'dismissed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'sent':
        return Icons.send;
      case 'delivered':
        return Icons.check_circle;
      case 'opened':
        return Icons.visibility;
      case 'clicked':
        return Icons.touch_app;
      case 'dismissed':
        return Icons.close;
      default:
        return Icons.notifications;
    }
  }

  String _getEventTitle(String type) {
    switch (type) {
      case 'sent':
        return 'Notification Sent';
      case 'delivered':
        return 'Notification Delivered';
      case 'opened':
        return 'Notification Opened';
      case 'clicked':
        return 'Notification Clicked';
      case 'dismissed':
        return 'Notification Dismissed';
      default:
        return 'Notification Event';
    }
  }

  String _getNotificationTypeTitle(String type) {
    switch (type) {
      case 'announcements':
        return 'Announcements';
      case 'fermentation_reminders':
        return 'Fermentation Reminders';
      case 'community_updates':
        return 'Community Updates';
      case 'moderation_alerts':
        return 'Moderation Alerts';
      case 'system_updates':
        return 'System Updates';
      case 'marketing':
        return 'Marketing';
      default:
        return type;
    }
  }
}
