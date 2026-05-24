const mongoose = require("mongoose");

const NoticeSchema = new mongoose.Schema({
  title: String,
  content: String,
  type: String,
  className: String,
  wing: String,
});

const Notice = mongoose.models.Notice || mongoose.model("Notice", NoticeSchema, "notices");

async function run() {
  await mongoose.connect("mongodb://127.0.0.1:27017/lakshyamarch");
  const notices = await Notice.find();
  console.log("NOTICES:");
  notices.forEach(n => console.log(`- ${n.title} | class: "${n.className}" | type: ${n.type} | wing: ${n.wing}`));
  process.exit(0);
}
run();
