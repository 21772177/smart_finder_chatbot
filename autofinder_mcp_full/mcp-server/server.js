const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();
app.use(cors());
app.use(bodyParser.json({limit: '15mb'}));
app.get('/health', (req,res) => res.json({status:'ok'}));
app.post('/tool/:name', async (req, res) => {
  const name = req.params.name;
  const toolPath = path.join(__dirname, 'tools', `${name}.js`);
  if(!fs.existsSync(toolPath)) return res.status(404).json({error: 'Tool not found'});
  try {
    const tool = require(toolPath);
    const result = await tool.run(req.body.input || {});
    res.json({ ok: true, tool: name, result });
  } catch (e) {
    console.error('Tool error', name, e);
    res.status(500).json({ ok:false, error: e.message || e.toString() });
  }
});
const PORT = process.env.PORT || 8080;
app.listen(PORT, ()=> console.log('MCP server listening on', PORT));
