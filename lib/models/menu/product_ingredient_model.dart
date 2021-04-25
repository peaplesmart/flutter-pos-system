import 'package:flutter/material.dart';
import 'package:possystem/models/menu/product_quantity_model.dart';
import 'package:possystem/models/stock/ingredient_model.dart';
import 'package:possystem/services/database.dart';

import 'product_model.dart';

class ProductIngredientModel {
  ProductIngredientModel({
    this.ingredientId,
    this.ingredient,
    @required this.product,
    num defaultAmount,
    num cost,
    Map<String, ProductQuantityModel> quantities,
  })  : quantities = quantities ?? {},
        defaultAmount = defaultAmount ?? 0,
        cost = cost ?? 0 {
    ingredientId ??= ingredient.id;
  }

  final ProductModel product;
  final Map<String, ProductQuantityModel> quantities;
  String ingredientId;
  num defaultAmount;
  num cost;
  IngredientModel ingredient;

  factory ProductIngredientModel.fromMap({
    ProductModel product,
    Map<String, dynamic> data,
    String ingredientId,
  }) {
    final quantitiesMap = data['quantities'];
    final quantities = <String, ProductQuantityModel>{};

    if (quantitiesMap is Map<String, Map>) {
      quantitiesMap.forEach((quantityId, quantity) {
        if (quantity is Map) {
          quantities[quantityId] = ProductQuantityModel.fromMap(
            quantityId,
            quantity,
          );
        }
      });
    }

    return ProductIngredientModel(
      product: product,
      ingredientId: ingredientId,
      defaultAmount: data['defaultAmount'],
      quantities: quantities,
    );
  }

  factory ProductIngredientModel.empty(ProductModel product) {
    return ProductIngredientModel(product: product, ingredientId: null);
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultAmount': defaultAmount,
      'quantities': {
        for (var entry in quantities.entries) entry.key: entry.value.toMap()
      },
    };
  }

  // STATE CHANGE

  void updateQuantity(ProductQuantityModel quantity) {
    print('update quantity ${quantity.id}');
    if (!quantities.containsKey(quantity.id)) {
      quantities[quantity.id] = quantity;
      final updateData = {
        '$prefixQuantities.${quantity.id}': quantity.toMap(),
      };

      Database.instance.update(Collections.menu, updateData);
    }

    product.ingredientChanged();
  }

  ProductQuantityModel removeQuantity(String id) {
    print('remove quantity $id');

    final quantity = quantities.remove(id);
    final updateData = {'$prefixQuantities.$id': null};
    Database.instance.update(Collections.menu, updateData);
    product.ingredientChanged();

    return quantity;
  }

  void update({
    num defaultAmount,
    IngredientModel ingredient,
  }) {
    final updateData = <String, dynamic>{};
    if (defaultAmount != this.defaultAmount) {
      this.defaultAmount = defaultAmount;
      updateData['$prefix.defaultAmount'] = defaultAmount;
    }
    // after all property set
    if (id != ingredient.id) {
      product.removeIngredient(id);

      ingredientId = ingredient.id;
      this.ingredient = ingredient;

      updateData.clear();
    }

    if (updateData.isEmpty) return;

    Database.instance.update(Collections.menu, updateData);
  }

  // HELPER

  bool has(String id) => quantities.containsKey(id);
  ProductQuantityModel operator [](String id) => quantities[id];

  // GETTER

  bool get isReady => ingredientId != null;
  bool get isNotReady => ingredientId == null;
  String get id => ingredientId;
  String get prefix => '${product.prefix}.ingredients.$id';
  String get prefixQuantities => '$prefix.quantities';
}
