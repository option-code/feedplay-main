const fs = require('fs');
const path = require('path');

const filePath = path.resolve(__dirname, '../assets/horizantal.json');

function run() {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    const json = JSON.parse(raw);

    // Support both array root and { games: [...] }
    const games = Array.isArray(json) ? json : (json.games || []);

    const lowerToOriginal = new Map();
    for (const g of games) {
      const cat = (g.category || '').trim();
      if (!cat) continue;
      const lower = cat.toLowerCase();
      if (!lowerToOriginal.has(lower)) lowerToOriginal.set(lower, cat);
    }

    const unique = Array.from(lowerToOriginal.values())
      .sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

    // Print summary and list, one per line
    console.log(`Total categories: ${unique.length}`);
    for (const c of unique) console.log(c);
  } catch (e) {
    console.error('Failed to extract categories:', e.message);
    process.exit(1);
  }
}

run();


