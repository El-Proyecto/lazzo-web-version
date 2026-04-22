import 'package:flutter_test/flutter_test.dart';
import 'package:lazzo/features/create_event/data/models/location_model.dart';

void main() {
  group('LocationModel', () {
    final fullJson = <String, dynamic>{
      'id': 'loc-1',
      'display_name': 'Casa',
      'formatted_address': 'Rua B, 200',
      'latitude': 40.6405,
      'longitude': -8.6538,
    };

    test('fromJson parses lat lng display_name and formatted_address', () {
      final model = LocationModel.fromJson(fullJson);

      expect(model.id, 'loc-1');
      expect(model.displayName, 'Casa');
      expect(model.formattedAddress, 'Rua B, 200');
      expect(model.latitude, 40.6405);
      expect(model.longitude, -8.6538);
    });

    test('toEntity produces EventLocation', () {
      final entity = LocationModel.fromJson(fullJson).toEntity();

      expect(entity.id, 'loc-1');
      expect(entity.displayName, 'Casa');
      expect(entity.formattedAddress, 'Rua B, 200');
      expect(entity.latitude, 40.6405);
      expect(entity.longitude, -8.6538);
    });

    test('toEntity uses formattedAddress as displayName fallback', () {
      final json = Map<String, dynamic>.from(fullJson)..['display_name'] = null;
      final entity = LocationModel.fromJson(json).toEntity();

      expect(entity.displayName, 'Rua B, 200');
    });
  });
}
