/// The Little Nursery's two Sofia locations. Static content sourced from
/// thelittlenursery.bg — update here if the studio adds or moves a location.
class NurseryLocation {
  final String id;
  final String name;
  final String address;
  final String description;

  const NurseryLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
  });
}

class Locations {
  static const center = NurseryLocation(
    id: 'center',
    name: 'The Little Nursery — Center',
    address: 'ul. Solunska 60, Sofia',
    description:
        'Art studio and socialization space in the heart of Sofia, hosting '
        'workshops, baby socialization, and free play.',
  );

  static const house = NurseryLocation(
    id: 'house',
    name: 'The House of The Little Nursery',
    address: 'ul. Tsanko Tserkovski 50, Sofia',
    description:
        'A cozy house dedicated to Montessori activities, sensory play, and '
        'parent events.',
  );

  static const all = [center, house];

  static const contactPhone = '+359 886 700 702';
  static const contactEmail = 'hello@thelittlenursery.bg';
}
