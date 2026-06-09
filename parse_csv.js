const fs = require('fs');

const inputFile = 'D:\\lm_admin\\lakshyamarch-student\\data_safety_sample.csv';
const outputFile = 'D:\\lm_admin\\lakshyamarch-student\\data_safety_import.csv';

const mapping = {
  "PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA|": "true",
  "PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT|": "true",
  "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS|PSL_ACM_USER_ID_PASSWORD": "true", // Adding this since account creation is needed for login
  "PSL_SUPPORT_DATA_DELETION_BY_USER|DATA_DELETION_YES": "true",
  "PSL_ACCOUNT_DELETION_URL|": "https://support.lakshyamarch.com/deleteaccount",
  "PSL_DATA_DELETION_URL|": "https://support.lakshyamarch.com/deleteaccount",
  "PSL_DATA_TYPES_PERSONAL|PSL_NAME": "true",
  "PSL_DATA_TYPES_PERSONAL|PSL_EMAIL": "true",
  "PSL_DATA_TYPES_PERSONAL|PSL_USER_ACCOUNT": "true",
  "PSL_DATA_TYPES_PERSONAL|PSL_PHONE": "true",
  "PSL_DATA_TYPES_PHOTOS_AND_VIDEOS|PSL_PHOTOS": "true",
  "PSL_DATA_TYPES_APP_PERFORMANCE|PSL_CRASH_LOGS": "true",
  "PSL_DATA_TYPES_APP_PERFORMANCE|PSL_PERFORMANCE_DIAGNOSTICS": "true",
  "PSL_DATA_TYPES_IDENTIFIERS|PSL_DEVICE_ID": "true"
};

const dataTypes = [
  "PSL_NAME", "PSL_EMAIL", "PSL_USER_ACCOUNT", "PSL_PHONE", 
  "PSL_PHOTOS", "PSL_CRASH_LOGS", "PSL_PERFORMANCE_DIAGNOSTICS", "PSL_DEVICE_ID"
];

dataTypes.forEach(type => {
  mapping[`PSL_DATA_USAGE_RESPONSES:${type}:PSL_DATA_USAGE_COLLECTION_AND_SHARING|PSL_DATA_USAGE_ONLY_COLLECTED`] = "true";
  mapping[`PSL_DATA_USAGE_RESPONSES:${type}:PSL_DATA_USAGE_EPHEMERAL|`] = "false";
  mapping[`PSL_DATA_USAGE_RESPONSES:${type}:DATA_USAGE_USER_CONTROL|PSL_DATA_USAGE_USER_CONTROL_REQUIRED`] = "true";
  mapping[`PSL_DATA_USAGE_RESPONSES:${type}:DATA_USAGE_COLLECTION_PURPOSE|PSL_APP_FUNCTIONALITY`] = "true";
  
  if (type === "PSL_CRASH_LOGS" || type === "PSL_PERFORMANCE_DIAGNOSTICS") {
    mapping[`PSL_DATA_USAGE_RESPONSES:${type}:DATA_USAGE_COLLECTION_PURPOSE|PSL_ANALYTICS`] = "true";
  } else {
    mapping[`PSL_DATA_USAGE_RESPONSES:${type}:DATA_USAGE_COLLECTION_PURPOSE|PSL_ACCOUNT_MANAGEMENT`] = "true";
  }
});

function parseCSVLine(text) {
  const result = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    if (char === '"' && text[i+1] === '"') {
      current += '"';
      i++;
    } else if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += char;
    }
  }
  result.push(current);
  return result;
}

function stringifyCSVLine(row) {
  return row.map(cell => {
    if (cell.includes(',') || cell.includes('"') || cell.includes('\n')) {
      return '"' + cell.replace(/"/g, '""') + '"';
    }
    return cell;
  }).join(',');
}

try {
  const content = fs.readFileSync(inputFile, 'utf-8');
  const lines = content.split('\n');
  const newLines = [];
  
  for (let i = 0; i < lines.length; i++) {
    let line = lines[i].trim();
    if (!line) continue;
    
    // For header, keep it
    if (i === 0) {
      newLines.push(line);
      continue;
    }
    
    const row = parseCSVLine(line);
    if (row.length < 5) {
      newLines.push(line);
      continue;
    }
    
    const qid = row[0];
    const rid = row[1];
    
    // Clear out any old response values first to ensure a clean slate
    row[2] = '';
    
    const key = `${qid}|${rid}`;
    if (mapping[key] !== undefined) {
      row[2] = mapping[key];
    }
    
    newLines.push(stringifyCSVLine(row));
  }
  
  fs.writeFileSync(outputFile, newLines.join('\n'));
  console.log('Successfully created data_safety_import.csv');
} catch (e) {
  console.error('Error:', e.message);
}
