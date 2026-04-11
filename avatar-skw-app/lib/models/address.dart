class Address {
  final String id;
  final String userId;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String? landmark;
  final String? label;
  final AddressType type;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    this.landmark,
    this.label,
    this.type = AddressType.home,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      phone: json['phone'] ?? '',
      landmark: json['landmark'],
      label: json['label'],
      type: AddressType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'home'),
        orElse: () => AddressType.home,
      ),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Don't send id and userId - backend handles these
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'landmark': landmark,
      'label': label,
      'type': type.name,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? name,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? landmark,
    String? label,
    AddressType? type,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
      landmark: landmark ?? this.landmark,
      label: label ?? this.label,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

enum AddressType {
  home,
  work,
  other,
}
