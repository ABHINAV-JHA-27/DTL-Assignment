import { chromium } from "playwright";

const baseUrl = process.env.APP_URL ?? "http://localhost:3000";
const viewports = [
  { name: "mobile", width: 390, height: 844 },
  { name: "tablet", width: 768, height: 1024 },
  { name: "laptop", width: 1024, height: 768 },
  { name: "desktop", width: 1440, height: 900 },
];

function summarizeOverflow() {
  const nodes = Array.from(document.querySelectorAll("body *"));
  const offenders = nodes
    .map((node) => {
      const rect = node.getBoundingClientRect();
      const overflowAmount = Math.max(
        rect.right - window.innerWidth,
        Math.abs(Math.min(rect.left, 0)),
      );

      if (overflowAmount <= 1) {
        return null;
      }

      return {
        tag: node.tagName,
        className: node.className,
        text: (node.textContent || "").trim().slice(0, 80),
        left: Math.round(rect.left),
        right: Math.round(rect.right),
        width: Math.round(rect.width),
      };
    })
    .filter(Boolean)
    .slice(0, 8);

  return {
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
    hasHorizontalOverflow:
      document.documentElement.scrollWidth - document.documentElement.clientWidth >
      1,
    offenders,
  };
}

async function collectState(page, label) {
  const summary = await page.evaluate(summarizeOverflow);
  return { label, ...summary };
}

const browser = await chromium.launch({
  headless: true,
  args: [
    "--use-fake-ui-for-media-stream",
    "--use-fake-device-for-media-stream",
  ],
});

const results = [];

for (const viewport of viewports) {
  const context = await browser.newContext({
    viewport,
    permissions: ["camera", "microphone"],
  });
  const page = await context.newPage();

  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await page.locator('input[placeholder="Add your display name"]').fill(
    `Tester ${viewport.name}`,
  );
  results.push(await collectState(page, `${viewport.name}:landing`));

  await page.getByRole("button", { name: "Create Meeting" }).click();
  await page.waitForURL(/\/meet\//, { timeout: 20000 });
  await page.waitForTimeout(3000);
  results.push(await collectState(page, `${viewport.name}:meeting`));

  await context.close();
}

await browser.close();

console.log(JSON.stringify(results, null, 2));
