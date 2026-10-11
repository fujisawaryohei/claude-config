#!/usr/bin/env node
// 編集用の HTML（隣の doc.css と mermaid を読む）を、どこで開いても同じ見た目になる 1 枚に固める。
//
//   node bundle.mjs <編集用 HTML の絶対パス> <1 枚の HTML の出力パス> [--pdf <PDF の出力パス>] [--playwright <playwright/index.mjs>]
//
// やること:
//   1. 実ブラウザ（Chromium）で開き、mermaid の図を描き切るまで待つ
//   2. 全要素（図の SVG の中も）の見た目を、既定値と違うものだけ style 属性に書き込む
//   3. <style>・<script>・<link rel="stylesheet"> を全部外す（図は描いた後の SVG のまま残る）
//   4. --pdf があれば、描いた状態を背景ごと 1 ページの PDF に書き出す
//
// なぜ: Teams・SharePoint のプレビューやメールは、HTML の <style> と <script> を取り除く。CSS を <style> で
// 埋め込んだだけの 1 枚では、そこでスタイルが外れ、mermaid の図も描かれない。style 属性と描いた後の SVG だけに
// しておけば、取り除かれる物が無い。それでも崩す表示先には PDF を渡す。
import { existsSync, readdirSync, writeFileSync } from "node:fs";
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
const pdfPath = option("--pdf");
const [inPath, outPath] = args;
if (!inPath || !outPath) {
  console.error("使い方: node bundle.mjs <編集用 HTML> <1 枚の HTML の出力> [--pdf <PDF の出力>] [--playwright <path>]");
  process.exit(2);
}

const candidatesFrom = (start) => {
  const found = [];
  let dir = path.resolve(start);
  for (;;) {
    found.push(path.join(dir, "node_modules/playwright/index.mjs"));
    const packages = path.join(dir, "packages");
    if (existsSync(packages)) for (const n of readdirSync(packages)) found.push(path.join(packages, n, "node_modules/playwright/index.mjs"));
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
await page.goto(pathToFileURL(path.resolve(inPath)).href);
// 図が全部描けるまで待つ（CDN の読み込みを含む）
await page.waitForFunction(
  () => [...document.querySelectorAll("pre.mermaid")].every((el) => el.querySelector("svg") || /Syntax error|Parse error/i.test(el.textContent ?? "")),
  null,
  { timeout: 30000 }
);
await page.evaluate(() => document.fonts?.ready);

const figures = await page.evaluate(() =>
  [...document.querySelectorAll("pre.mermaid")].map((el) => ({ svg: el.querySelector("svg") !== null, err: /Syntax error|Parse error/i.test(el.textContent ?? "") }))
);
if (figures.some((f) => !f.svg || f.err)) {
  console.error(`描けていない図があります: ${JSON.stringify(figures)}`);
  await browser.close();
  process.exit(1);
}

if (pdfPath) {
  const height = await page.evaluate(() => document.documentElement.scrollHeight);
  await page.emulateMedia({ media: "screen" });
  await page.pdf({ path: pdfPath, width: "1500px", height: `${height + 40}px`, printBackground: true, margin: { top: "0", bottom: "0", left: "0", right: "0" } });
}

const html = await page.evaluate(() => {
  // 見た目に効く性質だけを写す（全部写すとファイルが膨らむ）。SVG の描画に効く性質も含める
  const PROPS = [
    "display", "position", "top", "right", "bottom", "left", "float", "clear", "box-sizing",
    "width", "min-width", "max-width", "height", "min-height", "max-height",
    "margin-top", "margin-right", "margin-bottom", "margin-left",
    "padding-top", "padding-right", "padding-bottom", "padding-left",
    "border-top-width", "border-right-width", "border-bottom-width", "border-left-width",
    "border-top-style", "border-right-style", "border-bottom-style", "border-left-style",
    "border-top-color", "border-right-color", "border-bottom-color", "border-left-color",
    "border-top-left-radius", "border-top-right-radius", "border-bottom-left-radius", "border-bottom-right-radius",
    "border-collapse", "border-spacing",
    "color", "background-color", "background-image", "box-shadow", "opacity",
    "font-family", "font-size", "font-weight", "font-style", "line-height", "letter-spacing",
    "text-align", "text-decoration-line", "text-transform", "white-space", "word-break", "overflow-wrap", "vertical-align",
    "list-style-type", "list-style-position",
    "flex-direction", "flex-wrap", "justify-content", "align-items", "align-self", "flex-grow", "flex-shrink", "flex-basis", "gap", "row-gap", "column-gap",
    "grid-template-columns", "grid-template-rows", "grid-column", "grid-row",
    "overflow-x", "overflow-y", "table-layout",
    "fill", "fill-opacity", "stroke", "stroke-width", "stroke-dasharray", "stroke-opacity", "stroke-linecap", "stroke-linejoin",
    "text-anchor", "dominant-baseline", "alignment-baseline", "marker-end", "marker-start",
    "font-feature-settings", "text-rendering", "-webkit-font-smoothing", "text-wrap-style", "tab-size",
  ];
  // 親から受け継ぐ性質。これは既定値ではなく親の値と比べる（既定値と比べると、親に書いた値が子に受け継がれて、
  // 子が元は既定値〔例: 文字の縁取りなし〕だったのに親の値で描かれてしまう）
  const INHERITED = new Set([
    "color", "font-family", "font-size", "font-weight", "font-style", "line-height", "letter-spacing",
    "text-align", "text-transform", "white-space", "word-break", "overflow-wrap", "list-style-type", "list-style-position",
    "border-collapse", "border-spacing",
    "fill", "fill-opacity", "stroke", "stroke-width", "stroke-dasharray", "stroke-opacity", "stroke-linecap", "stroke-linejoin",
    "text-anchor", "dominant-baseline", "marker-end", "marker-start",
    "font-feature-settings", "text-rendering", "-webkit-font-smoothing", "text-wrap-style", "tab-size",
  ]);
  // 既定値は、スタイルの無い別の文書で同じ要素を作って測る
  const frame = document.createElement("iframe");
  frame.style.display = "none";
  document.body.appendChild(frame);
  const blank = frame.contentDocument;
  blank.open();
  blank.write("<!DOCTYPE html><html><body><svg xmlns='http://www.w3.org/2000/svg'></svg></body></html>");
  blank.close();
  const blankSvg = blank.querySelector("svg");
  const defaults = new Map();
  const defaultsOf = (el) => {
    const key = `${el.namespaceURI}|${el.localName}`;
    if (!defaults.has(key)) {
      const probe = el.namespaceURI === "http://www.w3.org/2000/svg" ? blank.createElementNS(el.namespaceURI, el.localName) : blank.createElement(el.localName);
      (el.namespaceURI === "http://www.w3.org/2000/svg" ? blankSvg : blank.body).appendChild(probe);
      const cs = frame.contentWindow.getComputedStyle(probe);
      defaults.set(key, Object.fromEntries(PROPS.map((p) => [p, cs.getPropertyValue(p)])));
    }
    return defaults.get(key);
  };
  const all = [document.documentElement, ...document.querySelectorAll("body, body *")].filter((el) => el !== frame);
  const SIDES = ["top", "right", "bottom", "left"];
  const styles = all.map((el) => {
    const cs = getComputedStyle(el);
    const base = defaultsOf(el);
    const parent = el.parentElement ? getComputedStyle(el.parentElement) : null;
    const reference = (p) => (INHERITED.has(p) && parent ? parent.getPropertyValue(p) : base[p]);
    const picked = new Set(PROPS.filter((p) => cs.getPropertyValue(p) !== reference(p) && cs.getPropertyValue(p) !== ""));
    // HTML の要素は、計算済みの幅・高さ（px）を書かない。表示先で文字の幅が少し違うだけで、決め打ちの高さから
    // はみ出して重なるため。幅・高さはブラウザに任せ、max-width など CSS で決めていた上限だけを残す。
    // SVG の中（図）は描いた寸法がそのまま正しいので残す
    if (el.namespaceURI !== "http://www.w3.org/2000/svg" && el.localName !== "svg") {
      for (const p of ["width", "height", "min-height"]) picked.delete(p);
    }
    // 枠線は 3 つで 1 組。リセットの CSS は全要素に「実線・太さ 0」を当てるので、種類だけが既定と違って写り、
    // 太さ 0 が既定と同じとして落ちると、太さの既定（medium）の黒い枠になる。種類が none 以外なら 3 つとも書く
    for (const side of SIDES) {
      if (cs.getPropertyValue(`border-${side}-style`) === "none") {
        for (const part of ["width", "style", "color"]) picked.delete(`border-${side}-${part}`);
      } else {
        for (const part of ["width", "style", "color"]) picked.add(`border-${side}-${part}`);
      }
    }
    return [...picked].map((p) => `${p}:${cs.getPropertyValue(p)}`).join(";");
  });
  // 測り終えてから書き込む（書き込みながら測ると、後の要素の値が変わる）
  all.forEach((el, i) => {
    const own = el.getAttribute("style");
    const merged = [styles[i], own].filter(Boolean).join(";");
    if (merged) el.setAttribute("style", merged);
    el.removeAttribute("class");
  });
  frame.remove();
  document.querySelectorAll("style, script, link[rel='stylesheet'], link[rel='preload']").forEach((el) => el.remove());
  return `<!DOCTYPE html>\n${document.documentElement.outerHTML}`;
});
await browser.close();
writeFileSync(outPath, html);
console.log(JSON.stringify({ figures: figures.length, out: outPath, bytes: Buffer.byteLength(html), pdf: pdfPath ?? null }));
