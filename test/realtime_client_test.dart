import 'package:dawayaa/core/network/realtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RealtimeClient client;

  setUp(() => client = RealtimeClient(url: 'http://unused'));
  tearDown(() => client.dispose());

  test('routes a new message to listeners of that consultation only', () async {
    final mine = client.eventsFor('c1').toList();
    final other = client.eventsFor('c2').toList();

    client.handleEvent('consultation:message', {
      'consultationId': 'c1',
      'status': 'active',
      'message': {
        '_id': 'm1',
        'senderType': 'doctor',
        'text': 'Take it after food',
      },
    });
    client.dispose();

    final events = await mine;
    expect(events, hasLength(1));
    expect(events.single.message?.text, 'Take it after food');
    expect(events.single.message?.senderType, 'doctor');
    expect(events.single.status, 'active');
    expect(await other, isEmpty);
  });

  test('a status update carries no message', () async {
    final events = client.eventsFor('c1').toList();

    client.handleEvent('consultation:updated', {
      'consultationId': 'c1',
      'status': 'closed',
    });
    client.dispose();

    final event = (await events).single;
    expect(event.message, isNull);
    expect(event.status, 'closed');
  });

  test('ignores malformed payloads', () async {
    final events = client.eventsFor('c1').toList();

    client.handleEvent('consultation:message', 'not a map');
    client.handleEvent('consultation:message', {'message': {}});
    client.dispose();

    expect(await events, isEmpty);
  });
}
