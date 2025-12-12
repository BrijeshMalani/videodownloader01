import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ad_manager.dart';
import '../utils/common.dart';
import '../widgets/WorkingNativeAdWidget.dart';
import 'video_downloader_screen.dart';
import 'video_list_screen.dart';
import 'mp3_list_screen.dart';
import 'mp3_converter_screen.dart';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const VideoListScreen(),
    const MP3ListScreen(),
  ];

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildExitDialog(),
    );
    return shouldExit ?? false;
  }

  Widget _buildExitDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade900, Colors.grey.shade800],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.deepPurple, width: 3),
              ),
              child: const Icon(
                Icons.exit_to_app,
                size: 50,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Exit App?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Are you sure you want to exit?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 30),

            // Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade600, width: 2),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Exit Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        SystemNavigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldExit = await _onWillPop();
          if (shouldExit && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawer: _buildDrawer(),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.grey.shade900,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey.shade600,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library),
              label: 'Videos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: 'Music',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade900, Colors.purple.shade800],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.play_circle_filled,
                      size: 40,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Video Downloader',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.download,
              title: 'Download Videos',
              onTap: () {
                if (Common.adsopen == "2") {
                  Common.openUrl();
                }
                AdManager().showInterstitialAd();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VideoDownloaderScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.video_library,
              title: 'My Videos',
              onTap: () {
                if (Common.adsopen == "2") {
                  Common.openUrl();
                }
                AdManager().showInterstitialAd();
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            _buildDrawerItem(
              icon: Icons.music_note,
              title: 'My Music',
              onTap: () {
                if (Common.adsopen == "2") {
                  Common.openUrl();
                }
                AdManager().showInterstitialAd();
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
            _buildDrawerItem(
              icon: Icons.transform,
              title: 'Convert to MP3',
              onTap: () {
                if (Common.adsopen == "2") {
                  Common.openUrl();
                }
                AdManager().showInterstitialAd();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MP3ConverterScreen()),
                );
              },
            ),
            const Divider(color: Colors.white24),
            _buildDrawerItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewScreen(
                      title: 'Privacy Policy',
                      url:
                          'https://www.privacypolicygenerator.info/live.php?token=YOUR_PRIVACY_TOKEN',
                    ),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.description,
              title: 'Terms of Service',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewScreen(
                      title: 'Terms of Service',
                      url:
                          'https://www.termsofservicegenerator.info/live.php?token=YOUR_TERMS_TOKEN',
                    ),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.star,
              title: 'Rate Us',
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.share,
              title: 'Share App',
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  'Check out this amazing Video Downloader app! Download videos from Instagram, Facebook, Twitter, and TikTok. https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME',
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.info,
              title: 'About',
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Video Downloader',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.play_circle_filled,
                    size: 50,
                    color: Colors.deepPurple,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Download Videos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildPlatformCard(
                    context,
                    'Instagram',
                    Icons.camera_alt,
                    Colors.purple,
                    () {
                      if (Common.adsopen == "2") {
                        Common.openUrl();
                      }
                      AdManager().showInterstitialAd();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VideoDownloaderScreen(
                            platform: 'instagram',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildPlatformCard(
                    context,
                    'Facebook',
                    Icons.facebook,
                    Colors.blue,
                    () {
                      if (Common.adsopen == "2") {
                        Common.openUrl();
                      }
                      AdManager().showInterstitialAd();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const VideoDownloaderScreen(platform: 'facebook'),
                        ),
                      );
                    },
                  ),
                  _buildPlatformCard(
                    context,
                    'Twitter/X',
                    Icons.alternate_email,
                    Colors.blueAccent,
                    () {
                      if (Common.adsopen == "2") {
                        Common.openUrl();
                      }
                      AdManager().showInterstitialAd();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const VideoDownloaderScreen(platform: 'twitter'),
                        ),
                      );
                    },
                  ),
                  _buildPlatformCard(
                    context,
                    'TikTok',
                    Icons.music_note,
                    Colors.white,
                    () {
                      if (Common.adsopen == "2") {
                        Common.openUrl();
                      }
                      AdManager().showInterstitialAd();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const VideoDownloaderScreen(platform: 'tiktok'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              _buildToolCard(
                context,
                'Convert to MP3',
                'Convert any video to MP3 format',
                Icons.transform,
                Colors.orange,
                () {
                  if (Common.adsopen == "2") {
                    Common.openUrl();
                  }
                  AdManager().showInterstitialAd();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MP3ConverterScreen(),
                    ),
                  );
                },
              ),
              // Video Trimmer feature temporarily disabled
              // const SizedBox(height: 15),
              // _buildToolCard(
              //   context,
              //   'Video Trimmer',
              //   'Video cut as your wish',
              //   Icons.cut,
              //   Colors.orange,
              //   () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => const VideoCutter()),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const WorkingNativeAdWidget(),
    );
  }

  Widget _buildPlatformCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade800, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 25, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
