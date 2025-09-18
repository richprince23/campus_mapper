import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';
import 'package:campus_mapper/core/widgets/university_dropdown.dart';
import 'package:campus_mapper/core/models/university.dart';
import 'package:campus_mapper/core/services/university_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;
  University? _selectedUniversity;
  final UniversityService _universityService = UniversityService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _displayNameController.text = authProvider.userDisplayName;
    // Phone and bio would need to be loaded from user profile if available
    _phoneController.text = authProvider.userPhoneNumber ?? '';
    _bioController.text = authProvider.userBio ?? '';
    
    // Load user university
    try {
      final userProfile = await authProvider.getUserProfile();
      if (userProfile != null && userProfile['university_id'] != null) {
        final university = await _universityService.getUniversityById(userProfile['university_id']);
        if (mounted && university != null) {
          setState(() {
            _selectedUniversity = university;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (authProvider.userPhotoURL != null
                                  ? NetworkImage(authProvider.userPhotoURL!)
                                  : null) as ImageProvider?,
                          child: _selectedImage == null &&
                                  authProvider.userPhotoURL == null
                              ? Text(
                                  authProvider.userDisplayName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: Icon(
                            HugeIcons.strokeRoundedCamera01,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Display Name Field
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your display name',
                  prefixIcon: const Icon(HugeIcons.strokeRoundedUser),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Display name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: (_) => _setHasChanges(true),
                maxLength: 50,
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  hintText: 'Enter your phone number',
                  prefixIcon: const Icon(HugeIcons.strokeRoundedCall),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    // Basic phone validation
                    if (value.trim().length < 10) {
                      return 'Enter a valid phone number';
                    }
                  }
                  return null;
                },
                onChanged: (_) => _setHasChanges(true),
                maxLength: 15,
              ),
              const SizedBox(height: 16),

              // Bio Field
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
                  hintText: 'Tell us about yourself',
                  prefixIcon: const Icon(HugeIcons.strokeRoundedNote),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                maxLength: 150,
                onChanged: (_) => _setHasChanges(true),
              ),
              const SizedBox(height: 16),

              // University Selection
              UniversityDropdown(
                selectedUniversity: _selectedUniversity,
                onChanged: (university) {
                  setState(() {
                    _selectedUniversity = university;
                    _hasChanges = true;
                  });
                },
                label: 'University',
                hint: 'Select your university',
              ),
              const SizedBox(height: 32),

              // Account Information (Read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Column(
                          children: [
                            _buildInfoRow(
                              context,
                              'Email',
                              authProvider.userEmail,
                              HugeIcons.strokeRoundedMail01,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              context,
                              'Account Created',
                              'Recently', // You could get actual creation date from user profile
                              HugeIcons.strokeRoundedCalendar01,
                            ),
                          ],
                        );
                      },
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

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _setHasChanges(bool hasChanges) {
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedCamera01),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedImage01),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null ||
                  Provider.of<AuthProvider>(context, listen: false)
                          .userPhotoURL !=
                      null)
                ListTile(
                  leading: const Icon(HugeIcons.strokeRoundedDelete01),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        final file = File(image.path);
        
        // Validate file exists and has reasonable size
        if (!await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected image file not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final fileSize = await file.length();
        debugPrint('Selected image size: $fileSize bytes');
        
        // Check file size (limit to 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image too large. Please select an image smaller than 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = file;
          _hasChanges = true;
        });
        
        debugPrint('Image selected successfully: ${image.path}');
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String? photoURL;

      // Handle image upload if there's a selected image
      if (_selectedImage != null) {
        // Show upload progress
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Uploading image...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }
        
        photoURL = await _uploadImageToFirebase(_selectedImage!);
        
        // Hide progress snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        
        if (photoURL == null && mounted) {
          // Image upload failed, show error and don't proceed
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else if (authProvider.userPhotoURL != null) {
        photoURL = authProvider.userPhotoURL;
      }

      final success = await authProvider.updateProfile(
        displayName: _displayNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        photoURL: photoURL,
        universityId: _selectedUniversity?.id,
      );

      if (success && mounted) {
        setState(() {
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true); // Return true to indicate success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error updating profile: ${authProvider.errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToFirebase(File file) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;
      
      if (userId == null) {
        debugPrint('Error: No user ID available for upload');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please sign in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      debugPrint('Starting image upload for user: $userId');
      debugPrint('File path: ${file.path}');
      debugPrint('File exists: ${await file.exists()}');
      debugPrint('File size: ${await file.length()} bytes');

      // Create a unique filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.jpg';
      final storagePath = 'user_photos/$userId/$fileName';
      
      debugPrint('Upload path: $storagePath');
      
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      
      // Upload with metadata
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': timestamp.toString(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      debugPrint('Waiting for upload to complete...');
      final snapshot = await uploadTask;
      debugPrint('Upload completed. Getting download URL...');
      
      final downloadURL = await snapshot.ref.getDownloadURL();
      debugPrint('Download URL obtained: $downloadURL');
      
      return downloadURL;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error uploading image: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.message ?? 'Unknown Firebase error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } catch (e) {
      debugPrint('General error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
