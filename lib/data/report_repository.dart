import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/config/app_config.dart';

class ReportRepository {
  static final ReportRepository instance = ReportRepository._();
  ReportRepository._();

  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Submits to reports/{id} and triggers email via Firestore Trigger Email extension.
  // To enable email: install "Trigger Email from Firestore" Firebase extension,
  // configure SMTP, and set the collection to "mail".
  Future<String> submitReport({
    required String category,
    required String description,
    required bool anonymous,
    required bool includeDevInfo,
    String? contactEmail,
    String? uid,
    String? appVersion,
    String? platform,
  }) async {
    final id = _uuid.v4();
    final now = FieldValue.serverTimestamp();

    final report = <String, dynamic>{
      'category': category,
      'description': description,
      'anonymous': anonymous,
      'status': 'open',
      'createdAt': now,
      if (!anonymous && contactEmail != null && contactEmail.isNotEmpty)
        'contactEmail': contactEmail,
      if (!anonymous && uid != null) 'uid': uid,
      if (includeDevInfo) ...{
        'appVersion': appVersion ?? '1.0.0',
        'platform': platform ?? 'unknown',
      },
    };

    await _db.collection('reports').doc(id).set(report);

    // Trigger Email extension: write to "mail" collection
    await _db.collection('mail').doc(id).set({
      'to': [AppConfig.reportEmail],
      'message': {
        'subject': '[Divine Chat] ${_categoryLabel(category)} report',
        'html': _buildEmailHtml(
          id: id,
          category: category,
          description: description,
          anonymous: anonymous,
          contactEmail: anonymous ? null : contactEmail,
          appVersion: includeDevInfo ? (appVersion ?? '1.0.0') : null,
          platform: includeDevInfo ? platform : null,
        ),
      },
    });

    return id;
  }

  static String _categoryLabel(String id) {
    const labels = {
      'inaccurate': 'Inaccurate answer',
      'disrespect': 'Disrespectful response',
      'inappropriate': 'Inappropriate content',
      'translation': 'Translation error',
      'voice': 'Voice / audio issue',
      'bug': 'Bug or crash',
      'account': 'Account / billing',
      'other': 'Other',
    };
    return labels[id] ?? id;
  }

  static String _buildEmailHtml({
    required String id,
    required String category,
    required String description,
    required bool anonymous,
    String? contactEmail,
    String? appVersion,
    String? platform,
  }) {
    final safeDesc = description
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br>');

    return '''
<h2 style="margin:0 0 16px;font-family:sans-serif">
  Divine Dialogue — ${_categoryLabel(category)}
</h2>
<table style="font-family:sans-serif;font-size:14px;border-collapse:collapse">
  <tr><td style="padding:4px 12px 4px 0;color:#888">Ref</td><td>DD-${id.substring(0, 8).toUpperCase()}</td></tr>
  <tr><td style="padding:4px 12px 4px 0;color:#888">Category</td><td>${_categoryLabel(category)}</td></tr>
  <tr><td style="padding:4px 12px 4px 0;color:#888">Anonymous</td><td>${anonymous ? 'Yes' : 'No'}</td></tr>
  ${contactEmail != null && contactEmail.isNotEmpty ? '<tr><td style="padding:4px 12px 4px 0;color:#888">Contact</td><td>$contactEmail</td></tr>' : ''}
  ${appVersion != null ? '<tr><td style="padding:4px 12px 4px 0;color:#888">App</td><td>v$appVersion · $platform</td></tr>' : ''}
</table>
<hr style="margin:16px 0;border:none;border-top:1px solid #eee">
<h3 style="font-family:sans-serif;margin:0 0 8px">Description</h3>
<p style="font-family:sans-serif;font-size:14px;line-height:1.6;color:#333;margin:0">$safeDesc</p>
''';
  }
}
