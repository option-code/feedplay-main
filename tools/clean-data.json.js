const fs = require('fs');
const path = require('path');

// Path to data.json
const dataJsonPath = path.join(__dirname, '..', 'assets', 'data.json');
const backupPath = path.join(__dirname, '..', 'assets', 'data.json.backup');

console.log('🧹 Starting data.json cleanup...');
console.log('📁 Reading file:', dataJsonPath);

try {
  // Read data.json
  const jsonString = fs.readFileSync(dataJsonPath, 'utf8');
  console.log('✅ File read successfully');
  
  // Parse JSON
  const games = JSON.parse(jsonString);
  console.log(`📊 Total games: ${games.length}`);
  
  // Create backup
  console.log('💾 Creating backup...');
  fs.writeFileSync(backupPath, jsonString, 'utf8');
  console.log('✅ Backup created:', backupPath);
  
  // Count fields to remove
  let instructionsCount = 0;
  let widthCount = 0;
  let heightCount = 0;
  
  // Remove instructions, width, and height from each game
  console.log('🔧 Removing fields...');
  games.forEach((game, index) => {
    if (game.instructions !== undefined) {
      delete game.instructions;
      instructionsCount++;
    }
    if (game.width !== undefined) {
      delete game.width;
      widthCount++;
    }
    if (game.height !== undefined) {
      delete game.height;
      heightCount++;
    }
    
    // Progress indicator for large files
    if ((index + 1) % 1000 === 0) {
      console.log(`   Processed ${index + 1}/${games.length} games...`);
    }
  });
  
  console.log(`✅ Fields removed:`);
  console.log(`   - instructions: ${instructionsCount}`);
  console.log(`   - width: ${widthCount}`);
  console.log(`   - height: ${heightCount}`);
  
  // Convert back to JSON with proper formatting
  console.log('💾 Writing updated data.json...');
  const updatedJsonString = JSON.stringify(games, null, 2);
  fs.writeFileSync(dataJsonPath, updatedJsonString, 'utf8');
  console.log('✅ Updated data.json saved successfully!');
  
  // Show file size comparison
  const originalSize = (jsonString.length / 1024 / 1024).toFixed(2);
  const newSize = (updatedJsonString.length / 1024 / 1024).toFixed(2);
  const savedSize = ((jsonString.length - updatedJsonString.length) / 1024 / 1024).toFixed(2);
  
  console.log('\n📊 File size comparison:');
  console.log(`   Original: ${originalSize} MB`);
  console.log(`   Updated:  ${newSize} MB`);
  console.log(`   Saved:    ${savedSize} MB`);
  
  console.log('\n✨ Cleanup completed successfully!');
  console.log(`📦 Backup saved at: ${backupPath}`);
  
} catch (error) {
  console.error('❌ Error:', error.message);
  console.error(error.stack);
  process.exit(1);
}

