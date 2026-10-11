/* planning-explainer の予備の mermaid 初期化。プロジェクトに doc-mermaid-init.js が無いときだけ、その名前で写して使う。 */
(function () {
  "use strict";
  if (typeof mermaid === "undefined") return;
  mermaid.initialize({
    startOnLoad: true,
    securityLevel: "strict",
    theme: "base",
    themeVariables: {
      fontFamily: '"Hiragino Sans", "Noto Sans JP", "Yu Gothic UI", system-ui, sans-serif',
      primaryColor: "#f3eef9",
      primaryBorderColor: "#7500c0",
      primaryTextColor: "#1f1f1f",
      lineColor: "#7500c0",
      actorBkg: "#f8f4fc",
      actorBorder: "#a055f5",
      noteBkgColor: "#fff7e6",
      noteBorderColor: "#f0b44c",
    },
  });
})();
