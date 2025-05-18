import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Initialize Firebase services
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // For enabling Firestore persistence (offline data)
  static Future<void> enablePersistence() async {
    try {
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      debugPrint('Firebase persistence enabled successfully');
    } catch (e) {
      debugPrint('Error enabling Firebase persistence: $e');
    }
  }

  // Initialize all Firebase settings
  static Future<void> initializeSettings() async {
    // Enable persistence for offline access
    if (!kIsWeb) {
      // Skip persistence on web platform
      await enablePersistence();
    }

    // Set cache size to 100MB
    FirebaseFirestore.instance.settings = const Settings(
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Initialize any other Firebase settings here
  }

  // Seed initial data (use this only for development or first time setup)
  static Future<void> seedInitialData() async {
    // Check if categories collection exists and has documents
    final categoriesSnapshot = await firestore.collection('categories').get();
    if (categoriesSnapshot.docs.isEmpty) {
      // Add default categories
      final batch = firestore.batch();
      final categories = [
        'Vegetables',
        'Fruits',
        'Grains',
        'Meat',
        'Dairy',
        'Spices',
        'Spare Parts',
      ];

      for (final category in categories) {
        final docRef = firestore.collection('categories').doc();
        batch.set(docRef, {'name': category, 'createdAt': FieldValue.serverTimestamp()});
      }

      // Commit the batch
      await batch.commit();
      debugPrint('Default categories added');
    }

    // Check if locations collection exists and has documents
    final locationsSnapshot = await firestore.collection('locations').get();
    if (locationsSnapshot.docs.isEmpty) {
      // Add default locations
      final batch = firestore.batch();
      final locations = [
        'Mbare Musika',
        'Sakubva',
        'Kudzanai',
        'Mucheke',
        'Gokwe',
        'Kaguvi'
      ];

      for (final location in locations) {
        final docRef = firestore.collection('locations').doc();
        batch.set(docRef, {'name': location, 'createdAt': FieldValue.serverTimestamp()});
      }

      // Commit the batch
      await batch.commit();
      debugPrint('Default locations added');
    }
  }
}