import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_widgets.dart';

class VideoLibraryScreen extends StatelessWidget {
  const VideoLibraryScreen({super.key});

  Future<void> _launchYouTube(String youtubeId) async {
    final url = Uri.parse('https://youtube.com/watch?v=$youtubeId');
    
    // Pehle try karega YouTube App mein open karne ka (without browser)
    try {
      final bool launchedInApp = await launchUrl(
        url,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      
      // Agar YouTube app installed nahi hai to fallback default external mode pe karega
      if (!launchedInApp) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    
    // Group videos by subject, then topic
    final Map<String, Map<String, List<dynamic>>> groupedVideos = {};
    for (var video in academic.videos) {
      final subject = video['subject'] ?? 'Other';
      final topic = video['topic']?.toString().trim().isNotEmpty == true ? video['topic'] : 'General';
      if (!groupedVideos.containsKey(subject)) {
        groupedVideos[subject] = {};
      }
      if (!groupedVideos[subject]!.containsKey(topic)) {
        groupedVideos[subject]![topic] = [];
      }
      groupedVideos[subject]![topic]!.add(video);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  Column(
                    children: [
                      AnimatedBrandHeader(wingMode: auth.activeWingMode),
                      const SizedBox(height: 4),
                      Text(
                        'Video Library',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textBase,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () => context.read<AcademicProvider>().refreshWithLastParams(),
                child: academic.isLoading && academic.videos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : academic.videos.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.videoOff, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text('No videos found for your class.', style: TextStyle(color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          )
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedVideos.keys.length,
                      itemBuilder: (context, index) {
                        final subject = groupedVideos.keys.elementAt(index);
                        final topicsMap = groupedVideos[subject]!;
                        
                        return Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: index == 0,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              subject,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textBase,
                              ),
                            ),
                            children: topicsMap.keys.map((topic) {
                              final videos = topicsMap[topic]!;
                              return ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(
                                  topic,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                children: [
                                  SizedBox(
                                    height: 250, // Increased height
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: videos.length,
                                      itemBuilder: (context, vIndex) {
                                        final video = videos[vIndex];
                                        return GestureDetector(
                                          onTap: () => _launchYouTube(video['youtubeId']),
                                          child: Container(
                                            width: 280,
                                            margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppTheme.border),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            child: AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (video['thumbnailUrl'] != null)
                                                    Image.network(video['thumbnailUrl'], fit: BoxFit.cover)
                                                  else
                                                    Container(color: AppTheme.border),
                                                  Container(
                                                    color: Colors.black.withOpacity(0.3),
                                                    child: const Center(
                                                      child: Icon(LucideIcons.playCircle, size: 48, color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    video['title'] ?? 'No Title',
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textBase,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (video['topic'] != null && video['topic'].toString().isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Text(
                                                        video['topic'],
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: AppTheme.textMuted,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
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
                                },
                              ),
                            ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                },
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
