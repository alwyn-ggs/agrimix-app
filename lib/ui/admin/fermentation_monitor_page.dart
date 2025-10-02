import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_fermentation_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/fermentation_log.dart';
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
    
    final totalActive = activeData.values.fold(0, (sum, count) => sum + count);
    final totalCompleted = completedData.values.fold(0, (sum, count) => sum + count);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up_outlined,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active vs Completed Logs',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Fermentation activity over last 30 days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Summary Stats
              Row(
                children: [
                  Expanded(
                    child: _buildTrendStatCard(
                      'Active Logs',
                      totalActive.toString(),
                      Icons.play_circle_outline,
                      Colors.orange.shade600,
                      'Currently fermenting',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTrendStatCard(
                      'Completed',
                      totalCompleted.toString(),
                      Icons.check_circle_outline,
                      Colors.green.shade600,
                      'Successfully finished',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) {
                            if (value == value.toInt().toDouble()) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < dates.length && index % 7 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  dates[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        left: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.grey.shade800,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final isActive = barSpot.barIndex == 0;
                            return LineTooltipItem(
                              '${isActive ? 'Active' : 'Completed'}: ${barSpot.y.toInt()}\\n${dates[barSpot.x.toInt()]}',
                              TextStyle(
                                color: isActive ? Colors.orange.shade300 : Colors.green.shade300,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: dates.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), activeData[entry.value]?.toDouble() ?? 0);
                        }).toList(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.orange.shade600,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.orange.shade200.withValues(alpha: 0.3),
                              Colors.orange.shade100.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                      LineChartBarData(
                        spots: dates.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), completedData[entry.value]?.toDouble() ?? 0);
                        }).toList(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.green.shade600,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.green.shade200.withValues(alpha: 0.3),
                              Colors.green.shade100.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Enhanced Legend
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEnhancedLegendItem(
                      'Active Logs',
                      Colors.orange.shade600,
                      Icons.play_circle_outline,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    _buildEnhancedLegendItem(
                      'Completed',
                      Colors.green.shade600,
                      Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodBreakdownChart(AdminFermentationProvider provider) {
    final methodData = provider.getMethodBreakdown();
    final totalMethods = (methodData['FFJ'] ?? 0) + (methodData['FPJ'] ?? 0);
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pie_chart_outline,
                      color: Colors.purple.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Method Breakdown',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Distribution of fermentation methods',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (totalMethods == 0)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No method data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 500) {
                      // Mobile layout - Stack vertically
                      return Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: methodData['FFJ']?.toDouble() ?? 0,
                                title: '',
                                color: Colors.purple.shade600,
                                radius: constraints.maxWidth < 500 ? 60 : 70,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.purple.shade700,
                                  ],
                                ),
                              ),
                              PieChartSectionData(
                                value: methodData['FPJ']?.toDouble() ?? 0,
                                title: '',
                                color: Colors.teal.shade600,
                                radius: constraints.maxWidth < 500 ? 60 : 70,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.teal.shade400,
                                    Colors.teal.shade700,
                                  ],
                                ),
                              ),
                            ],
                            sectionsSpace: 3,
                            centerSpaceRadius: constraints.maxWidth < 500 ? 30 : 35,
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                // Add touch feedback if needed
                              },
                            ),
                          ),
                        ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Legend and Stats - Mobile
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMethodLegendItem(
                                      'FFJ',
                                      'Fermented Fruit Juice',
                                      methodData['FFJ'] ?? 0,
                                      totalMethods,
                                      Colors.purple.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildMethodLegendItem(
                                      'FPJ',
                                      'Fermented Plant Juice',
                                      methodData['FPJ'] ?? 0,
                                      totalMethods,
                                      Colors.teal.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      color: Colors.grey.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      children: [
                                        Text(
                                          'Total Methods',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          totalMethods.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                      } else {
                        // Desktop layout - Side by side
                        return Row(
                          children: [
                            // Pie Chart
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: methodData['FFJ']?.toDouble() ?? 0,
                                        title: '',
                                        color: Colors.purple.shade600,
                                        radius: 70,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.purple.shade400,
                                            Colors.purple.shade700,
                                          ],
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: methodData['FPJ']?.toDouble() ?? 0,
                                        title: '',
                                        color: Colors.teal.shade600,
                                        radius: 70,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.teal.shade400,
                                            Colors.teal.shade700,
                                          ],
                                        ),
                                      ),
                                    ],
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 35,
                                    pieTouchData: PieTouchData(
                                      enabled: true,
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        // Add touch feedback if needed
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Legend and Stats
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // FFJ Legend
                                  _buildMethodLegendItem(
                                    'FFJ',
                                    'Fermented Fruit Juice',
                                    methodData['FFJ'] ?? 0,
                                    totalMethods,
                                    Colors.purple.shade600,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // FPJ Legend
                                  _buildMethodLegendItem(
                                    'FPJ',
                                    'Fermented Plant Juice',
                                    methodData['FPJ'] ?? 0,
                                    totalMethods,
                                    Colors.teal.shade600,
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Total Count
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.analytics_outlined,
                                          color: Colors.grey.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Methods',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              Text(
                                                totalMethods.toString(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAverageCompletionTimeChart(AdminFermentationProvider provider) {
    final completionData = provider.getAverageCompletionTime();
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average Completion Time',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Days to complete fermentation',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: completionData.values.isEmpty 
                        ? 10.0 
                        : (completionData.values.reduce((a, b) => a > b ? a : b) * 1.3).clamp(10.0, double.infinity),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.grey.shade800,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final method = groupIndex == 0 ? 'FFJ' : 'FPJ';
                          return BarTooltipItem(
                            '$method\\n${rod.toY.toStringAsFixed(1)} days',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return Container(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'FFJ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${completionData['FFJ']?.toStringAsFixed(1) ?? '0'}d',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              case 1:
                                return Container(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'FPJ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${completionData['FPJ']?.toStringAsFixed(1) ?? '0'}d',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}d',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                        left: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: completionData['FFJ'] ?? 0,
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.purple.shade400,
                                Colors.purple.shade600,
                              ],
                            ),
                            width: 50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: completionData['FPJ'] ?? 0,
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.teal.shade400,
                                Colors.teal.shade600,
                              ],
                            ),
                            width: 50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
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
      ),
    );
  }

  Widget _buildMostUsedIngredientsChart(AdminFermentationProvider provider) {
    final ingredientsData = provider.getMostUsedIngredients(limit: 6);
    final totalUsage = ingredientsData.values.fold(0, (sum, count) => sum + count);
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.green.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.eco_outlined,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Most Used Ingredients',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Popular ingredients in fermentation',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (ingredientsData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.eco,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No ingredient data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Ingredient List with Progress Bars
                ...ingredientsData.entries.take(6).map((entry) {
                  final percentage = totalUsage > 0 ? (entry.value / totalUsage * 100) : 0.0;
                  final color = _getIngredientColor(ingredientsData.keys.toList().indexOf(entry.key));
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.value} uses',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                
                // Summary Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIngredientStat(
                        'Total Types',
                        ingredientsData.length.toString(),
                        Icons.category,
                        Colors.blue,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _buildIngredientStat(
                        'Total Usage',
                        totalUsage.toString(),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _buildIngredientStat(
                        'Most Popular',
                        ingredientsData.isNotEmpty ? _truncateText(ingredientsData.entries.first.key, 8) : 'None',
                        Icons.star,
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
                      backgroundColor: log.method == FermentationMethod.ffj 
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

  Widget _buildIngredientStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getIngredientColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.red.shade600,
    ];
    return colors[index % colors.length];
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildTrendStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodLegendItem(String method, String description, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                method,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$count logs',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
