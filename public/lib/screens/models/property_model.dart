class PropertyModel {
  final String id;
  final String type;
  final String subtype;
  final int bedrooms;
  final double price;
  final double area;
  final String address;
  final String imageUrl;

  PropertyModel({
    required this.id,
    required this.type,
    required this.subtype,
    required this.bedrooms,
    required this.price,
    required this.area,
    required this.address,
    required this.imageUrl,
  });

  PropertyModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type = json['type'],
        subtype = json['subtype'],
        bedrooms = json['bedrooms'],
        price = json['price'],
        area = json['area'],
        address = json['address'],
        imageUrl = json['imageUrl'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'subtype': subtype,
        'bedrooms': bedrooms,
        'price': price,
        'area': area,
        'address': address,
        'imageUrl': imageUrl,
      };
}
