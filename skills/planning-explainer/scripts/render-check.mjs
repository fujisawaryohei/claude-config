#!/usr/bin/env node
// HTML を実ブラウザで開き、mermaid の図がすべて描けたかを確かめて、全ページのスクショを撮る。
//
//   node render-check.mjs <html の絶対パス> <スクショの出力パス> [--playwright <playwright/index.mjs>] [--wait <ミリ秒>]
//
// 出力: 図ごとに {"svg": 描けたか, "err": 構文エラーの表示が出たか}。1 つでも描けていなければ exit 1。
// playwright はこのスクリプトの置き場からは解決できないことが多いので、次の順で探す:
//   --playwright の指定 → 環境変数 PLAYWRIGHT_MODULE → import("playwright") → 今のディレクトリから上へ
//   node_modules/playwright と packages/*/node_modules/playwright を探す
import { existsSync, readdirSync } from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const args = process.argv.slice(2);
const option = (name) => {
  const i = args.indexOf(name);
  if (i === -1) return undefined;
  const [, value] = args.splice(i, 2);
  return value;
};
const explicit = option("--playwright") ?? process.env.PLAYWRIGHT_MODULE;
const waitMs = Number(option("--wait") ?? 4000);
const [htmlPath, shotPath] = args;
if (!htmlPath || !shotPath) {
  console.error("使い方: node render-check.mjs <html の絶対パス> <スクショの出力パス> [--playwright <path>] [--wait <ms>]");
  process.exit(2);
}

const candidatesFrom = (start) => {
  const found = [];
  let dir = path.resolve(start);
  for (;;) {
    found.push(path.join(dir, "node_modules/playwright/index.mjs"));
    const packages = path.join(dir, "packages");
    if (existsSync(packages)) {
      for (const name of readdirSync(packages)) found.push(path.join(packages, name, "node_modules/playwright/index.mjs"));
    }
    const parent = path.dirname(dir);
    if (parent === dir) return found;
    dir = parent;
  }
};

const loadPlaywright = async () => {
  if (explicit) return import(pathToFileURL(path.resolve(explicit)).href);
  try {
    return await import("playwright");
  } catch {
    const hit = candidatesFrom(process.cwd()).find((p) => existsSync(p));
    if (!hit) {
      console.error("playwright が見つかりません。--playwright <…/node_modules/playwright/index.mjs> で場所を渡してください");
      process.exit(2);
    }
    return import(pathToFileURL(hit).href);
  }
};

const { chromium } = await loadPlaywright();
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1500, height: 1000 } });
await page.goto(pathToFileURL(path.resolve(htmlPath)).href);
await page.waitForTimeout(waitMs);
const figures = await page.evaluate(() =>
  [...document.querySelectorAll("pre.mermaid")].map((el) => ({
    svg: el.querySelector("svg") !== null,
    err: /Syntax error|Parse error/i.test(el.textContent ?? ""),
  }))
);
await page.screenshot({ path: shotPath, fullPage: true });
await browser.close();

console.log(JSON.stringify(figures));
const broken = figures.filter((f) => !f.svg || f.err).length;
if (figures.length === 0) console.error("mermaid の図が 1 つもありません");
if (broken > 0) console.error(`描けていない図が ${broken} 個あります`);
process.exit(broken > 0 || figures.length === 0 ? 1 : 0);
