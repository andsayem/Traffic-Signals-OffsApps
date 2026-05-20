import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/traffic_sign_model.dart';
import '../providers/traffic_provider.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/traffic_sign_painter.dart';

class SignDetailsScreen extends StatelessWidget {
  final TrafficSignModel sign;
  final String countryId;

  const SignDetailsScreen({
    super.key,
    required this.sign,
    required this.countryId,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      appBar: AppBar(
        title: Text(sign.name),
      ),
      child: Consumer<TrafficDataProvider>(
        builder: (context, provider, child) {
          final isFav = provider.isFavorite(sign.id);
          final country = provider.getCountryById(countryId);
          final countryName = country?.name ?? 'General';

          // Get country specific override details if available
          final countrySpecificText = sign.countrySpecificInfo[countryId] ?? 
              "This sign follows standard international guidelines in $countryName.";

          final relatedSigns = provider.getRelatedSigns(sign);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // Large Vector Sign
              Center(
                child: Hero(
                  tag: 'sign-${sign.id}',
                  child: TrafficSignWidget(
                    signId: sign.id,
                    size: 160,
                    isGlowing: true,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Favorite Button
                  _buildActionButton(
                    context: context,
                    icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? ThemeConstants.signalRed : Colors.grey,
                    onTap: () => provider.toggleFavorite(sign.id),
                    tooltip: 'Favorite',
                  ),
                  const SizedBox(width: 20),

                  // Share Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.share_rounded,
                    color: ThemeConstants.signalBlue,
                    onTap: () => _shareSign(context),
                    tooltip: 'Share',
                  ),
                  const SizedBox(width: 20),

                  // Download Button
                  _buildActionButton(
                    context: context,
                    icon: Icons.download_rounded,
                    color: ThemeConstants.signalGreen,
                    onTap: () => _downloadSign(context),
                    tooltip: 'Download',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sign Information Details Cards
              GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(sign.category).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr(sign.category).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _getCategoryColor(sign.category),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sign.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoSection(context, 'meaning', sign.meaning),
                    const SizedBox(height: 16),
                    _buildInfoSection(context, 'usage_inst', sign.usageInstructions),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Country Specific Card
              GlassCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (country != null) ...[
                          Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          "$countryName: " + context.tr('country_info'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: ThemeConstants.signalYellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      countrySpecificText,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Related Signs
              if (relatedSigns.isNotEmpty) ...[
                Text(
                  context.tr('related_signs'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: relatedSigns.length,
                    itemBuilder: (context, index) {
                      final rel = relatedSigns[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: GlassCard(
                          onTap: () {
                            // Open new details screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignDetailsScreen(
                                  sign: rel,
                                  countryId: countryId,
                                ),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(8),
                          borderRadius: 14,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TrafficSignWidget(
                                signId: rel.id,
                                size: 45,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rel.name,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String labelKey, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(labelKey),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'warning':
        return ThemeConstants.signalRed;
      case 'regulatory':
        return ThemeConstants.signalOrange;
      case 'mandatory':
        return ThemeConstants.signalBlue;
      case 'information':
        return ThemeConstants.signalGreen;
      case 'signal_light':
        return ThemeConstants.signalYellow;
      default:
        return Colors.white;
    }
  }

  void _shareSign(BuildContext context) {
    final text = context.tr('shared_text')
        .replaceAll('{name}', sign.name)
        .replaceAll('{meaning}', sign.meaning);
    Share.share(text);
  }

  // Draw custom painter offline to PNG bytes and save as file
  Future<void> _downloadSign(BuildContext context) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(512, 512);

      // Paint using the vector CustomPainter
      final painter = TrafficSignPainter(signId: sign.id);
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final img = await picture.toImage(512, 512);
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes == null) throw Exception("Failed to serialize PNG bytes.");
      final u8Bytes = pngBytes.buffer.asUint8List();

      // Get appropriate directories based on platform (Windows support included)
      Directory? dir;
      if (kIsWeb) {
        throw Exception("Web platform not supported directly.");
      } else if (Platform.isWindows) {
        dir = await getDownloadsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) dir = await getTemporaryDirectory();

      final filePath = "${dir.path}/${sign.id}_sign.png";
      final file = File(filePath);
      await file.writeAsBytes(u8Bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ThemeConstants.signalGreen,
            content: Text("${context.tr('download_success')}\nPath: $filePath"),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ThemeConstants.signalRed,
            content: Text("${context.tr('download_fail')}: ${e.toString()}"),
          ),
        );
      }
    }
  }
}
