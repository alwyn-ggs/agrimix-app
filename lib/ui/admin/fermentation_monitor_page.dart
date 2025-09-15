import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_fermentation_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/fermentation_log.dart';
import '../../models/user.dart';
import 'fermentation_log_detail_page.dart';

class FermentationMonitorPage extends StatefulWidget {
  const FermentationMonitorPage({super.key});

  @override
  State<FermentationMonitorPage> createState() => _FermentationMonitorPageState();
}

class _FermentationMonitorPageState extends State<FermentationMonitorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminFermentationProvider = context.read<AdminFermentationProvider>();
      final adminProvider = context.read<AdminProvider>();
      
      // Set farmers from admin provider
      adminFermentationProvider.setFarmers(adminProvider.users);
      
      // Start monitoring
      adminFermentationProvider.startMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fermentation Monitoring'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AdminFermentationProvider>().startMonitoring();
            },
          ),
        ],
      ),
      body: Consumer<AdminFermentationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading data',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.startMonitoring();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              provider.startMonitoring();
            },
            child: SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatisticsCards(provider),
                    const SizedBox(height: 12),
                    _buildActiveVsCompletedChart(provider),
                    const SizedBox(height: 12),
                    _buildMethodBreakdownChart(provider),
                    const SizedBox(height: 12),
                    _buildAverageCompletionTimeChart(provider),
                    const SizedBox(height: 12),
                    _buildMostUsedIngredientsChart(provider),
                    const SizedBox(height: 12),
                    _buildRecentLogsList(provider),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards(AdminFermentationProvider provider) {
    final stats = provider.getStatistics();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
            final childAspectRatio = crossAxisCount == 2 ? 1.6 : 1.1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStatCard('Total Logs', stats['total'] ?? 0, Icons.list_alt, Colors.blue),
                _buildStatCard('Active', stats['active'] ?? 0, Icons.play_circle, Colors.orange),
                _buildStatCard('Completed', stats['completed'] ?? 0, Icons.check_circle, Colors.green),
                _buildStatCard('FFJ', stats['ffj'] ?? 0, Icons.local_florist, Colors.purple),
                _buildStatCard('FPJ', stats['fpj'] ?? 0, Icons.eco, Colors.teal),
                _buildStatCard('Overdue', provider.getOverdueLogs().length, Icons.warning, Colors.red),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(icon, color: color, size: 18), // Slightly smaller icon
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveVsCompletedChart(AdminFermentationProvider provider) {
    final chartData = provider.getActiveVsCompletedOverTime();
    final dates = chartData['dates'] as List<String>;
    final activeData = chartData['active'] as Map<String, int>;
    final completedData = chartData['completed'] as Map<String, int>;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active vs Completed Logs (Last 30 Days)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Only show integer values and limit the number of labels
                          if (value == value.toInt().toDouble()) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length && index % 5 == 0) {
                            return Text(dates[index], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dates.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), activeData[entry.value]?.toDouble() ?? 0);
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: dates.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), completedData[entry.value]?.toDouble() ?? 0);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Active', Colors.orange),
                const SizedBox(width: 24),
                _buildLegendItem('Completed', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodBreakdownChart(AdminFermentationProvider provider) {
    final methodData = provider.getMethodBreakdown();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Method Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: methodData['FFJ']?.toDouble() ?? 0,
                      title: 'FFJ\n${methodData['FFJ'] ?? 0}',
                      color: Colors.purple,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: methodData['FPJ']?.toDouble() ?? 0,
                      title: 'FPJ\n${methodData['FPJ'] ?? 0}',
                      color: Colors.teal,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageCompletionTimeChart(AdminFermentationProvider provider) {
    final completionData = provider.getAverageCompletionTime();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Completion Time (Days)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: completionData.values.isEmpty 
                      ? 10.0 
                      : (completionData.values.reduce((a, b) => a > b ? a : b) * 1.2).clamp(10.0, double.infinity),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('FFJ');
                            case 1:
                              return const Text('FPJ');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: completionData['FFJ'] ?? 0,
                          color: Colors.purple,
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: completionData['FPJ'] ?? 0,
                          color: Colors.teal,
                          width: 40,
                        ),
                      ],
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

  Widget _buildMostUsedIngredientsChart(AdminFermentationProvider provider) {
    final ingredientsData = provider.getMostUsedIngredients(limit: 8);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Used Ingredients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: ingredientsData.values.isEmpty 
                      ? 10.0 
                      : (ingredientsData.values.reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final ingredients = ingredientsData.keys.toList();
                          if (index >= 0 && index < ingredients.length) {
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                ingredients[index],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: ingredientsData.entries.map((entry) {
                    final index = ingredientsData.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.blue.withOpacity(0.7),
                          width: 20,
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

  Widget _buildRecentLogsList(AdminFermentationProvider provider) {
    final recentLogs = provider.allLogs.take(5).toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Fermentation Logs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (recentLogs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No fermentation logs found'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentLogs.length,
                itemBuilder: (context, index) {
                  final log = recentLogs[index];
                  final farmer = provider.getFarmerForLog(log.ownerUid);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: log.method == FermentationMethod.FFJ 
                          ? Colors.purple 
                          : Colors.teal,
                      child: Text(
                        log.method.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(log.title),
                    subtitle: Text('${farmer?.name ?? 'Unknown Farmer'} • ${_formatDate(log.createdAt)}'),
                    trailing: _buildStatusChip(log.status),
                    onTap: () {
                      if (farmer != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FermentationLogDetailPage(
                              log: log,
                              farmer: farmer,
                              isReadOnly: true,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildStatusChip(FermentationStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case FermentationStatus.active:
        color = Colors.orange;
        label = 'Active';
        break;
      case FermentationStatus.done:
        color = Colors.green;
        label = 'Done';
        break;
      case FermentationStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
