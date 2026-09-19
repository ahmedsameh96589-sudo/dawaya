import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../presentation/prescription_request.dart';

/// Prescription uploads for medicines that need a pharmacist's approval.
class PrescriptionRepository {
  PrescriptionRepository(this._api);

  final ApiClient _api;

  /// Uploads a prescription photo and returns the request id.
  Future<String> submit({
    required String productId,
    required String productName,
    required String imagePath,
  }) async {
    final body = await _api.upload(
      '/prescriptions',
      fileField: 'prescription',
      filePath: imagePath,
      fields: {'productId': productId, 'productName': productName},
    );
    return dataObject(body, 'prescription')['_id'] as String;
  }

  Future<PrescriptionRequest> fetch(String id) async =>
      PrescriptionRequest.fromJson(
        dataObject(await _api.get('/prescriptions/$id'), 'prescription'),
      );

  /// Admin: prescriptions waiting for review.
  Future<List<PrescriptionRequest>> fetchPending() async {
    final body = await _api.get(
      '/admin/prescriptions',
      query: {'status': 'pending_review'},
    );
    return dataList(
      body,
      'prescriptions',
    ).map(PrescriptionRequest.fromJson).toList();
  }

  Future<void> approve(String id, {String? note}) =>
      _review(id, 'approved', note);

  Future<void> reject(String id, {String? note}) =>
      _review(id, 'rejected', note);

  Future<void> _review(String id, String status, String? note) => _api.put(
    '/admin/prescriptions/$id/review',
    body: {'status': status, 'reviewNote': note ?? ''},
  );
}

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>(
  (ref) => PrescriptionRepository(ref.watch(apiClientProvider)),
);

/// Live status of one prescription request, refreshed every 5 seconds while
/// a screen is watching it and stopped as soon as none is. Emits `null`
/// when a refresh fails, so the UI can keep showing the last known state.
final prescriptionStatusProvider = StreamProvider.autoDispose
    .family<PrescriptionRequest?, String>((ref, id) async* {
      final repository = ref.watch(prescriptionRepositoryProvider);
      var active = true;
      ref.onDispose(() => active = false);

      while (active) {
        try {
          yield await repository.fetch(id);
        } catch (_) {
          yield null;
        }
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    });
