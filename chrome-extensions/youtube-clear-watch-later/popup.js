const $ = (id) => document.getElementById(id);
const statusEl = $("status");
const clearBtn = $("clear");
const stopBtn = $("stop");
const progressWrap = $("progressWrap");
const barEl = $("bar");
const detailEl = $("detail");
const hintEl = $("hint");

let tabId = null;
let count = null; // videos in Watch Later, as last reported
let confirmTimer = null;

const fmt = (n) => (typeof n === "number" ? n.toLocaleString() : String(n));

function setStatus(main, sub, isError) {
  statusEl.textContent = "";
  statusEl.classList.toggle("error", !!isError);
  if (main != null) {
    const strong = document.createElement("strong");
    strong.textContent = main;
    statusEl.appendChild(strong);
  }
  if (sub) statusEl.appendChild(document.createTextNode(sub));
}

function send(msg) {
  return new Promise((resolve) => {
    if (tabId == null) return resolve(null);
    chrome.tabs.sendMessage(tabId, msg, (resp) => {
      resolve(chrome.runtime.lastError ? null : resp || null);
    });
  });
}

function resetConfirm() {
  clearTimeout(confirmTimer);
  confirmTimer = null;
  clearBtn.classList.remove("confirm");
  clearBtn.textContent = "Clear Watch Later";
}

function render(state) {
  if (!state) return;
  const running = state.running;
  stopBtn.hidden = !running;
  stopBtn.disabled = !!state.stopping;
  stopBtn.textContent = state.stopping ? "Stopping…" : "Stop";
  progressWrap.hidden = state.phase === "idle";
  hintEl.hidden = running;

  const total = state.total || count || 0;
  if (running) {
    clearBtn.disabled = true;
    resetConfirm();
    if (state.phase === "listing" && state.removed === 0) {
      setStatus("Reading your list…", null);
      const pct = total ? Math.min(100, (state.listed / total) * 100) : 5;
      barEl.style.width = `${pct}%`;
      detailEl.textContent = `Listed ${fmt(state.listed)}${total ? ` of ${fmt(total)}` : ""}`;
    } else {
      setStatus(`${fmt(state.removed)} removed`, total ? ` of ${fmt(total)}` : null);
      barEl.style.width = `${total ? Math.min(100, (state.removed / total) * 100) : 0}%`;
      detailEl.textContent = state.phase === "listing" ? "Checking for anything left…" : "Removing, oldest first…";
    }
    return;
  }

  const secs = state.endedAt && state.startedAt ? Math.max(1, Math.round((state.endedAt - state.startedAt) / 1000)) : 0;
  const skipped = state.failed ? `, ${fmt(state.failed)} skipped` : "";
  if (state.phase === "done") {
    setStatus(`${fmt(state.removed)} removed`, ` in ${secs}s${skipped}.`);
    barEl.style.width = "100%";
    detailEl.textContent = "Done. The Watch Later page reloads by itself.";
    count = 0;
  } else if (state.phase === "stopped") {
    setStatus(`${fmt(state.removed)} removed`, ` before you stopped it${skipped}.`);
    detailEl.textContent = "Stopped. The newest videos were kept.";
  } else if (state.phase === "error") {
    setStatus(null, `Stopped with an error after ${fmt(state.removed)} removed: ${state.error}`, true);
    detailEl.textContent = "";
  }
  clearBtn.disabled = !(typeof count === "number" ? count > 0 : !!count);
}

async function refreshCount() {
  const resp = await send({ type: "ytwl-count" });
  if (!resp) return notYouTube();
  if (!resp.ok) {
    setStatus(null, resp.error || "Couldn't read Watch Later.", true);
    clearBtn.disabled = true;
    return;
  }
  count = resp.count;
  if (resp.state && resp.state.running) return render(resp.state);
  if (count === 0) setStatus("0 videos", " in Watch Later. Nothing to clear.");
  else setStatus(`${fmt(count)} videos`, " in Watch Later.");
  clearBtn.disabled = !count;
}

function notYouTube() {
  setStatus(null, "Open YouTube in this tab (signed in), then click the icon again. If YouTube is already open, reload the tab.");
  clearBtn.disabled = true;
}

clearBtn.addEventListener("click", async () => {
  if (!confirmTimer) {
    clearBtn.classList.add("confirm");
    clearBtn.textContent = typeof count === "number" ? `Yes, remove all ${fmt(count)}` : "Yes, remove them all";
    confirmTimer = setTimeout(resetConfirm, 5000);
    return;
  }
  resetConfirm();
  clearBtn.disabled = true;
  const resp = await send({ type: "ytwl-start" });
  if (!resp) return notYouTube();
  render(resp.state);
});

stopBtn.addEventListener("click", async () => {
  const resp = await send({ type: "ytwl-stop" });
  if (resp) render(resp.state);
});

chrome.runtime.onMessage.addListener((msg, sender) => {
  if (sender.id !== chrome.runtime.id) return; // only our own content script
  if (!sender.tab || sender.tab.id !== tabId) return; // only the tab this popup is for
  if (msg && msg.type === "ytwl-progress") render(msg.state);
});

// ---- Removed list: everything removed so far, kept so it can be downloaded ----

function csvCell(s) {
  let v = String(s == null ? "" : s);
  if (/^[=+\-@\t\r]/.test(v)) v = `'${v}`; // stop spreadsheets treating titles as formulas
  return `"${v.replace(/"/g, '""')}"`;
}

function showRemovedLog(removedLog) {
  const box = $("last");
  const items = removedLog && Array.isArray(removedLog.items) ? removedLog.items : [];
  if (!items.length) {
    box.hidden = true;
    return;
  }
  box.hidden = false;
  $("lastCount").textContent = fmt(items.length);
  $("lastWhen").textContent = `since ${new Date(removedLog.since).toLocaleDateString()}`;
}

$("download").addEventListener("click", () => {
  chrome.storage.local.get("removedLog", ({ removedLog }) => {
    if (!removedLog || !Array.isArray(removedLog.items)) return;
    const rows = [["url", "title"]].concat(
      removedLog.items
        .filter((r) => /^[A-Za-z0-9_-]{11}$/.test(r.v || ""))
        .map((r) => [`https://www.youtube.com/watch?v=${r.v}`, r.t])
    );
    const csv = rows.map((r) => r.map(csvCell).join(",")).join("\r\n");
    const url = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = `watch-later-removed-${new Date(removedLog.updated || Date.now()).toISOString().slice(0, 10)}.csv`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  });
});

$("forget").addEventListener("click", () => chrome.storage.local.remove("removedLog"));

chrome.storage.local.get("removedLog", ({ removedLog }) => showRemovedLog(removedLog));
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.removedLog) showRemovedLog(changes.removedLog.newValue);
});

// ---- Start ----

chrome.tabs.query({ active: true, currentWindow: true }, async (tabs) => {
  tabId = tabs[0] ? tabs[0].id : null;
  const resp = await send({ type: "ytwl-status" });
  if (!resp) return notYouTube();
  if (resp.state && resp.state.running) {
    count = resp.state.total;
    return render(resp.state);
  }
  refreshCount();
});
