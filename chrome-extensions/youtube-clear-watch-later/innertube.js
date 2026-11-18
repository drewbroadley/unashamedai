/*
 * Talking to YouTube's own web API ("InnerTube") for the Watch Later playlist.
 * --------------------------------------------------------------------------
 * YouTube's "Remove from Watch later" menu item POSTs to
 * /youtubei/v1/browse/edit_playlist with an *array* of actions, one per video.
 * The web UI only ever sends one, but the endpoint accepts many, so a whole
 * page of the playlist can be removed in a single request.
 *
 * Everything here is either a pure function (unit-tested in Node by
 * tests/youtube-watch-later.test.mjs) or takes its I/O (fetch, cookies,
 * SHA-1) as arguments, so nothing in this file touches the network or the
 * page by itself.
 *
 * Exposed as globalThis.YTWatchLater (content scripts share one global).
 */
(function (root) {
  "use strict";

  const PLAYLIST_ID = "WL";
  // Browse id of the Watch Later page. The params ask YouTube to include
  // videos it would normally hide as "unavailable" (deleted or private),
  // which still count against the playlist and should be cleared too.
  const BROWSE_ID = "VLWL";
  const SHOW_UNAVAILABLE_PARAMS = "wgYCCAA%3D";

  // A setVideoId identifies one *entry* in a playlist (not the video itself).
  // YouTube issues them as 16 upper-case hex characters.
  const SET_VIDEO_ID_RE = /^[0-9A-F]{16}$/;

  /** Find the object passed to `ytcfg.set({...})` in YouTube's inline script. */
  function extractYtcfgObject(text) {
    const marker = "ytcfg.set({";
    let from = 0;
    while (true) {
      const at = text.indexOf(marker, from);
      if (at < 0) return null;
      const start = at + marker.length - 1; // the "{"
      const end = matchBrace(text, start);
      if (end > start) {
        try {
          const obj = JSON.parse(text.slice(start, end + 1));
          if (obj && typeof obj === "object" && obj.INNERTUBE_CONTEXT) return obj;
        } catch {
          // not strict JSON (YouTube has a few tiny ytcfg.set calls with
          // single quotes); keep looking for the big one
        }
      }
      from = at + marker.length;
    }
  }

  /** Index of the "}" that closes the "{" at `start`, honouring JSON strings. */
  function matchBrace(text, start) {
    let depth = 0;
    let inStr = false;
    for (let i = start; i < text.length; i++) {
      const c = text[i];
      if (inStr) {
        if (c === "\\") i++;
        else if (c === '"') inStr = false;
      } else if (c === '"') inStr = true;
      else if (c === "{") depth++;
      else if (c === "}" && --depth === 0) return i;
    }
    return -1;
  }

  /**
   * The handful of page settings the API calls need, from the texts of the
   * page's inline <script> tags. Returns null when they can't be found.
   */
  function parseYtcfg(scriptTexts) {
    for (const t of scriptTexts) {
      if (!t || t.indexOf("INNERTUBE_CONTEXT") < 0) continue;
      const cfg = extractYtcfgObject(t);
      if (!cfg) continue;
      const context = cfg.INNERTUBE_CONTEXT;
      if (!context || !context.client || !context.client.clientVersion) continue;
      return {
        context,
        clientName: String(cfg.INNERTUBE_CONTEXT_CLIENT_NAME || 1),
        clientVersion: String(context.client.clientVersion),
        sessionIndex: cfg.SESSION_INDEX != null ? String(cfg.SESSION_INDEX) : "0",
        delegatedSessionId: cfg.DELEGATED_SESSION_ID ? String(cfg.DELEGATED_SESSION_ID) : "",
        loggedIn: cfg.LOGGED_IN === true,
      };
    }
    return null;
  }

  function readCookie(cookieString, name) {
    for (const part of String(cookieString || "").split(";")) {
      const eq = part.indexOf("=");
      if (eq < 0) continue;
      if (part.slice(0, eq).trim() === name) return part.slice(eq + 1).trim();
    }
    return "";
  }

  /**
   * The Authorization header YouTube's own page sends:
   * "SAPISIDHASH <ts>_<sha1(ts SAPISID origin)>", plus the 1P/3P variants when
   * those cookies exist. Without it the API treats the request as logged out.
   * `sha1Hex(string) -> Promise<hex>` is injected so this stays testable.
   */
  async function authHeader(cookieString, origin, tsSec, sha1Hex) {
    const pairs = [
      ["SAPISID", "SAPISIDHASH"],
      ["__Secure-1PAPISID", "SAPISID1PHASH"],
      ["__Secure-3PAPISID", "SAPISID3PHASH"],
    ];
    const parts = [];
    for (const [cookie, label] of pairs) {
      const v = readCookie(cookieString, cookie);
      if (v) parts.push(`${label} ${tsSec}_${await sha1Hex(`${tsSec} ${v} ${origin}`)}`);
    }
    return parts.join(" ");
  }

  /** Depth-first walk collecting every value stored under `key`. */
  function collect(node, key, out, depth) {
    if (!node || typeof node !== "object" || depth > 60) return out;
    if (Array.isArray(node)) {
      for (const v of node) collect(v, key, out, depth + 1);
      return out;
    }
    for (const k of Object.keys(node)) {
      const v = node[k];
      if (k === key) out.push(v);
      else collect(v, key, out, depth + 1);
    }
    return out;
  }

  function text(t) {
    if (!t) return "";
    if (typeof t.simpleText === "string") return t.simpleText;
    if (Array.isArray(t.runs)) return t.runs.map((r) => r.text || "").join("");
    if (typeof t.content === "string") return t.content;
    return "";
  }

  /**
   * One page of the playlist from a browse response (first page or a
   * continuation): the entries, the token for the next page (or ""), and the
   * playlist's own video count when the response carries the header.
   */
  function extractPage(json) {
    const items = [];
    const seen = new Set();
    for (const r of collect(json, "playlistVideoRenderer", [], 0)) {
      const id = r && r.setVideoId;
      if (!SET_VIDEO_ID_RE.test(id || "") || seen.has(id)) continue;
      seen.add(id);
      items.push({ setVideoId: id, videoId: String(r.videoId || ""), title: text(r.title) });
    }
    let continuation = "";
    for (const c of collect(json, "continuationItemRenderer", [], 0)) {
      const tok = collect(c, "continuationCommand", [], 0)[0];
      if (tok && typeof tok.token === "string") {
        continuation = tok.token;
        break;
      }
    }
    return { items, continuation, total: headerCount(json) };
  }

  /** "4,681 videos" from the playlist header, as a number; null if absent. */
  function headerCount(json) {
    const candidates = []
      .concat(collect(json, "numVideosText", [], 0).map(text))
      .concat(collect(json, "playlistHeaderRenderer", [], 0).map((h) => text(h && h.numVideosText)))
      .concat(
        collect(json, "metadataParts", [], 0)
          .flat()
          .map((p) => text(p && p.text))
      );
    for (const s of candidates) {
      const m = /([\d][\d,.\s ]*)\s*video/i.exec(s || "");
      if (m) {
        const n = parseInt(m[1].replace(/[^\d]/g, ""), 10);
        if (Number.isFinite(n)) return n;
      }
    }
    return null;
  }

  /** The API answers logged-out requests with 200 and empty results; spot that. */
  function isLoggedOut(json) {
    for (const svc of collect(json, "serviceTrackingParams", [], 0).flat()) {
      for (const p of (svc && svc.params) || []) {
        if ((p.key === "logged_in" || p.key === "yt_li") && p.value === "0") return true;
      }
    }
    return false;
  }

  function editSucceeded(json) {
    return !!json && json.status === "STATUS_SUCCEEDED";
  }

  function chunk(arr, size) {
    const out = [];
    for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
    return out;
  }

  function removeBody(context, setVideoIds) {
    return {
      context,
      playlistId: PLAYLIST_ID,
      actions: setVideoIds.map((setVideoId) => ({ action: "ACTION_REMOVE_VIDEO", setVideoId })),
    };
  }

  class ApiError extends Error {
    constructor(message, status, kind) {
      super(message);
      this.status = status;
      this.kind = kind; // "logged-out" | "rate-limited" | "bad-request" | "server" | "network"
    }
  }

  /**
   * A tiny client bound to one page's settings. All I/O is injected:
   *   fetch(url, init) -> Response       (the content script's own fetch)
   *   getCookies() -> string             (document.cookie, read per request)
   *   sha1Hex(string) -> Promise<string> (crypto.subtle)
   *   now() -> ms                        (Date.now)
   */
  function createClient({ cfg, origin, fetch, getCookies, sha1Hex, now }) {
    async function post(path, body) {
      const headers = {
        "Content-Type": "application/json",
        "X-Origin": origin,
        "X-Goog-AuthUser": cfg.sessionIndex,
        "X-Youtube-Client-Name": cfg.clientName,
        "X-Youtube-Client-Version": cfg.clientVersion,
      };
      if (cfg.delegatedSessionId) headers["X-Goog-PageId"] = cfg.delegatedSessionId;
      const auth = await authHeader(getCookies(), origin, Math.floor(now() / 1000), sha1Hex);
      if (!auth) throw new ApiError("Not signed in to YouTube in this tab.", 0, "logged-out");
      headers.Authorization = auth;

      let res;
      try {
        res = await fetch(`${origin}${path}?prettyPrint=false`, {
          method: "POST",
          credentials: "same-origin",
          headers,
          body: JSON.stringify(body),
        });
      } catch (e) {
        throw new ApiError(`Network error: ${e && e.message}`, 0, "network");
      }
      let json = null;
      try {
        json = await res.json();
      } catch {
        json = null;
      }
      if (res.status === 429) throw new ApiError("YouTube is rate limiting.", 429, "rate-limited");
      if (res.status === 401 || res.status === 403)
        throw new ApiError("YouTube refused the request (signed out?).", res.status, "logged-out");
      if (res.status >= 500) throw new ApiError(`YouTube error ${res.status}.`, res.status, "server");
      if (res.status >= 400) throw new ApiError(`YouTube rejected the request (${res.status}).`, res.status, "bad-request");
      if (!json || typeof json !== "object") throw new ApiError("Unreadable response from YouTube.", res.status, "server");
      if (isLoggedOut(json)) throw new ApiError("YouTube treated the request as signed out.", res.status, "logged-out");
      return json;
    }

    async function firstPage() {
      return extractPage(
        await post("/youtubei/v1/browse", { context: cfg.context, browseId: BROWSE_ID, params: SHOW_UNAVAILABLE_PARAMS })
      );
    }

    async function nextPage(token) {
      return extractPage(await post("/youtubei/v1/browse", { context: cfg.context, continuation: token }));
    }

    async function removeEntries(setVideoIds) {
      const ids = setVideoIds.filter((id) => SET_VIDEO_ID_RE.test(id));
      if (!ids.length) return;
      const json = await post("/youtubei/v1/browse/edit_playlist", removeBody(cfg.context, ids));
      if (!editSucceeded(json)) throw new ApiError("YouTube did not confirm the removal.", 200, "bad-request");
    }

    return { firstPage, nextPage, removeEntries };
  }

  root.YTWatchLater = {
    PLAYLIST_ID,
    BROWSE_ID,
    SHOW_UNAVAILABLE_PARAMS,
    SET_VIDEO_ID_RE,
    extractYtcfgObject,
    parseYtcfg,
    readCookie,
    authHeader,
    extractPage,
    headerCount,
    isLoggedOut,
    editSucceeded,
    removeBody,
    chunk,
    ApiError,
    createClient,
  };
})(globalThis);
