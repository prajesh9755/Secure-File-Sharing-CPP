import 'dart:convert';

import 'package:cpp/utils/encryption_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedGender;
  String? selectedStay;
  String? selectedaddmission;

  // Controllers
  final nameCtrl = TextEditingController();
  final casteCtrl = TextEditingController();
  final disabilityCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final QualificationCtrl = TextEditingController();
  final fatherCtrl = TextEditingController();
  final fatheroccupationCtrl = TextEditingController();
  final motherCtrl = TextEditingController();
  final motheroccupationCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final address2Ctrl = TextEditingController();
  final phone1Ctrl = TextEditingController();
  final phone2Ctrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final aadharCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();
  final accNoCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  // _loadExistingData() async {
  //   final uid = FirebaseAuth.instance.currentUser!.uid;
  //   var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  //   if (doc.exists) {
  //     Map data = doc.data() as Map;
  //     setState(() {
  //       nameCtrl.text = data['student_name'] ?? "";
  //       selectedGender = data['gender'];
  //       dobCtrl.text = data['dob'] ?? "";
  //       QualificationCtrl.text = data['Qualification'] ?? "";
  //       selectedaddmission = data['admission_type'];
  //       selectedStay = data['stay'];
  //       casteCtrl.text = data['caste'] ?? "";
  //       disabilityCtrl.text = data['disability'] ?? "";
  //       fatherCtrl.text = data['father_name'] ?? "";
  //       fatheroccupationCtrl.text = data['father_occupation'] ?? "";
  //       motherCtrl.text = data['mother_name'] ?? "";
  //       motheroccupationCtrl.text = data['mother_occupation'] ?? "";
  //       addressCtrl.text = data['address'] ?? "";
  //       address2Ctrl.text = data['address2'] ?? "";
  //       phone1Ctrl.text = data['parent_phone'] ?? "";
  //       phone2Ctrl.text = data['self_phone'] ?? "";
  //       emailCtrl.text = data['myemail'] ?? "";
  //       aadharCtrl.text = data['aadhar'] ?? "";
  //       yearCtrl.text = data['current_year'] ?? "";
  //       bankNameCtrl.text = data['bank_details']?['bank_name'] ?? "";
  //       accNoCtrl.text = data['bank_details']?['acc_no'] ?? "";
  //       ifscCtrl.text = data['bank_details']?['ifsc'] ?? "";
  //     });
  //   }
  // }
  _loadExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch the master key from the student's vault
      final keyDoc = await FirebaseFirestore.instance
          .collection('file_keys')
          .doc(user.email)
          .collection('keys')
          .doc('profile_data')
          .get();

      if (!keyDoc.exists) return; // No encrypted profile found
      String masterKey = keyDoc.data()!['key'];

      // 2. Fetch the encrypted payload from the users collection
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (doc.exists && doc.data()!.containsKey('secure_payload')) {
        String encryptedPayload = doc.data()!['secure_payload'];

        // 3. Decrypt the block back into a JSON string
        String decryptedJson = EncryptionService.decryptString(encryptedPayload, masterKey);

        // 4. Decode the JSON back into a Map
        Map<String, dynamic> data = jsonDecode(decryptedJson);

        setState(() {
          nameCtrl.text = data['student_name'] ?? "";
          selectedGender = data['gender'];
          dobCtrl.text = data['dob'] ?? "";
          QualificationCtrl.text = data['Qualification'] ?? "";
          selectedaddmission = data['admission_type'];
          selectedStay = data['stay'];
          casteCtrl.text = data['caste'] ?? "";
          disabilityCtrl.text = data['disability'] ?? "";
          fatherCtrl.text = data['father_name'] ?? "";
          fatheroccupationCtrl.text = data['father_occupation'] ?? "";
          motherCtrl.text = data['mother_name'] ?? "";
          motheroccupationCtrl.text = data['mother_occupation'] ?? "";
          addressCtrl.text = data['address'] ?? "";
          address2Ctrl.text = data['address2'] ?? "";
          phone1Ctrl.text = data['parent_phone'] ?? "";
          phone2Ctrl.text = data['self_phone'] ?? "";
          emailCtrl.text = data['myemail'] ?? "";
          aadharCtrl.text = data['aadhar'] ?? "";
          yearCtrl.text = data['current_year'] ?? "";
          bankNameCtrl.text = data['bank_details']?['bank_name'] ?? "";
          accNoCtrl.text = data['bank_details']?['acc_no'] ?? "";
          ifscCtrl.text = data['bank_details']?['ifsc'] ?? "";
        });
      }
    } catch (e) {
      debugPrint("Error loading decrypted data: $e");
    }
  }

  Future<void> _saveToFirebase() async {
    List<TextEditingController> controllers = [
      nameCtrl, dobCtrl, QualificationCtrl, casteCtrl,
      disabilityCtrl, fatherCtrl, fatheroccupationCtrl, motherCtrl, motheroccupationCtrl,
      addressCtrl, address2Ctrl, phone1Ctrl, phone2Ctrl, emailCtrl, aadharCtrl, yearCtrl,
      bankNameCtrl, accNoCtrl, ifscCtrl,
    ];

    bool isAnyEmpty = controllers.any((c) => c.text.trim().isEmpty) ||
        selectedGender == null ||
        selectedStay == null ||
        selectedaddmission == null;

    if (isAnyEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 10), Text("Missing Info")]),
          content: const Text("All fields are mandatory. Please fill everything before saving."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
      return;
    }

    try {
      await _saveEncryptedUserDetails(); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Encrypted & Saved Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Encryption Error: $e")));
    }

    // final uid = FirebaseAuth.instance.currentUser!.uid;
    // await FirebaseFirestore.instance.collection('users').doc(uid).set({
    //   'student_name': nameCtrl.text,
    //   'gender': selectedGender,
    //   'dob': dobCtrl.text,
    //   'Qualification': QualificationCtrl.text,
    //   'admission_type': selectedaddmission,
    //   'stay': selectedStay,
    //   'caste': casteCtrl.text,
    //   'disability': disabilityCtrl.text,
    //   'father_name': fatherCtrl.text,
    //   'father_occupation': fatheroccupationCtrl.text,
    //   'mother_name': motherCtrl.text,
    //   'mother_occupation': motheroccupationCtrl.text,
    //   'address': addressCtrl.text,
    //   'address2': address2Ctrl.text,
    //   'parent_phone': phone1Ctrl.text,
    //   'self_phone': phone2Ctrl.text,
    //   'myemail': emailCtrl.text,
    //   'aadhar': aadharCtrl.text,
    //   'current_year': yearCtrl.text,
    //   'bank_details': {
    //     'bank_name': bankNameCtrl.text,
    //     'acc_no': accNoCtrl.text,
    //     'ifsc': ifscCtrl.text,
    //   },
    //   'last_updated': FieldValue.serverTimestamp(),
    // }, SetOptions(merge: true));

    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved Successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A3A),
        elevation: 0,
        title: const Text("User Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          // Navy Header Backdrop
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2A3A),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 35)),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Personal Profile", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Keep your info up to date", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),
          ),

          // Content Area
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // --- SECTION: BASIC INFO ---
                  _buildSectionCard(
                    title: "Basic Information",
                    icon: Icons.info_outline,
                    iconColor: Colors.blue,
                    children: [
                      _buildField(nameCtrl, "Student Name"),
                      _buildField(emailCtrl, "Email Address", keyboard: TextInputType.emailAddress),
                      _buildDropdownField(selectedGender, "Gender", ['Male', 'Female', 'Other'], (val) => setState(() => selectedGender = val)),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(child: _buildField(dobCtrl, "Date of Birth", readOnly: true)),
                      ),
                      _buildField(QualificationCtrl, "Qualification (10th / 12th)"),
                      _buildDropdownField(selectedaddmission, "Admission Type", ['First Year', 'Direct Second Year - DSY'], (val) => setState(() => selectedaddmission = val)),
                    ],
                  ),

                  // --- SECTION: CATEGORY ---
                  _buildSectionCard(
                    title: "Identity & Caste",
                    icon: Icons.fingerprint,
                    iconColor: Colors.orange,
                    children: [
                      _buildField(casteCtrl, "Caste"),
                      _buildField(disabilityCtrl, "Disability (or 'No')"),
                      _buildField(aadharCtrl, "Aadhar Number", keyboard: TextInputType.number),
                      _buildField(yearCtrl, "Current Studying Year"),
                    ],
                  ),

                  // --- SECTION: FAMILY ---
                  _buildSectionCard(
                    title: "Parental Details",
                    icon: Icons.family_restroom,
                    iconColor: Colors.green,
                    children: [
                      _buildField(fatherCtrl, "Father Name"),
                      _buildField(fatheroccupationCtrl, "Father Occupation"),
                      _buildField(motherCtrl, "Mother Name"),
                      _buildField(motheroccupationCtrl, "Mother Occupation"),
                      _buildField(phone1Ctrl, "Parent Phone", keyboard: TextInputType.phone),
                      _buildField(phone2Ctrl, "Self Phone", keyboard: TextInputType.phone),
                    ],
                  ),

                  // --- SECTION: ADDRESS ---
                  _buildSectionCard(
                    title: "Address & Stay",
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.red,
                    children: [
                      _buildField(addressCtrl, "Full Address", maxLines: 2),
                      _buildField(address2Ctrl, "Taluka, District, State"),
                      _buildDropdownField(selectedStay, "Stay Type", ['Home', 'Hostel'], (val) => setState(() => selectedStay = val)),
                    ],
                  ),

                  // --- SECTION: BANK ---
                  _buildSectionCard(
                    title: "Bank Details",
                    icon: Icons.account_balance_outlined,
                    iconColor: Colors.purple,
                    children: [
                      _buildField(bankNameCtrl, "Bank Name"),
                      _buildField(accNoCtrl, "Account Number"),
                      _buildField(ifscCtrl, "IFSC Code"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(colors: [Color(0xFF1A2A3A), Color(0xFF4CA1AF)]),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveToFirebase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("SAVE PROFILE INFO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

    Future<void> _saveEncryptedUserDetails() async {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userEmail = FirebaseAuth.instance.currentUser!.email;

      Map<String, dynamic> userData = {
        'student_name': nameCtrl.text,
        'gender': selectedGender,
        'dob': dobCtrl.text,
        'Qualification': QualificationCtrl.text,
        'admission_type': selectedaddmission,
        'stay': selectedStay,
        'caste': casteCtrl.text,
        'disability': disabilityCtrl.text,
        'father_name': fatherCtrl.text,
        'father_occupation': fatheroccupationCtrl.text,
        'mother_name': motherCtrl.text,
        'mother_occupation': motheroccupationCtrl.text,
        'address': addressCtrl.text,
        'address2': address2Ctrl.text,
        'parent_phone': phone1Ctrl.text,
        'self_phone': phone2Ctrl.text,
        'myemail': emailCtrl.text,
        'aadhar': aadharCtrl.text,
        'current_year': yearCtrl.text,
        'bank_details': {
          'bank_name': bankNameCtrl.text,
          'acc_no': accNoCtrl.text,
          'ifsc': ifscCtrl.text,
        },
      };

      try {
        String jsonString = jsonEncode(userData);
        String profileKey = EncryptionService.generateRandomKey(); 
        String encryptedData = EncryptionService.encryptString(jsonString, profileKey);

        // 5. Store in 'users' with unencrypted identification fields
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'secure_payload': encryptedData,
          'student_name': nameCtrl.text, // For searching/displaying in lists
          'search_email': userEmail,    // For identification
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 6. Store key in vault
        await FirebaseFirestore.instance
            .collection('file_keys')
            .doc(userEmail)
            .collection('keys')
            .doc('profile_data')
            .set({
          'key': profileKey,
          'ownerEmail': userEmail,
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Encrypted & Saved!")));
      } catch (e) {
        debugPrint("Encryption Error: $e");
      }
    }

  // UI HELPER: Section Card
  Widget _buildSectionCard({required String title, required IconData icon, required Color iconColor, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A2A3A))),
            ],
          ),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }

  // UI HELPER: Modern Text Field
  Widget _buildField(TextEditingController ctrl, String label, {TextInputType? keyboard, int maxLines = 1, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 1)),
        ),
        keyboardType: keyboard,
        maxLines: maxLines,
      ),
    );
  }

  // UI HELPER: Modern Dropdown
  Widget _buildDropdownField(String? value, String label, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: options.map((String val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobCtrl.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}