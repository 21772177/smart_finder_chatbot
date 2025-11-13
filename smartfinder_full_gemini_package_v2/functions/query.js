
const { GoogleGenerativeAI } = require("@google/generative-ai");
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

exports.queryHandler = async (body) => {
  const { text } = body;
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
  const prompt = `You are SmartFinder AI. Parse this user query into structured JSON.
User text: "${text}"
Reply JSON only:
{
  "intent": "one of [nearby_search, recall_visit, reel_search, video_search, general]",
  "type": "category (like restaurant, petrol pump, cafe, etc.)",
  "location": "if mentioned place or city",
  "reply": "brief text reply for user"
}`; 
  const result = await model.generateContent(prompt);
  const textRes = result.response.text();
  const start = textRes.indexOf("{");
  const end = textRes.lastIndexOf("}") + 1;
  const json = JSON.parse(textRes.slice(start, end));
  return json;
};
