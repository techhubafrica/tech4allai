const fs = require("fs");
const path = require("path");

const buildId =
  process.env.VERCEL_GIT_COMMIT_SHA ||
  process.env.VERCEL_DEPLOYMENT_ID ||
  Date.now().toString();

const output = {
  buildId,
  generatedAt: new Date().toISOString()
};

const target = path.join(process.cwd(), "web", "version.json");

fs.writeFileSync(
  target,
  JSON.stringify(output, null, 2),
  "utf8"
);

console.log(`Generated Flutter web build ID: ${buildId}`);
