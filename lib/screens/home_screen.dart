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
            colors: [Colors.white, Colors.orange.shade50],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
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
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange, width: 3),
              ),
              child: const Icon(
                Icons.exit_to_app,
                size: 50,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Exit App?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Are you sure you want to exit?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
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
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.white,
          selectedItemColor: Colors.orange,
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
            colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
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
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Video Saver',
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
              title: 'Save Videos',
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
                    builder: (_) => WebViewScreen(
                      title: 'Privacy Policy',
                      url: Common.privacy_policy == ""
                          ? 'https://www.privacypolicygenerator.info/live.php?token=YOUR_PRIVACY_TOKEN'
                          : Common.privacy_policy,
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
                    builder: (_) => WebViewScreen(
                      title: 'Terms of Service',
                      url: Common.terms_conditions == ""
                          ? 'https://www.termsofservicegenerator.info/live.php?token=YOUR_TERMS_TOKEN'
                          : Common.terms_conditions,
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
                  'https://play.google.com/store/apps/details?id=' +
                      Common.packageName,
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
                  'Check out this amazing Video Saver app! Save videos from Instagram, Facebook, Twitter, and TikTok. https://play.google.com/store/apps/details?id=' +
                      Common.packageName,
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
                  applicationName: 'Video Saver',
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
        decoration: BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Save Videos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              // URL Input Field
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paste Insta, FB, Tik, Twit URL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Enter Video URL',
                          labelStyle: const TextStyle(color: Colors.black),
                          hintText: 'Paste video URL here',
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          prefixIcon: const Icon(
                            Icons.link,
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onTap: () {
                          // Open download screen on tap
                          if (Common.adsopen == "2") {
                            Common.openUrl();
                          }
                          AdManager().showInterstitialAd();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VideoDownloaderScreen(),
                            ),
                          );
                        },
                        readOnly: true,
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Open download screen
                            if (Common.adsopen == "2") {
                              Common.openUrl();
                            }
                            AdManager().showInterstitialAd();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VideoDownloaderScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download, size: 20),
                          label: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Tools',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
