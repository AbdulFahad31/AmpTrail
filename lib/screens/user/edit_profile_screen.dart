import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:amptrail_mini/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocalImage();
    // Add listener to update avatar in real-time
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadLocalImage() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${user.uid}');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? 'User';
      
      // Also try to get from Firestore for "perfect" sync
      final profile = await _userService.getUserProfile();
      if (profile != null && profile['name'] != null && mounted) {
        setState(() {
          _nameController.text = profile['name'];
        });
      }
    } else {
      _nameController.text = 'User';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final user = _auth.currentUser;
        if (user == null) return;

        // Save image PERMANENTLY in app documentation directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = "profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}";
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');

        setState(() {
          _profileImage = savedImage;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${user.uid}', savedImage.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final user = _auth.currentUser;
        if (user == null) return;

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = "profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}";
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');

        setState(() {
          _profileImage = savedImage;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_${user.uid}', savedImage.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Profile Picture',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text('Take Photo', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final newName = _nameController.text.trim();
        
        // 1. Update Firebase Auth display name (Essential)
        await user.updateDisplayName(newName).timeout(const Duration(seconds: 5));
        
        // 2. Sync to Firestore (Persistence) - with timeout to prevent hanging
        try {
          await _userService.saveUserProfile(newName).timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint("Firestore sync timed out or failed: $e");
          // We continue anyway since Auth was updated and image is saved locally
        }
        
        await user.reload();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text('Profile saved perfectly!', style: GoogleFonts.outfit()),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      }
 else {
        // Fallback for non-logged in state (shouldn't happen usually)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e', style: GoogleFonts.outfit()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return 'U';
    // Use characters for emoji safety
    return text.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Picture
            FadeInDown(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Stack(
                  children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).cardColor,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? Text(
                                _getInitials(),
                                style: GoogleFonts.outfit(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, color: AppColors.background, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Tap to change photo',
              style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 14),
            ),

            const SizedBox(height: 40),

            // Name Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Name',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: GoogleFonts.outfit(color: Theme.of(context).hintColor),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Save Button
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.background,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
