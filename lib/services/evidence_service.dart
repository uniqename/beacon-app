import '../models/evidence_log.dart';
import '../services/local_database_service.dart';

class EvidenceService {
  Future<EvidenceLog> createEvidence({
    required String userId,
    required String title,
    required String description,
    required DateTime incidentDate,
    required Severity severity,
    required String location,
    List<String> photoUrls = const [],
    List<String> audioUrls = const [],
    List<String> witnesses = const [],
    bool policeInvolved = false,
    String? policeReportNumber,
    bool medicalAttention = false,
    String? hospitalName,
  }) async {
    final now = DateTime.now();
    final evidenceId = await LocalDatabaseService.saveEvidenceLog(userId, {
      'date': incidentDate.toIso8601String(),
      'incident_type': severity.name,
      'description': description,
      'location': location,
      'witnesses': witnesses.join(', '),
      'injuries': title, // Using title as injuries summary
      'police_report_number': policeReportNumber ?? '',
      'hospital_name': hospitalName ?? '',
      'photos': photoUrls,
      'audio': audioUrls,
    });

    return EvidenceLog(
      id: evidenceId,
      userId: userId,
      incidentDate: incidentDate,
      createdAt: now,
      updatedAt: now,
      title: title,
      description: description,
      severity: severity,
      location: location,
      photoUrls: photoUrls,
      audioUrls: audioUrls,
      witnesses: witnesses,
      policeInvolved: policeInvolved,
      policeReportNumber: policeReportNumber,
      medicalAttention: medicalAttention,
      hospitalName: hospitalName,
    );
  }

  Future<List<EvidenceLog>> getAllEvidence(String userId) async {
    final logs = await LocalDatabaseService.getEvidenceLogs(userId);
    return logs.map((log) {
      final severity = Severity.values.firstWhere(
        (s) => s.name == log['incident_type'],
        orElse: () => Severity.medium,
      );
      return EvidenceLog(
        id: log['id'] as String,
        userId: log['user_id'] as String,
        incidentDate: DateTime.parse(log['date'] as String),
        createdAt: DateTime.parse(log['created_at'] as String),
        updatedAt: DateTime.parse(log['created_at'] as String),
        title: log['injuries'] as String? ?? '',
        description: log['description'] as String,
        severity: severity,
        location: log['location'] as String? ?? '',
        photoUrls: (log['photos'] as List?)?.cast<String>() ?? [],
        audioUrls: (log['audio'] as List?)?.cast<String>() ?? [],
        witnesses: (log['witnesses'] as String? ?? '').split(', ').where((w) => w.isNotEmpty).toList(),
        policeInvolved: (log['police_report_number'] as String? ?? '').isNotEmpty,
        policeReportNumber: log['police_report_number'] as String?,
        medicalAttention: (log['hospital_name'] as String? ?? '').isNotEmpty,
        hospitalName: log['hospital_name'] as String?,
      );
    }).toList();
  }

  Future<EvidenceLog?> getEvidence(String id) async {
    // For now, get all evidence and filter by id
    // TODO: Add a method to LocalDatabaseService to get single evidence
    return null;
  }

  Future<void> updateEvidence(EvidenceLog evidence) async {
    await LocalDatabaseService.saveEvidenceLog(evidence.userId, {
      'date': evidence.incidentDate.toIso8601String(),
      'incident_type': evidence.severity.name,
      'description': evidence.description,
      'location': evidence.location,
      'witnesses': evidence.witnesses.join(', '),
      'injuries': evidence.title,
      'police_report_number': evidence.policeReportNumber ?? '',
      'hospital_name': evidence.hospitalName ?? '',
      'photos': evidence.photoUrls,
      'audio': evidence.audioUrls,
    });
  }

  Future<void> deleteEvidence(String id) async {
    await LocalDatabaseService.deleteEvidenceLog(id);
  }

  Future<String> exportToText(EvidenceLog evidence) async {
    final buffer = StringBuffer();
    buffer.writeln('INCIDENT REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln('Title: ${evidence.title}');
    buffer.writeln('Date: ${evidence.incidentDate}');
    buffer.writeln('Location: ${evidence.location}');
    buffer.writeln('Severity: ${evidence.severity.name.toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('DESCRIPTION:');
    buffer.writeln(evidence.description);
    buffer.writeln('');

    if (evidence.witnesses.isNotEmpty) {
      buffer.writeln('WITNESSES:');
      for (var witness in evidence.witnesses) {
        buffer.writeln('- $witness');
      }
      buffer.writeln('');
    }

    if (evidence.policeInvolved) {
      buffer.writeln('POLICE INVOLVEMENT: Yes');
      if (evidence.policeReportNumber != null) {
        buffer.writeln('Report Number: ${evidence.policeReportNumber}');
      }
      buffer.writeln('');
    }

    if (evidence.medicalAttention) {
      buffer.writeln('MEDICAL ATTENTION: Yes');
      if (evidence.hospitalName != null) {
        buffer.writeln('Hospital: ${evidence.hospitalName}');
      }
      buffer.writeln('');
    }

    buffer.writeln('ATTACHMENTS:');
    buffer.writeln('Photos: ${evidence.photoUrls.length}');
    buffer.writeln('Audio: ${evidence.audioUrls.length}');
    buffer.writeln('Documents: ${evidence.documentUrls.length}');

    return buffer.toString();
  }
}
