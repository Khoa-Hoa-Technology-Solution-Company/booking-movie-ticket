class Product {
  final int id;
  final String name;
  final double price;
  final String? imageUrl;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }
}

class Combo {
  final int id;
  final String name;
  final double price;
  final String? description;
  final bool isActive;

  const Combo({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    required this.isActive,
  });

  factory Combo.fromJson(Map<String, dynamic> json) {
    return Combo(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'is_active': isActive,
    };
  }
}

class CartItem {
  final Product? product;
  final Combo? combo;
  int quantity;

  CartItem({
    this.product,
    this.combo,
    required this.quantity,
  }) : assert((product != null && combo == null) || (product == null && combo != null));

  bool get isCombo => combo != null;

  String get name => isCombo ? combo!.name : product!.name;

  double get price => isCombo ? combo!.price : product!.price;

  double get totalAmount => price * quantity;

  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': product?.id,
      'combo_id': combo?.id,
      'quantity': quantity,
      'price': price,
    };
  }
}
