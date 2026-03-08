import 'package:cpp/camera/camera.dart';
import 'package:cpp/firebase/file_viewer_screen.dart';
import 'package:cpp/pages/form_history.dart';
import 'package:cpp/pages/gallery_to_pdf_screen.dart';
import 'package:cpp/pages/help_page.dart';
import 'package:cpp/pages/profilepage.dart';
import 'package:cpp/pages/upload_page.dart';
import 'package:cpp/pages/user_details.dart';
import 'package:flutter/material.dart';
import 'applyform.dart';
// import 'cyberside.dart';
// import 'profilepage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;

void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
}

// --- UPLOAD OPTIONS DIALOG ---
void _showUploadDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Choose Upload Option',
        style: TextStyle(
          color: Color(0xFF1A2A3A),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select how you want to upload your files:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          
          // Option 1: Upload IMG or PDF
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadPage()),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload IMG or PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CA1AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Option 2: IMG to PDF
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GalleryToPdfScreen()),
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('IMG to PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF1A2A3A)),
          ),
        ),
      ],
    ),
  );
}

  @override
Widget build(BuildContext context) {
  // List of the different screens
  final List<Widget> _pages = [
    _buildHomeBody(context), // Your current homepage content
    const FileViewerScreen(folderName: 'user_data'),   // Index 1 (Your logic/class here)
    const ProfilePage(), // Placeholder for Profile
  ];

  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FA), // Your homepage background
    
    // This part ensures the pages actually switch
    body: _pages[_selectedIndex], 

    // Use the widget I gave you earlier
    bottomNavigationBar: _buildBottomNavBar(), 
  );
}

  Widget _buildHomeBody(BuildContext context) {
  return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        title: Row(
          children: [
            // --- LOGO WITH WHITE BORDER ---
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/spdy.png', 
                  height: 28, 
                  width: 28, 
                  fit: BoxFit.cover
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Home', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. THE CURVED NAVY DECORATION
          Container(
            height: 180, 
            decoration: const BoxDecoration(
              color: Color(0xFF1A2A3A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 2. SCROLLABLE CONTENT
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BRAND MISSION BANNER (Share Button Removed) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '100% SECURE & ENCRYPTED',
                              style: TextStyle(
                                color: Colors.greenAccent.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Fill Forms & Share Files\nWith Full Privacy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Our mission is to provide a safe platform\nto manage all your document needs securely.',
                          style: TextStyle(
                            color: Colors.white70, 
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- MAIN ACTIONS ---
                  const Text(
                    'Quick Actions', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildActionBtn(context, Icons.assignment, 'Apply Form', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplyFormPage()))),
                      const SizedBox(width: 12),
                      _buildActionBtn(context, Icons.add_a_photo, 'Scan Photo', () => CustomScanner.startScan(context)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- QUICK SERVICES GRID ---
                  const Text(
                    'Quick Services', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 8,
                    children: [
                      _serviceButton(context, Icons.upload_file, 'Upload', () {
                        _showUploadDialog(context);
                      }),
                      _serviceButton(context, Icons.fact_check, 'Submitted', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FileViewerScreen(folderName: 'applications')));
                      }),
                      _serviceButton(context, Icons.person, 'Details', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      }),
                      _serviceButton(context, Icons.folder, 'Files', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const FileViewerScreen(folderName: 'user_data')));
                      }),
                      _serviceButton(context, Icons.payment, 'Payment', () {}),
                      _serviceButton(context, Icons.description, 'Required Docs', () {}),
                      _serviceButton(context, Icons.calendar_month, 'Deadlines', () {}),
                      _serviceButton(context, Icons.help_center, 'Help', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpPage()));
                      }),
                      _serviceButton(context, Icons.history, 'History', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
                      }),
                    ],
                  ),

                  const SizedBox(height: 30),

                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
}

  Widget _buildBottomNavBar() {
  return Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: _selectedIndex, // Logic to be handled by you
      onTap: _onItemTapped,         // Logic to be handled by you
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1A2A3A),
      unselectedItemColor: Colors.grey[400],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.home_outlined),
          ),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.folder_open_outlined),
          ),
          activeIcon: Icon(Icons.folder_rounded),
          label: 'Files',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.person_outline_rounded),
          ),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    ),
  );
}

  // Helper: Service Grid Buttons
  Widget _serviceButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, color: const Color(0xFF1A2A3A), size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A2A3A)), 
            textAlign: TextAlign.center
          ),
        ],
      ),
    );
  }

// Helper: Top Horizontal Buttons (Modified to handle functions)
Widget _buildActionBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap, // Trigger the passed function
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), 
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1A2A3A), size: 20),
            const SizedBox(width: 8),
            Text(
              label, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}
}
// Helper: History List Tile
class _historyTile extends StatelessWidget {
  final String title; final String subtitle; final String count;
  const _historyTile({required this.title, required this.subtitle, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9), 
          child: Icon(Icons.history, color: Colors.green, size: 20)
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Text(count, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}