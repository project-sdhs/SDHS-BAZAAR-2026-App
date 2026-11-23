import 'package:flutter/material.dart';

import '../../../data/models/booth_category.dart';

extension BoothCategoryIcon on BoothCategory {
  IconData get icon => switch (this) {
    BoothCategory.snack => Icons.ramen_dining,
    BoothCategory.dessert => Icons.bakery_dining,
    BoothCategory.drink => Icons.local_cafe,
    BoothCategory.korean => Icons.rice_bowl,
    BoothCategory.goods => Icons.shopping_bag,
    BoothCategory.activity => Icons.sports_esports,
    BoothCategory.exhibition => Icons.palette,
    BoothCategory.special => Icons.school,
  };
}
