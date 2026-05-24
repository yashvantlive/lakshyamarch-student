const mongoose = require('mongoose');

const MONGODB_URI = "mongodb://lakshyamarchbegusarai_db_user:gg1ixpUrdlcywx9B@ac-kxpw8n2-shard-00-00.fcbaunk.mongodb.net:27017,ac-kxpw8n2-shard-00-01.fcbaunk.mongodb.net:27017,ac-kxpw8n2-shard-00-02.fcbaunk.mongodb.net:27017/lakshyamarch?authSource=admin&replicaSet=atlas-y91vr3-shard-0&tls=true";

async function listClasses() {
  await mongoose.connect(MONGODB_URI);
  console.log("Connected to MongoDB");
  
  const ClassMaster = mongoose.model('ClassMaster', new mongoose.Schema({ name: String, wing: String }, { collection: 'class_master' }));
  const SubjectMaster = mongoose.model('SubjectMaster', new mongoose.Schema({ name: String, code: String }, { collection: 'subject_master' }));
  
  const classes = await ClassMaster.find();
  const subjects = await SubjectMaster.find();
  
  console.log("CLASSES:");
  classes.forEach(c => console.log(`- ${c.name} (${c.wing}) [${c._id}]`));
  
  console.log("\nSUBJECTS:");
  subjects.forEach(s => console.log(`- ${s.name} (${s.code}) [${s._id}]`));
  
  await mongoose.disconnect();
}

listClasses();
