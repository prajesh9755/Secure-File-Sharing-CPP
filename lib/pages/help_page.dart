import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        title: Row(
          children: [
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
              'Help & Support', 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Section
            _buildHelpSection(
              'Upload Files',
              Icons.upload_file,
              [
                'Tap "Upload" in Quick Services',
                'Choose "Upload IMG or PDF" to upload existing files',
                'Choose "IMG to PDF" to convert images to PDF',
                'Files are encrypted and stored securely',
              ],
              const Color(0xFF4CA1AF),
            ),
            
            const SizedBox(height: 20),
            
            // Camera Scan Section
            _buildHelpSection(
              'Camera Scan',
              Icons.camera_alt,
              [
                'Tap "Scan Photo" in Quick Actions',
                'Use camera to scan documents',
                'Multiple pages supported',
                'Auto-creates encrypted PDF',
              ],
              const Color(0xFF2C3E50),
            ),
            
            const SizedBox(height: 20),
            
            // Forms Section
            _buildHelpSection(
              'Apply Forms',
              Icons.assignment,
              [
                'Tap "Apply Form" in Quick Actions',
                'Fill out required information',
                'Submit for processing',
                'Track status in "Submitted" section',
              ],
              Colors.blue,
            ),
            
            const SizedBox(height: 20),
            
            // Files Section
            _buildHelpSection(
              'Manage Files',
              Icons.folder,
              [
                'Access "Files" from bottom navigation',
                'View uploaded documents',
                'Download or share files',
                'All files are encrypted',
              ],
              Colors.green,
            ),
            
            const SizedBox(height: 20),
            
            // Contact Section
            _buildHelpSection(
              'Contact Support',
              Icons.contact_support,
              [
                'Email: spdyvault@gmail.com',
                'Phone: 9309299519',
                'We\'re here to help you',
                'Quick response guaranteed',
              ],
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(String title, IconData icon, List<String> steps, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2A3A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A2A3A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
