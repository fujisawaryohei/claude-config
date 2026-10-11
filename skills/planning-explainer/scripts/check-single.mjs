#!/usr/bin/env node
// 固めた 1 枚の HTML（bundle.mjs の出力）を、表示先と同じ条件で開けるかを確かめる。
//   - その 1 ファイルだけを空のディレクトリに写す（隣の doc.css などに頼っていないか）
//   - JavaScript を切ったブラウザで開く（Teams・メールのプレビューは JS を動かさない）
//   - <style>・<script>・<link> が 0 件か、図の SVG の数、全ページのスクショを出す
//
// 使い方（プロジェクトのディレクトリで。render-check.mjs と同じく node_modules/playwright を上へ探す）:
//   node check-single.mjs <資料名>_単一.html <スクショの出力パス> [--expect-figures N] [--playwright <index.mjs>]
//
// 出力: {"tags":0,"svg":N,"height":H,"shot":"..."}。tags が 0 でない・svg が N に足りないときは exit 1。
// スクショは、編集用の HTML のスクショ（render-check.mjs の出力）と目で見比べること。
import { copyFileSync, existsSync, mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const args = process.argv.slice(2);
const opt = (name) => {
  const i = args.indexOf(name);
  if (i < 0) return undefined;
  const [, value] = args.splice(i, 2);
  return value;
};
const expectFigures = Number(opt("--expect-figures") ?? "0");
const playwrightPath = opt("--playwright");
const [htmlArg, shotArg] = args;
if (!htmlArg || !shotArg) {
  console.error("使い方: check-single.mjs <資料名>_単一.html <スクショの出力パス> [--expect-figures N] [--playwright <index.mjs>]");
  process.exit(2);
}

function findPlaywright() {
  if (playwrightPath) return resolve(playwrightPath);
  let dir = process.cwd();
  for (;;) {
    for (const rel of ["node_modules/playwright/index.mjs", "packages/frontend/node_modules/playwright/index.mjs"]) {
      const p = join(dir, rel);
      if (existsSync(p)) return p;
    }
    const up = dirname(dir);
    if (up === dir) break;
    dir = up;
  }
  console.error("playwright が見つかりません。--playwright で index.mjs のパスを渡してください");
  process.exit(2);
}

const html = resolve(htmlArg);
const tags = (readFileSync(html, "utf8").match(/<(style|script|link)\b/gi) ?? []).length;
const isolated = join(mkdtempSync(join(tmpdir(), "single-check-")), basename(html));
copyFileSync(html, isolated);

const { chromium } = await import(pathToFileURL(findPlaywright()).href);
const browser = await chromium.launch();
try {
  const page = await browser.newPage({ javaScriptEnabled: false, viewport: { width: 1400, height: 900 } });
  await page.goto(pathToFileURL(isolated).href);
  const shot = resolve(shotArg);
  await page.screenshot({ path: shot, fullPage: true });
  const { svg, height } = await page.evaluate(() => ({ svg: document.querySelectorAll("svg").length, height: document.body.scrollHeight }));
  console.log(JSON.stringify({ tags, svg, height, shot }));
  if (tags !== 0 || svg < expectFigures) process.exit(1);
} finally {
  await browser.close();
}
