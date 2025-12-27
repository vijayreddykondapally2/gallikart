// seed.js - Bulk seed Firestore with sample products, orders, etc.
// Run with: export PEXELS_API_KEY=your_key && node seed.js (after installing firebase-admin and placing serviceAccount.json)

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';

const PEXELS_API_KEY = process.env.PEXELS_API_KEY || '';

async function fetchPexelsImage(query) {
  if (!PEXELS_API_KEY) return null;
  try {
    const res = await fetch(
      `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&per_page=1`,
      { headers: { Authorization: PEXELS_API_KEY } },
    );
    if (!res.ok) return null;
    const data = await res.json();
    const photo = data?.photos?.[0];
    return photo?.src?.medium || photo?.src?.large || photo?.src?.original || null;
  } catch (err) {
    console.error('Pexels fetch failed for query:', query, err?.message || err);
    return null;
  }
}

async function withPexelsImage(product) {
  let query = product.name;
  if (product.category.includes('Vegetables')) {
    query = `fresh ${product.name} vegetable`;
  } else if (product.category.includes('Fruits')) {
    query = `ripe ${product.name} fruit`;
  } else if (product.category.includes('Groceries')) {
    query = `${product.name} grocery item`;
  } else if (product.category.includes('Milk & Daily Needs')) {
    query = `${product.name} dairy product`;
  } else {
    query = `${product.name} food`;
  }
  const url = await fetchPexelsImage(query);
  return { ...product, imageUrl: url || product.imageUrl };
}

// Download serviceAccount.json from Firebase Console → Project Settings → Service Accounts → Generate new private key
const serviceAccount = JSON.parse(fs.readFileSync('serviceAccount.json', 'utf8'));
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function seed() {
  const batch = db.batch();

  // Bulk products
  const vegetables = [
    { id: 'veg_onion', name: 'Onion', category: 'Vegetables', price: 30.0, stock: 200, reorderLevel: 30, isActive: true, imageUrl: 'https://picsum.photos/200?random=onion' },
    { id: 'veg_potato', name: 'Potato', category: 'Vegetables', price: 28.0, stock: 220, reorderLevel: 40, isActive: true, imageUrl: 'https://picsum.photos/200?random=F5F5DC/000000?text=Potato' },
    { id: 'veg_tomato', name: 'Tomato', category: 'Vegetables', price: 35.0, stock: 180, reorderLevel: 25, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFCDD2/000000?text=Tomato' },
    { id: 'veg_green_chilli', name: 'Green Chilli', category: 'Vegetables', price: 70.0, stock: 90, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=A5D6A7/000000?text=Chilli' },
    { id: 'veg_okra', name: 'Lady Finger (Okra)', category: 'Vegetables', price: 60.0, stock: 120, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=81C784/000000?text=Okra' },
    { id: 'veg_brinjal', name: 'Brinjal', category: 'Vegetables', price: 55.0, stock: 100, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=CE93D8/000000?text=Brinjal' },
    { id: 'veg_cabbage', name: 'Cabbage', category: 'Vegetables', price: 48.0, stock: 90, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=AED581/000000?text=Cabbage' },
    { id: 'veg_cauliflower', name: 'Cauliflower', category: 'Vegetables', price: 70.0, stock: 85, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF59D/000000?text=Cauli' },
    { id: 'veg_carrot', name: 'Carrot', category: 'Vegetables', price: 65.0, stock: 110, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFAB91/000000?text=Carrot' },
    { id: 'veg_beans', name: 'Beans', category: 'Vegetables', price: 55.0, stock: 100, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=A5D6A7/000000?text=Beans' },
    { id: 'veg_bottle_gourd', name: 'Bottle Gourd', category: 'Vegetables', price: 50.0, stock: 90, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=99CCFF/000000?text=Bottle+Gourd' },
    { id: 'veg_ridge_gourd', name: 'Ridge Gourd', category: 'Vegetables', price: 58.0, stock: 85, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=66BB6A/000000?text=Ridge' },
    { id: 'veg_spinach', name: 'Spinach (Palak)', category: 'Vegetables', price: 40.0, stock: 140, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=AED581/000000?text=Spinach' },
    { id: 'veg_ginger', name: 'Ginger', category: 'Vegetables', price: 120.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFCC80/000000?text=Ginger' },
    { id: 'veg_garlic', name: 'Garlic', category: 'Vegetables', price: 90.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=D7CCC8/000000?text=Garlic' },
  ];
  const fruits = [
    { id: 'fruit_banana_robusta', name: 'Banana – Robusta', category: 'Fruits', price: 45.0, stock: 150, reorderLevel: 25, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF176/000000?text=Banana' },
    { id: 'fruit_banana_yelakki', name: 'Banana – Yelakki', category: 'Fruits', price: 55.0, stock: 120, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF176/000000?text=Yelakki' },
    { id: 'fruit_apple_shimla', name: 'Apple – Shimla', category: 'Fruits', price: 150.0, stock: 80, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=F48FB1/000000?text=Apple' },
    { id: 'fruit_orange', name: 'Orange', category: 'Fruits', price: 80.0, stock: 100, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFAB91/000000?text=Orange' },
    { id: 'fruit_sweet_lime', name: 'Sweet Lime (Mosambi)', category: 'Fruits', price: 60.0, stock: 110, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFECB3/000000?text=Mosambi' },
    { id: 'fruit_papaya', name: 'Papaya', category: 'Fruits', price: 45.0, stock: 90, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF9C4/000000?text=Papaya' },
    { id: 'fruit_watermelon', name: 'Watermelon', category: 'Fruits', price: 70.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=66BB6A/000000?text=Watermelon' },
    { id: 'fruit_muskmelon', name: 'Muskmelon', category: 'Fruits', price: 70.0, stock: 60, reorderLevel: 8, isActive: true, imageUrl: 'https://picsum.photos/200?random=A5D6A7/000000?text=Muskmelon' },
    { id: 'fruit_pomegranate', name: 'Pomegranate', category: 'Fruits', price: 160.0, stock: 50, reorderLevel: 8, isActive: true, imageUrl: 'https://picsum.photos/200?random=E57373/000000?text=Pomegranate' },
    { id: 'fruit_guava', name: 'Guava', category: 'Fruits', price: 50.0, stock: 110, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=AED581/000000?text=Guava' },
    { id: 'fruit_pineapple', name: 'Pineapple', category: 'Fruits', price: 80.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFCC80/000000?text=Pineapple' },
    { id: 'fruit_grapes_green', name: 'Grapes – Green', category: 'Fruits', price: 120.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=81C784/000000?text=Green+Grapes' },
    { id: 'fruit_grapes_black', name: 'Grapes – Black', category: 'Fruits', price: 140.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=6A1B9A/000000?text=Black+Grapes' },
    { id: 'fruit_pear', name: 'Pear', category: 'Fruits', price: 90.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=9CCC65/000000?text=Pear' },
    { id: 'fruit_mango', name: 'Mango (Seasonal)', category: 'Fruits', price: 120.0, stock: 50, reorderLevel: 8, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFB74D/000000?text=Mango' },
    { id: 'fruit_watermelon_half', name: 'Watermelon (Half)', category: 'Fruits', price: 40.0, stock: 80, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=66BB6A/000000?text=Watermelon' },
    { id: 'fruit_orange_navel', name: 'Orange – Navel', category: 'Fruits', price: 85.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFAB91/000000?text=Orange' },
  ];
  const groceries = [
    // Staples
    { id: 'grain_rice_raw', name: 'Rice – Raw (Sona Masoori)', category: 'Groceries – Staples', price: 56.0, stock: 120, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=F9A825/000000?text=Raw+Rice' },
    { id: 'grain_rice_boiled', name: 'Rice – Boiled', category: 'Groceries – Staples', price: 62.0, stock: 100, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=FDD835/000000?text=Boiled+Rice' },
    { id: 'grain_rice_basmati', name: 'Rice – Basmati', category: 'Groceries – Staples', price: 120.0, stock: 80, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF59D/000000?text=Basmati+Rice' },
    { id: 'grain_atta', name: 'Atta (Wheat Flour)', category: 'Groceries – Staples', price: 60.0, stock: 110, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFECB3/000000?text=Atta' },
    { id: 'grain_maida', name: 'Maida', category: 'Groceries – Staples', price: 45.0, stock: 100, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FAFAFA/000000?text=Maida' },
    { id: 'grain_rava', name: 'Rava (Sooji)', category: 'Groceries – Staples', price: 48.0, stock: 90, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE082/000000?text=Rava' },
    { id: 'dal_toor', name: 'Toor Dal', category: 'Groceries – Staples', price: 110.0, stock: 80, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFCC80/000000?text=Toor+Dal' },
    { id: 'dal_moong', name: 'Moong Dal', category: 'Groceries – Staples', price: 95.0, stock: 80, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF9C4/000000?text=Moong+Dal' },
    { id: 'dal_chana', name: 'Chana Dal', category: 'Groceries – Staples', price: 92.0, stock: 90, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=DCE775/000000?text=Chana+Dal' },
    { id: 'dal_urad', name: 'Urad Dal', category: 'Groceries – Staples', price: 115.0, stock: 70, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=DCE775/000000?text=Urad+Dal' },
    { id: 'sugar', name: 'Sugar', category: 'Groceries – Staples', price: 48.0, stock: 120, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=F8BBD0/000000?text=Sugar' },
    { id: 'salt', name: 'Salt', category: 'Groceries – Staples', price: 22.0, stock: 130, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=B0BEC5/000000?text=Salt' },
    // Cooking essentials
    { id: 'oil_sunflower', name: 'Sunflower Oil', category: 'Groceries – Cooking', price: 200.0, stock: 90, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE0B2/000000?text=Sunflower+Oil' },
    { id: 'oil_groundnut', name: 'Groundnut Oil', category: 'Groceries – Cooking', price: 220.0, stock: 70, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=D7CCC8/000000?text=Groundnut+Oil' },
    { id: 'oil_mustard', name: 'Mustard Oil', category: 'Groceries – Cooking', price: 210.0, stock: 75, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF8E1/000000?text=Mustard+Oil' },
    { id: 'ghee', name: 'Ghee', category: 'Groceries – Cooking', price: 380.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE0B2/000000?text=Ghee' },
    { id: 'seed_mustard', name: 'Mustard Seeds', category: 'Groceries – Cooking', price: 90.0, stock: 80, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFECB3/000000?text=Mustard+Seeds' },
    { id: 'seed_cumin', name: 'Cumin Seeds', category: 'Groceries – Cooking', price: 140.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=E0F2F1/000000?text=Cumin+Seeds' },
    { id: 'powder_turmeric', name: 'Turmeric Powder', category: 'Groceries – Cooking', price: 70.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF9C4/000000?text=Turmeric' },
    { id: 'powder_red_chilli', name: 'Red Chilli Powder', category: 'Groceries – Cooking', price: 95.0, stock: 65, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFCDD2/000000?text=Chilli' },
    { id: 'powder_coriander', name: 'Coriander Powder', category: 'Groceries – Cooking', price: 85.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=E6EE9C/000000?text=Coriander' },
    // Packaged daily items
    { id: 'tea_powder', name: 'Tea Powder', category: 'Groceries – Packaged', price: 140.0, stock: 90, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=DCE775/000000?text=Tea' },
    { id: 'coffee_powder', name: 'Coffee Powder', category: 'Groceries – Packaged', price: 250.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=6A1B9A/000000?text=Coffee' },
    { id: 'instant_coffee', name: 'Instant Coffee', category: 'Groceries – Packaged', price: 120.0, stock: 80, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=795548/000000?text=Instant+Coffee' },
    { id: 'poha', name: 'Poha', category: 'Groceries – Packaged', price: 45.0, stock: 120, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF9C4/000000?text=Poha' },
    { id: 'vermicelli', name: 'Vermicelli', category: 'Groceries – Packaged', price: 55.0, stock: 100, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=F8BBD0/000000?text=Vermicelli' },
    { id: 'bread_crumbs', name: 'Bread Crumbs', category: 'Groceries – Packaged', price: 65.0, stock: 80, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE082/000000?text=Bread+Crumbs' },
    { id: 'pickle_mixed', name: 'Pickle (Mixed)', category: 'Groceries – Packaged', price: 90.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FF8A65/000000?text=Pickle' },
    { id: 'jam', name: 'Jam', category: 'Groceries – Packaged', price: 85.0, stock: 70, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFB74D/000000?text=Jam' },
    // Quick / instant
    { id: 'instant_noodles', name: 'Instant Noodles', category: 'Groceries – Quick', price: 15.0, stock: 200, reorderLevel: 40, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFAB91/000000?text=Noodles' },
    { id: 'pasta', name: 'Pasta', category: 'Groceries – Quick', price: 80.0, stock: 90, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF176/000000?text=Pasta' },
    { id: 'ready_upma', name: 'Ready-to-eat Upma Mix', category: 'Groceries – Quick', price: 45.0, stock: 120, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=C8E6C9/000000?text=Upma+Mix' },
    { id: 'ready_idli_dosa', name: 'Ready-to-eat Idli/Dosa Batter', category: 'Groceries – Quick', price: 65.0, stock: 110, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE0B2/000000?text=Batter' },
    // Home & cleaning
    { id: 'dishwash_liquid', name: 'Dishwash Liquid', category: 'Groceries – Cleaning', price: 90.0, stock: 80, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=2196F3/000000?text=Dishwash' },
    { id: 'washing_powder', name: 'Washing Powder', category: 'Groceries – Cleaning', price: 120.0, stock: 90, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=C5E1A5/000000?text=Washing+Powder' },
    { id: 'washing_bar', name: 'Washing Bar', category: 'Groceries – Cleaning', price: 40.0, stock: 140, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE082/000000?text=Washing+Bar' },
    { id: 'toilet_cleaner', name: 'Toilet Cleaner', category: 'Groceries – Cleaning', price: 95.0, stock: 70, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=4FC3F7/000000?text=Toilet+Cleaner' },
    { id: 'floor_cleaner', name: 'Floor Cleaner', category: 'Groceries – Cleaning', price: 110.0, stock: 70, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=9CCC65/000000?text=Floor+Cleaner' },
    // Personal care
    { id: 'bath_soap', name: 'Bath Soap', category: 'Groceries – Personal Care', price: 35.0, stock: 160, reorderLevel: 25, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF59D/000000?text=Soap' },
    { id: 'shampoo_sachet', name: 'Shampoo Sachet', category: 'Groceries – Personal Care', price: 18.0, stock: 180, reorderLevel: 30, isActive: true, imageUrl: 'https://picsum.photos/200?random=81D4FA/000000?text=Shampoo' },
    { id: 'toothpaste', name: 'Toothpaste', category: 'Groceries – Personal Care', price: 55.0, stock: 140, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFCCBC/000000?text=Toothpaste' },
    { id: 'toothbrush', name: 'Toothbrush', category: 'Groceries – Personal Care', price: 45.0, stock: 140, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=CE93D8/000000?text=Toothbrush' },
  ];
  const dailyAddOns = [
    { id: 'daily_milk_500ml', name: 'Milk 500ml', category: 'Milk & Daily Needs', price: 28.0, stock: 150, reorderLevel: 25, isActive: true, imageUrl: 'https://picsum.photos/200?random=BBDEFB/000000?text=Milk+500ml' },
    { id: 'daily_milk_1l', name: 'Milk 1L', category: 'Milk & Daily Needs', price: 50.0, stock: 140, reorderLevel: 25, isActive: true, imageUrl: 'https://picsum.photos/200?random=90CAF9/000000?text=Milk+1L' },
    { id: 'daily_curd', name: 'Curd', category: 'Milk & Daily Needs', price: 32.0, stock: 120, reorderLevel: 20, isActive: true, imageUrl: 'https://picsum.photos/200?random=E1BEE7/000000?text=Curd' },
    { id: 'daily_eggs_6', name: 'Eggs (6 pack)', category: 'Milk & Daily Needs', price: 40.0, stock: 100, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE0B2/000000?text=Eggs+6' },
    { id: 'daily_eggs_12', name: 'Eggs (12 pack)', category: 'Milk & Daily Needs', price: 75.0, stock: 90, reorderLevel: 15, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFE0B2/000000?text=Eggs+12' },
    { id: 'daily_bread', name: 'Bread', category: 'Milk & Daily Needs', price: 30.0, stock: 140, reorderLevel: 25, isActive: true, imageUrl: 'https://picsum.photos/200?random=EF9A9A/000000?text=Bread' },
    { id: 'daily_butter', name: 'Butter', category: 'Milk & Daily Needs', price: 90.0, stock: 80, reorderLevel: 12, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFD54F/000000?text=Butter' },
    { id: 'daily_paneer', name: 'Paneer', category: 'Milk & Daily Needs', price: 140.0, stock: 60, reorderLevel: 10, isActive: true, imageUrl: 'https://picsum.photos/200?random=FFF9C4/000000?text=Paneer' },
  ];

  const baseProducts = [...vegetables, ...fruits, ...groceries, ...dailyAddOns];
  const products = await Promise.all(baseProducts.map(withPexelsImage));

  products.forEach(prod => {
    const ref = db.collection('products').doc(prod.id);
    batch.set(ref, prod);
  });

  // Sample user
  const userRef = db.collection('users').doc('user-1');
  batch.set(userRef, {
    phone: '9876543210',
    name: 'Demo User',
    address: 'Hyderabad Outskirts',
    createdAt: FieldValue.serverTimestamp(),
  });

  // Sample order
  const orderRef = db.collection('orders').doc('order-1');
  batch.set(orderRef, {
    userId: 'user-1',
    status: 'pending',
    total: 96.0,
    createdAt: FieldValue.serverTimestamp(),
    items: [
      { productId: 'prod-1', name: 'Milk 1L', qty: 2, price: 48.0 },
    ],
  });

  // Sample delivery task
  const deliveryRef = db.collection('delivery_tasks').doc('deliv-1');
  batch.set(deliveryRef, {
    orderId: 'order-1',
    status: 'assigned',
    partner: 'Ravi',
    pickupEta: 10,
    dropoffEta: 30,
    lat: 17.3850,
    lng: 78.4867,
    deliveredAt: null,
  });

  await batch.commit();
  console.log('Bulk seeded 10 products, 1 user, 1 order, 1 delivery task');
}

seed().catch(console.error);