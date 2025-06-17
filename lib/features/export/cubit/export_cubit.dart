import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../../features/thoughts/services/encryption_service.dart';
import 'export_state.dart';

class ExportCubit extends Cubit<ExportState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;

  ExportCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        super(const ExportInitial());

  Future<void> exportData(String password) async {
    try {
      emit(const ExportLoading());

      final user = _auth.currentUser;
      if (user == null) {
        emit(const ExportError('User not authenticated'));
        return;
      }

      
      await _encryptionService.initialize(user);

      
      final threadsSnapshot = await _firestore
          .collection('threads')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final thoughtsSnapshot = await _firestore
          .collection('thoughts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      
      final moodsSnapshot = await _firestore
          .collection('moods')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      
      final exportData = {
        'export_info': {
          'timestamp': DateTime.now().toIso8601String(),
          'user_id': user.uid,
          'app': 'Symbiote Journal',
          'version': '1.0.0'
        },
        'threads': threadsSnapshot.docs.map((doc) => _decryptAndConvertDoc(doc)).toList(),
        'thoughts': thoughtsSnapshot.docs.map((doc) => _decryptAndConvertDoc(doc)).toList(),
        'moods': moodsSnapshot.docs.map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            })).toList(),
      };

      
      final jsonData = json.encode(exportData);

      
      final encryptedData = _xorEncrypt(jsonData, password);
      
      
      final base64Data = base64.encode(encryptedData);

      
      final fileContent = _createFileContent(base64Data);

      
      await _shareFile(fileContent);

      emit(const ExportSuccess());
    } catch (e) {
      emit(ExportError('Export failed: ${e.toString()}'));
    }
  }

  List<int> _xorEncrypt(String data, String password) {
    final dataBytes = utf8.encode(data);
    final passwordBytes = utf8.encode(password);
    final encrypted = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ passwordBytes[i % passwordBytes.length]);
    }

    return encrypted;
  }

  Map<String, dynamic> _decryptAndConvertDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final decryptedData = <String, dynamic>{
      'id': doc.id,
    };

    
    if (data.containsKey('encryptedContent') && data.containsKey('iv')) {
      try {
        final decryptedContent = _encryptionService.decryptText(
          data['encryptedContent'] as String,
          data['iv'] as String,
        );
        decryptedData['content'] = decryptedContent;
      } catch (e) {
        
        decryptedData['encryptedContent'] = data['encryptedContent'];
        decryptedData['iv'] = data['iv'];
      }
    }

    
    for (final entry in data.entries) {
      if (entry.key != 'encryptedContent' && entry.key != 'iv') {
        decryptedData[entry.key] = entry.value;
      } else if (!decryptedData.containsKey('content')) {
        
        decryptedData[entry.key] = entry.value;
      }
    }

    return _convertTimestamps(decryptedData);
  }

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final convertedData = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is Timestamp) {
        convertedData[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
      } else if (entry.value is Map<String, dynamic>) {
        convertedData[entry.key] = _convertTimestamps(entry.value as Map<String, dynamic>);
      } else {
        convertedData[entry.key] = entry.value;
      }
    }
    
    return convertedData;
  }

  String _createFileContent(String base64Data) {
    final instructions = '''
====================================================================
SYMBIOTE JOURNAL EXPORT - ENCRYPTED DATA
====================================================================

This file contains your encrypted journal entries and mood data.

DECRYPTION INSTRUCTIONS:
1. Go to https://gchq.github.io/CyberChef/
2. Operations:
   a. From Base64
   b. XOR with key: your_password (Scheme: Standard)
3. Output is your content

====================================================================
ENCRYPTED CONTENT (Base64):
====================================================================

$base64Data

====================================================================
END OF FILE
====================================================================
''';

    return instructions;
  }

  Future<void> _shareFile(String content) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'symbiote_journal_export_$timestamp.txt';
    
    await Share.shareXFiles(
      [XFile.fromData(
        utf8.encode(content),
        name: fileName,
        mimeType: 'text/plain',
      )],
      subject: 'Symbiote Journal Export',
      text: 'Your encrypted journal export is ready',
    );
  }
} 