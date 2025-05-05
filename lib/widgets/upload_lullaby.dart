import 'package:flutter/material.dart';

class UploadLullaby extends StatelessWidget {
  const UploadLullaby({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Upload a Lullaby',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F51B5),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUploadButton(context, 'Choose File'),
          const SizedBox(height: 12),
          _buildUploadButton(context, 'Select from App Library'),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label clicked')));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3F51B5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'LeagueSpartan', fontSize: 16)),
      ),
    );
  }
}
