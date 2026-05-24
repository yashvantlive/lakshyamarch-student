const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

const MONGODB_URI = "mongodb://lakshyamarchbegusarai_db_user:gg1ixpUrdlcywx9B@ac-kxpw8n2-shard-00-00.fcbaunk.mongodb.net:27017,ac-kxpw8n2-shard-00-01.fcbaunk.mongodb.net:27017,ac-kxpw8n2-shard-00-02.fcbaunk.mongodb.net:27017/lakshyamarch?authSource=admin&replicaSet=atlas-y91vr3-shard-0&tls=true";

const DATA_DIR = "C:/Users/IT CARE/Desktop/lakshyamarch-student/lib/data";

async function migrate() {
  await mongoose.connect(MONGODB_URI);
  console.log("Connected to MongoDB");

  const ClassMaster = mongoose.model('ClassMaster', new mongoose.Schema({ name: String, wing: String, isActive: { type: Boolean, default: true } }, { collection: 'class_master' }));
  const SubjectMaster = mongoose.model('SubjectMaster', new mongoose.Schema({ name: String, code: String }, { collection: 'subject_master' }));
  const StudyMaterial = mongoose.model('StudyMaterial', new mongoose.Schema({
    classId: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassMaster' },
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'SubjectMaster' },
    bookName: String,
    type: String,
    fullBookPdf: String,
    chapters: [{ chapterNo: Number, chapterName: String, pdfLink: String }]
  }, { collection: 'studymaterials', timestamps: true }));

  // Clear existing to avoid duplicates during re-run
  await StudyMaterial.deleteMany({});
  console.log("Cleared existing study materials");

  const classes = await ClassMaster.find();
  const subjects = await SubjectMaster.find();

  const files = fs.readdirSync(DATA_DIR).filter(f => f.endsWith('.json'));

  for (const file of files) {
    if (file === 'study_hub_meta.json') continue;

    console.log(`Processing ${file}...`);
    const parts = file.replace('.json', '').split('_');
    const classNameRaw = parts[0]; 
    const type = parts[1]; 

    const classNum = classNameRaw.replace('class', '');
    const dbClassName = `Class ${classNum}`;
    let targetClass = classes.find(c => c.name === dbClassName && c.wing === 'school');

    if (!targetClass) {
      console.warn(`Class not found for ${dbClassName}. Creating new school class...`);
      targetClass = await ClassMaster.create({ name: dbClassName, wing: 'school' });
      classes.push(targetClass);
    }

    const data = JSON.parse(fs.readFileSync(path.join(DATA_DIR, file), 'utf8'));

    for (const subjectName in data) {
      let targetSubject = subjects.find(s => s.name.toLowerCase().includes(subjectName.toLowerCase()) || subjectName.toLowerCase().includes(s.name.toLowerCase()));
      
      if (!targetSubject) {
        if (subjectName.includes("Social Science")) targetSubject = subjects.find(s => s.code === 'SST');
        else if (subjectName.includes("Mathematics")) targetSubject = subjects.find(s => s.code === 'MTH');
        else if (subjectName.includes("Science")) targetSubject = subjects.find(s => s.name === 'Science' || s.code === 'SCI');
      }

      if (!targetSubject) {
        console.warn(`Subject not found for ${subjectName}. Creating new...`);
        const code = subjectName.substring(0, 3).toUpperCase();
        targetSubject = await SubjectMaster.create({ name: subjectName, code: code });
        subjects.push(targetSubject);
      }

      const bookData = data[subjectName];
      
      await StudyMaterial.create({
        classId: targetClass._id,
        subjectId: targetSubject._id,
        bookName: subjectName,
        type: type,
        fullBookPdf: bookData.full_book_pdf,
        chapters: (bookData.chapters || []).map(ch => ({
          chapterNo: ch.chapter_no,
          chapterName: ch.chapter_name,
          pdfLink: ch.pdf_link
        }))
      });
      console.log(`  Imported ${subjectName} for ${targetClass.name}`);
    }
  }

  console.log("Migration complete!");
  await mongoose.disconnect();
}

migrate().catch(console.error);
