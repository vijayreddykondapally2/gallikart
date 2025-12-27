const PEXELS_API_KEY = process.env.PEXELS_API_KEY;

async function fetchPexelsImage(query) {
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

async function main() {
  const categories = ['Vegetables', 'Fruits', 'Groceries', 'Milk & Daily Needs'];
  const categoryImages = {};
  for (const cat of categories) {
    const query = `fresh ${cat.toLowerCase()}`;
    const url = await fetchPexelsImage(query);
    categoryImages[cat] = url || `https://picsum.photos/seed/${cat.toLowerCase()}/200/150`;
    console.log(`${cat}: ${categoryImages[cat]}`);
  }
  console.log('Category Images:', JSON.stringify(categoryImages, null, 2));
}

main();