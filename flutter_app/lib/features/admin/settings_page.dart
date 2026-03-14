import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/language_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/image_crop_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registrationController = TextEditingController();
  final _presidentController = TextEditingController();
  final _vicePresidentController = TextEditingController();
  final _secretaryController = TextEditingController();
  final _treasurerController = TextEditingController();
  final _footerTextController = TextEditingController();
  final _headerTextController = TextEditingController();
  
  String? _logoUrl;
  String? _upiQrUrl;
  File? _selectedLogo;
  File? _selectedQr;

  // Footer portrait images
  String? _footerLeftImageUrl;
  String? _footerRightImageUrl;
  File? _selectedFooterLeft;
  File? _selectedFooterRight;
  final _footerLeftNameController        = TextEditingController();
  final _footerRightNameController       = TextEditingController();
  final _footerLeftDesignationController  = TextEditingController();
  final _footerRightDesignationController = TextEditingController();
  bool _footerLeftEnabled  = true;
  bool _footerRightEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _registrationController.dispose();
    _presidentController.dispose();
    _vicePresidentController.dispose();
    _secretaryController.dispose();
    _treasurerController.dispose();
    _footerTextController.dispose();
    _headerTextController.dispose();
    _footerLeftNameController.dispose();
    _footerRightNameController.dispose();
    _footerLeftDesignationController.dispose();
    _footerRightDesignationController.dispose();
    super.dispose();
  }

  Future<void> _loadTenantData() async {
    try {
      // Fetch fresh data from API
      final response = await ApiClient.dio.get('/tenant/self');
      final tenant = response.data;
      
      if (tenant != null) {
        setState(() {
          _nameController.text = tenant['name'] ?? '';
          _addressController.text = tenant['address'] ?? '';
          _phoneController.text = tenant['contact_phone'] ?? '';
          _registrationController.text = tenant['registration_no'] ?? '';
          _presidentController.text = tenant['president_name'] ?? '';
          _vicePresidentController.text = tenant['vice_president_name'] ?? '';
          _secretaryController.text = tenant['secretary_name'] ?? '';
          _treasurerController.text = tenant['treasurer_name'] ?? '';
          _footerTextController.text = tenant['footer_text'] ?? '';
          _headerTextController.text = tenant['header_text'] ?? '';
          _logoUrl = tenant['logo_url'];
          _upiQrUrl = tenant['upi_qr_url'];
          _footerLeftImageUrl  = tenant['footer_left_image_url'];
          _footerRightImageUrl = tenant['footer_right_image_url'];
          _footerLeftNameController.text  = tenant['footer_left_image_name']  ?? '';
          _footerRightNameController.text = tenant['footer_right_image_name'] ?? '';
          _footerLeftDesignationController.text  = tenant['footer_left_image_designation']  ?? '';
          _footerRightDesignationController.text = tenant['footer_right_image_designation'] ?? '';
          _footerLeftEnabled  = tenant['footer_left_image_enabled']  != false;
          _footerRightEnabled = tenant['footer_right_image_enabled'] != false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile == null) return;

    if (kIsWeb) {
      // Web: upload immediately (no crop support)
      await _uploadImageWeb(pickedFile, isLogo);
      return;
    }

    // Mobile/Desktop: show crop dialog for logo (square shape).
    // QR codes must NOT be cropped — skip crop for QR.
    if (isLogo) {
      if (!mounted) return;
      final croppedFile = await ImageCropDialog.show(
        context,
        pickedFile.path,
        isCircle: false, // square/rounded-rect crop for logos
      );
      if (croppedFile == null) return; // user cancelled
      setState(() => _selectedLogo = croppedFile);
    } else {
      setState(() => _selectedQr = File(pickedFile.path));
    }
  }

  Future<void> _pickFooterImage(bool isLeft) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile == null) return;

    if (kIsWeb) {
      // Web: no crop support, upload directly
      await _uploadFooterImageWeb(pickedFile, isLeft);
      return;
    }

    // Mobile/Desktop: open in-app crop dialog (square 1:1, circle preview)
    if (!mounted) return;
    final croppedFile = await ImageCropDialog.show(context, pickedFile.path);
    if (croppedFile == null) return; // user cancelled

    setState(() {
      if (isLeft) {
        _selectedFooterLeft = croppedFile;
      } else {
        _selectedFooterRight = croppedFile;
      }
    });
  }

  Future<void> _uploadFooterImageWeb(XFile pickedFile, bool isLeft) async {
    try {
      final bytes    = await pickedFile.readAsBytes();
      final endpoint = isLeft ? '/tenant/upload/footer_left' : '/tenant/upload/footer_right';
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: pickedFile.name),
      });
      final response = await ApiClient.dio.post(endpoint, data: formData);
      if (response.statusCode == 200) {
        final url = response.data['url'];
        setState(() {
          if (isLeft) _footerLeftImageUrl  = url;
          else        _footerRightImageUrl = url;
        });
        await AuthService.refreshTenant();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isLeft ? 'Left portrait uploaded!' : 'Right portrait uploaded!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _uploadFooterImage(File file, bool isLeft) async {
    try {
      final endpoint = isLeft ? '/tenant/upload/footer_left' : '/tenant/upload/footer_right';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await ApiClient.dio.post(endpoint, data: formData);
      if (response.statusCode == 200) {
        final url = response.data['url'];
        setState(() {
          if (isLeft) { _footerLeftImageUrl  = url; _selectedFooterLeft  = null; }
          else         { _footerRightImageUrl = url; _selectedFooterRight = null; }
        });
        await AuthService.refreshTenant();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isLeft ? 'Left portrait updated!' : 'Right portrait updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _removeFooterImage(bool isLeft) async {
    // Confirm before removing
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Image'),
        content: Text(
          isLeft
              ? 'Remove the left portrait (Politician / Guest)?'
              : 'Remove the right portrait (President / Head)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final endpoint =
          isLeft ? '/tenant/upload/footer_left' : '/tenant/upload/footer_right';
      await ApiClient.dio.delete(endpoint);
      await AuthService.refreshTenant();
      setState(() {
        if (isLeft) {
          _footerLeftImageUrl = null;
          _selectedFooterLeft = null;
          _footerLeftNameController.clear();
          _footerLeftDesignationController.clear();
        } else {
          _footerRightImageUrl = null;
          _selectedFooterRight = null;
          _footerRightNameController.clear();
          _footerRightDesignationController.clear();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLeft
                ? 'Left portrait removed.'
                : 'Right portrait removed.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Remove failed: $e')));
      }
    }
  }

  Future<void> _uploadImageWeb(XFile pickedFile, bool isLogo) async {
    try {
      // Read file bytes for web
      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final endpoint = isLogo ? '/tenant/upload/logo' : '/tenant/upload/upi_qr';
      final response = await ApiClient.dio.post(endpoint, data: formData);

      if (response.statusCode == 200) {
        final url = response.data['url'];
        setState(() {
          if (isLogo) {
            _logoUrl = url;
          } else {
            _upiQrUrl = url;
          }
        });

        // Refresh tenant data
        await AuthService.refreshTenant();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isLogo ? 'Logo uploaded!' : 'QR code uploaded!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage(File file, bool isLogo) async {
    try {
      // For mobile/desktop - use file path
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final endpoint = isLogo ? '/tenant/upload/logo' : '/tenant/upload/upi_qr';
      final response = await ApiClient.dio.post(endpoint, data: formData);

      if (response.statusCode == 200) {
        final url = response.data['url'];
        setState(() {
          if (isLogo) {
            _logoUrl = url;
            _selectedLogo = null;
          } else {
            _upiQrUrl = url;
            _selectedQr = null;
          }
        });
        
        // Refresh tenant data
        await AuthService.refreshTenant();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isLogo ? 'Logo updated!' : 'QR code updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _saveTenantSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload images if selected (only for mobile/desktop, web uploads immediately)
      if (!kIsWeb) {
        if (_selectedLogo != null) {
          await _uploadImage(_selectedLogo!, true);
        }
        if (_selectedQr != null) {
          await _uploadImage(_selectedQr!, false);
        }
        if (_selectedFooterLeft != null) {
          await _uploadFooterImage(_selectedFooterLeft!, true);
        }
        if (_selectedFooterRight != null) {
          await _uploadFooterImage(_selectedFooterRight!, false);
        }
      }

      // Update tenant settings
      final data = {
        'name': _nameController.text,
        'address': _addressController.text,
        'contact_phone': _phoneController.text,
        'registration_no': _registrationController.text,
        'president_name': _presidentController.text,
        'vice_president_name': _vicePresidentController.text,
        'secretary_name': _secretaryController.text,
        'treasurer_name': _treasurerController.text,
        'footer_text': _footerTextController.text,
        'header_text': _headerTextController.text,
        'footer_left_image_name':  _footerLeftNameController.text,
        'footer_right_image_name': _footerRightNameController.text,
        'footer_left_image_designation':  _footerLeftDesignationController.text,
        'footer_right_image_designation': _footerRightDesignationController.text,
        'footer_left_image_enabled':  _footerLeftEnabled,
        'footer_right_image_enabled': _footerRightEnabled,
      };

      final response = await ApiClient.dio.put('/tenant/self', data: data);

      if (response.statusCode == 200) {
        await AuthService.refreshTenant();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mandalSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveTenantSettings,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.uploadLogo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _selectedLogo != null
                              ? (kIsWeb 
                                  ? Image.network(_selectedLogo!.path, fit: BoxFit.cover)
                                  : Image.file(_selectedLogo!, fit: BoxFit.cover))
                              : _logoUrl != null
                                  ? Image.network(_logoUrl!, fit: BoxFit.cover)
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Tap to upload logo'),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // UPI QR Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.uploadQR,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _selectedQr != null
                              ? (kIsWeb 
                                  ? Image.network(_selectedQr!.path, fit: BoxFit.cover)
                                  : Image.file(_selectedQr!, fit: BoxFit.cover))
                              : _upiQrUrl != null
                                  ? Image.network(_upiQrUrl!, fit: BoxFit.cover)
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.qr_code, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Tap to upload QR'),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Footer Portrait Images ─────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.people, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Receipt Footer Portraits',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Optional: show two prominent portraits at the bottom of every receipt.\nTap a circle to pick & crop an image.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT portrait
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Left (Politician / Guest)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: GestureDetector(
                                  onTap: () => _pickFooterImage(true),
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _footerLeftEnabled
                                            ? Colors.orange
                                            : Colors.grey.shade400,
                                        width: 3,
                                      ),
                                      color: _footerLeftEnabled
                                          ? Colors.orange.shade50
                                          : Colors.grey.shade100,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_footerLeftEnabled
                                                  ? Colors.orange
                                                  : Colors.grey)
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: ColorFiltered(
                                        colorFilter: _footerLeftEnabled
                                            ? const ColorFilter.mode(
                                                Colors.transparent,
                                                BlendMode.multiply)
                                            : const ColorFilter.matrix([
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0,      0,      0,      1, 0,
                                              ]),
                                        child: _selectedFooterLeft != null
                                            ? Image.file(_selectedFooterLeft!, fit: BoxFit.cover)
                                            : _footerLeftImageUrl != null
                                                ? Image.network(_footerLeftImageUrl!, fit: BoxFit.cover)
                                                : const Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.add_a_photo, size: 34, color: Colors.orange),
                                                      SizedBox(height: 6),
                                                      Text('Tap to select', style: TextStyle(fontSize: 11, color: Colors.orange)),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedFooterLeft != null || _footerLeftImageUrl != null) ...[  
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to change photo',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              // Show in receipt toggle
                              if (_selectedFooterLeft != null || _footerLeftImageUrl != null) ...[  
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Show in receipt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _footerLeftEnabled
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                    ),
                                    Switch(
                                      value: _footerLeftEnabled,
                                      onChanged: (v) =>
                                          setState(() => _footerLeftEnabled = v),
                                      activeColor: Colors.orange,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ] else
                                const SizedBox(height: 10),
                              TextField(
                                controller: _footerLeftNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _footerLeftDesignationController,
                                decoration: const InputDecoration(
                                  labelText: 'Designation',
                                  hintText: 'e.g. Chief Guest, MLA',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // RIGHT portrait
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Right (President / Head)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: GestureDetector(
                                  onTap: () => _pickFooterImage(false),
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _footerRightEnabled
                                            ? Colors.orange
                                            : Colors.grey.shade400,
                                        width: 3,
                                      ),
                                      color: _footerRightEnabled
                                          ? Colors.orange.shade50
                                          : Colors.grey.shade100,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_footerRightEnabled
                                                  ? Colors.orange
                                                  : Colors.grey)
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: ColorFiltered(
                                        colorFilter: _footerRightEnabled
                                            ? const ColorFilter.mode(
                                                Colors.transparent,
                                                BlendMode.multiply)
                                            : const ColorFilter.matrix([
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0.2126, 0.7152, 0.0722, 0, 0,
                                                0,      0,      0,      1, 0,
                                              ]),
                                        child: _selectedFooterRight != null
                                            ? Image.file(_selectedFooterRight!, fit: BoxFit.cover)
                                            : _footerRightImageUrl != null
                                                ? Image.network(_footerRightImageUrl!, fit: BoxFit.cover)
                                                : const Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.add_a_photo, size: 34, color: Colors.orange),
                                                      SizedBox(height: 6),
                                                      Text('Tap to select', style: TextStyle(fontSize: 11, color: Colors.orange)),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedFooterRight != null || _footerRightImageUrl != null) ...[  
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to change photo',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              // Show in receipt toggle
                              if (_selectedFooterRight != null || _footerRightImageUrl != null) ...[  
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Show in receipt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _footerRightEnabled
                                            ? Colors.black87
                                            : Colors.grey,
                                      ),
                                    ),
                                    Switch(
                                      value: _footerRightEnabled,
                                      onChanged: (v) =>
                                          setState(() => _footerRightEnabled = v),
                                      activeColor: Colors.orange,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ] else
                                const SizedBox(height: 10),
                              TextField(
                                controller: _footerRightNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _footerRightDesignationController,
                                decoration: const InputDecoration(
                                  labelText: 'Designation',
                                  hintText: 'e.g. President, Adhyaksha',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Basic Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.mandalInfo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _nameController,
                      label: '${AppLocalizations.of(context)!.mandalName} *',
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _addressController,
                      label: '${AppLocalizations.of(context)!.address} *',
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      label: AppLocalizations.of(context)!.phoneNumber,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _registrationController,
                      label: AppLocalizations.of(context)!.registrationNumber,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Officials
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.officials,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _presidentController,
                      label: AppLocalizations.of(context)!.president,
                      prefixIcon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _vicePresidentController,
                      label: AppLocalizations.of(context)!.vicePresident,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _secretaryController,
                      label: AppLocalizations.of(context)!.secretary,
                      prefixIcon: Icons.edit_note,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _treasurerController,
                      label: AppLocalizations.of(context)!.treasurer,
                      prefixIcon: Icons.account_balance_wallet,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer Text
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.receiptFooter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _headerTextController,
                      label: 'Event Greeting (e.g. Ganpati Bappa Morya!)',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _footerTextController,
                      label: AppLocalizations.of(context)!.footerMessage,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Language Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.changeTo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLanguageOption(context, 'English', 'en', '🇬🇧'),
                    const Divider(height: 1),
                    _buildLanguageOption(context, 'हिंदी', 'hi', '🇮🇳'),
                    const Divider(height: 1),
                    _buildLanguageOption(context, 'मराठी', 'mr', '🕉️'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            AppButton(
              text: AppLocalizations.of(context)!.save,
              onPressed: _isSaving ? null : _saveTenantSettings,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String title, String languageCode, String icon) {
    final languageService = Provider.of<LanguageService>(context);
    final isSelected = languageService.locale?.languageCode == languageCode;

    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 28)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.orange : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.orange)
          : null,
      onTap: () async {
        await languageService.setLocale(Locale(languageCode));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageCode == 'en'
                    ? 'Language changed to English'
                    : languageCode == 'hi'
                        ? 'भाषा हिंदी में बदल गई'
                        : 'भाषा मराठी मध्ये बदलली',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}
