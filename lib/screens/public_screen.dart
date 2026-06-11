import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../site_data.dart';

class PublicScreen extends StatelessWidget {
  const PublicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/lm-logo.webp',
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      SiteData.instituteName,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      SiteData.tagline,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      SiteData.tagline2,
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text('Login to Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Don't have an account? Visit our office for enrollment.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // App Functionality Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What you can do with this App",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textBase),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(Icons.schedule, "View class schedules and notices instantly"),
                    _buildFeatureItem(Icons.menu_book, "Access study materials and DPPs digitally"),
                    _buildFeatureItem(Icons.assessment, "Track attendance and academic performance"),
                    _buildFeatureItem(Icons.notifications_active, "Get real-time updates and announcements"),
                  ],
                ),
              ),
              
              const Divider(thickness: 1, height: 1),

              // Founder Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(SiteData.founder['image']!),
                      backgroundColor: Colors.grey[200],
                      onBackgroundImageError: (exception, stackTrace) {},
                    ),
                    const SizedBox(height: 16),
                    Text(
                      SiteData.founder['name']!,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${SiteData.founder['designation']} | ${SiteData.founder['qualification']}",
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text(
                        '"${SiteData.founder['message']}"',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(thickness: 1, height: 1),

              // Programs Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Our Programs",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textBase),
                    ),
                    const SizedBox(height: 16),
                    ...SiteData.programs.map((prog) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prog['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            const SizedBox(height: 8),
                            Text(prog['description']!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(prog['classes']!, style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                    // Contact CTAs
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Have questions about our programs?",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    final uri = Uri.parse("https://wa.me/91${SiteData.whatsappPhone}");
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                                  label: const Text("WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    final uri = Uri.parse("tel:+91${SiteData.phone}");
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  },
                                  icon: const Icon(Icons.call, size: 20),
                                  label: const Text("Call Us", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),


              
              const Divider(thickness: 1, height: 1),

              // Social Links
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      "Connect With Us",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Dakbangla Road, Opp. Omar Girls High School,\nChanakya Nagar, Begusarai, Bihar – 851101",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(Icons.language, "Website", Colors.blueGrey.shade700, SiteData.socialMedia['website']!),
                        const SizedBox(width: 16),
                        _buildSocialIcon(Icons.video_library, "YouTube", Colors.red, SiteData.socialMedia['youtube']!),
                        const SizedBox(width: 16),
                        _buildSocialIcon(Icons.facebook, "Facebook", Colors.blue.shade700, SiteData.socialMedia['facebook']!),
                        const SizedBox(width: 16),
                        _buildSocialIcon(Icons.camera_alt, "Instagram", Colors.pink, SiteData.socialMedia['instagram']!),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String tooltip, Color color, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87))),
        ],
      ),
    );
  }
}
