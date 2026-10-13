const DEFAULTS = {
  enabled: true,
  hidePromoted: true,
  sortRising: true,
  dim: false,
  hideBots: true,
  botsInFeed: true,
  botsInComments: true,
  botDeepCheck: true,
  botMinAgeDays: 30,
  botMinKarma: 20,
  botScoreThreshold: 3,
  botAllowlist: [],
};
const TOGGLES = [
  "enabled",
  "hidePromoted",
  "sortRising",
  "dim",
  "hideBots",
  "botsInFeed",
  "botsInComments",
  "botDeepCheck",
];
const NUMBERS = ["botMinAgeDays", "botMinKarma", "botScoreThreshold"];

const $ = (id) => document.getElementById(id);
const countEl = $("count");
const botCountEl = $("botCount");
const listEl = $("botList");
const emptyEl = $("botEmpty");
const pendingEl = $("pending");
const clearAllowEl = $("clearAllow");
let allowlist = [];

chrome.storage.sync.get(DEFAULTS, (s) => {
  for (const k of TOGGLES) $(k).checked = !!s[k];
  for (const k of NUMBERS) $(k).value = s[k];
  allowlist = Array.isArray(s.botAllowlist) ? s.botAllowlist : [];
  clearAllowEl.hidden = allowlist.length === 0;
});

for (const k of TOGGLES) {
  $(k).addEventListener("change", () => chrome.storage.sync.set({ [k]: $(k).checked }));
}
for (const k of NUMBERS) {
  $(k).addEventListener("change", () => {
    const el = $(k);
    let v = Math.round(Number(el.value));
    if (!Number.isFinite(v)) v = DEFAULTS[k];
    v = Math.min(Number(el.max), Math.max(Number(el.min), v));
    el.value = v;
    chrome.storage.sync.set({ [k]: v });
  });
}

function notABot(name) {
  const key = name.toLowerCase();
  if (!allowlist.includes(key)) allowlist = [...allowlist, key].slice(-300);
  chrome.storage.sync.set({ botAllowlist: allowlist });
  clearAllowEl.hidden = false;
  setTimeout(refreshCount, 300);
}

clearAllowEl.addEventListener("click", () => {
  allowlist = [];
  chrome.storage.sync.set({ botAllowlist: [] });
  clearAllowEl.hidden = true;
  setTimeout(refreshCount, 300);
});

// Built with createElement/textContent only: usernames and reasons are
// treated as data, never markup.
function renderBots(bots, pending) {
  listEl.replaceChildren();
  for (const b of bots || []) {
    const li = document.createElement("li");
    const head = document.createElement("div");
    head.className = "bot-head";
    const name = document.createElement("strong");
    name.textContent = "u/" + b.name + " ";
    const score = document.createElement("small");
    score.textContent = "score " + b.score;
    name.appendChild(score);
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "link";
    btn.textContent = "Not a bot";
    btn.addEventListener("click", () => notABot(b.name));
    head.append(name, btn);
    const why = document.createElement("small");
    why.textContent = (b.reasons || []).join(" · ");
    li.append(head, why);
    listEl.appendChild(li);
  }
  emptyEl.hidden = (bots || []).length > 0;
  pendingEl.textContent = pending ? "(" + pending + " profiles still to check)" : "";
}

function refreshCount() {
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    const tab = tabs[0];
    if (!tab || !/^https:\/\/www\.reddit\.com\//.test(tab.url || "")) {
      countEl.textContent = "—";
      botCountEl.textContent = "—";
      renderBots([], 0);
      return;
    }
    chrome.tabs.sendMessage(tab.id, { type: "rrf-get-count" }, (resp) => {
      const ok = !chrome.runtime.lastError && resp;
      countEl.textContent = ok ? resp.count : "0";
      botCountEl.textContent = ok ? resp.botCount || 0 : "0";
      renderBots(ok ? resp.bots : [], ok ? resp.pending : 0);
    });
  });
}

chrome.runtime.onMessage.addListener((msg, sender) => {
  if (sender.id !== chrome.runtime.id) return; // only our own content script
  if (msg?.type === "rrf-count") {
    countEl.textContent = msg.count;
    botCountEl.textContent = msg.botCount || 0;
  }
});

refreshCount();
// Lookups trickle in while the popup is open; keep the list current.
setInterval(refreshCount, 2000);
