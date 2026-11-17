/// Starter data (same as the web app's SEED in db.js).
/// Password for every account: sizzle123
const seedPasswordHash = '63415ba544d8ad8893fff5efedb3ef90c96bbe722fe0feb73fb5f25dac69fda7';

const kSodaFlavors = ['Strawberry', 'Lychee', 'Green Apple', 'Lemon', 'Blueberry'];
const kFriesFlavors = ['Cheese', 'Sour Cream', 'Barbecue'];

List<Map<String, dynamic>> seedUsers() => [
      {
        'id': '5a285dbb-7c3b-45c8-9250-fdd0552e53d0',
        'full_name': 'Manager',
        'username': 'manager',
        'password_hash': seedPasswordHash,
        'role': 'owner',
        'is_active': 1,
      },
      for (var n = 1; n <= 6; n++)
        {
          'id': 'staff-$n',
          'full_name': 'Staff $n',
          'username': 'staff$n',
          'password_hash': seedPasswordHash,
          'role': 'staff',
          'is_active': 1,
        },
    ];

const seedCategories = <List<dynamic>>[
  [1, 'Meals'],
  [2, 'Silog Meals'],
  [3, 'Snacks'],
  [4, 'Fries'],
  [5, 'Fruit Soda Series'],
  [6, 'Yakult Series'],
  [7, 'Special Drinks'],
  [8, 'Snack Combos'],
];

const seedExpenseCategories = <List<dynamic>>[
  [1, 'Ingredients'],
  [2, 'Supplies and Packaging'],
  [3, 'Utilities'],
  [4, 'Transportation'],
  [5, 'Salaries'],
  [6, 'Others'],
];

Map<String, dynamic> _sizes2(String t, num a, num b) => {
      'type': t,
      'sizes': [
        {'name': '12oz', 'price': a},
        {'name': '16oz', 'price': b},
      ],
    };

/// [id, category_id, name, price, options]
final List<List<dynamic>> seedProducts = [
  [1, 1, 'Chicken Pastil', 55, null],
  [2, 1, 'Pork Tonkatsu', 69, null],
  [3, 1, 'Fried Chicken', 55, null],
  [4, 1, 'Pork Sisig (Regular)', 59, null],
  [5, 1, 'Pork Sisig with Egg', 69, null],
  [6, 2, 'Hotsilog', 39, null],
  [7, 2, 'Lumpiasilog', 39, null],
  [8, 2, 'Siomaisilog', 39, null],
  [9, 2, 'Hamsilog', 39, null],
  [10, 2, 'Porksilog', 59, null],
  [11, 2, 'Tapsilog', 69, null],
  [12, 3, 'Regular Burger', 20, null],
  [13, 3, 'Cheese Burger', 25, null],
  [14, 3, 'Burger With Egg', 35, null],
  [15, 3, 'Hotdog Sandwich', 25, null],
  [16, 3, 'Cheesy Hotdog Sandwich', 35, null],
  [17, 4, 'Fries', 30, {'type': 'fries', 'flavors': kFriesFlavors}],
  [
    18, 5, 'Fruit Soda', 29,
    {..._sizes2('flavorSize', 29, 39), 'flavors': kSodaFlavors}
  ],
  [
    19, 6, 'Yakult Series', 44,
    {..._sizes2('flavorSize', 44, 54), 'flavors': kSodaFlavors}
  ],
  [20, 7, 'Iced Coffee Latte', 49, _sizes2('size', 49, 59)],
  [21, 7, 'Matcha Latte', 49, _sizes2('size', 49, 59)],
  [22, 7, 'Lemonade', 39, _sizes2('size', 39, 49)],
  [23, 7, 'Oreo Matcha Latte', 59, _sizes2('size', 59, 69)],
  [
    24, 8, 'Combo A', 45,
    {'type': 'combo', 'requires': ['sodaFlavor'], 'included': 'Regular Burger + Fruit Soda', 'price': 45}
  ],
  [
    25, 8, 'Combo B', 50,
    {'type': 'combo', 'requires': ['sodaFlavor'], 'included': 'Hotdog Sandwich + Fruit Soda', 'price': 50}
  ],
  [
    26, 8, 'Combo C', 55,
    {'type': 'combo', 'requires': ['friesFlavor', 'sodaFlavor'], 'included': 'Fries + Fruit Soda', 'price': 55}
  ],
  [
    27, 8, 'Combo D', 45,
    {'type': 'combo', 'requires': ['friesFlavor'], 'included': 'Regular Burger + Fries', 'price': 45}
  ],
  [
    28, 8, 'Combo E', 50,
    {'type': 'combo', 'requires': ['friesFlavor'], 'included': 'Hotdog Sandwich + Fries', 'price': 50}
  ],
];
