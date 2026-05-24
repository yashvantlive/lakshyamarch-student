const mongoose = require('mongoose');
const mongoUrl = 'mongodb://127.0.0.1:27017/lakshyamarch';

async function cleanup() {
  try {
    await mongoose.connect(mongoUrl);
    console.log('Connected to DB');
    const db = mongoose.connection.db;
    const today = '2026-05-07';

    const homeworks = await db.collection('homeworks').find({ 
      subject: /Biology/i, 
      date: today 
    }).toArray();

    if (homeworks.length > 0) {
      const hwIds = homeworks.map(h => h._id);
      await db.collection('homeworks').deleteMany({ _id: { $in: hwIds } });
      await db.collection('homeworksubmissions').deleteMany({ homeworkId: { $in: hwIds } });
      console.log(`Successfully deleted ${hwIds.length} homework records and their submissions.`);
    } else {
      console.log('No matching Biology homework found for today.');
    }
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await mongoose.disconnect();
    process.exit();
  }
}

cleanup();
