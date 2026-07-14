/**
 * assets.ts
 * Resolves heavy WASM/model/data assets against a host-page prefetch cache.
 *
 * The host page may prefetch the big files (wasm, .data, .model) into the Cache API
 * and publish blob URLs on `window.__fileCacheUrls`, keyed by bare filename. The
 * engines must consult that map, otherwise Emscripten's locateFile — and our own
 * model fetch — pull each file over the network a SECOND time.
 */
/**
 * Return the prefetched blob URL for an asset if the host page has one,
 * otherwise `fallback`. `pathOrUrl` may be a bare filename ("cruncher.data")
 * or a full path ("/wasm/cruncher.data"); only the basename is matched.
 */
export function resolveAssetUrl(pathOrUrl, fallback) {
    if (typeof window === 'undefined')
        return fallback;
    const cacheUrls = window.__fileCacheUrls;
    if (!cacheUrls)
        return fallback;
    const basename = pathOrUrl.split('/').pop() || pathOrUrl;
    return cacheUrls[basename] || fallback;
}
/** gzip magic number: every gzip member starts with 0x1f 0x8b. */
function looksGzipped(bytes) {
    return bytes.length > 1 && bytes[0] === 0x1f && bytes[1] === 0x8b;
}
export function canGunzip() {
    return typeof DecompressionStream === 'function';
}
/**
 * Fetch a possibly-gzipped asset and return its *decompressed* bytes.
 *
 * Only decompresses when the payload actually starts with the gzip magic number:
 * a server may serve a .gz file with `Content-Encoding: gzip`, in which case the
 * browser has already decompressed it for us and gunzipping again would fail.
 *
 * Falls back to `fallbackUrl` (the uncompressed file) when the .gz is missing or
 * the browser has no DecompressionStream.
 */
export async function fetchMaybeGzipped(url, fallbackUrl) {
    let response = null;
    try {
        response = await fetch(url);
    }
    catch (_a) {
        response = null;
    }
    const gzUnusable = !response || !response.ok || (url.endsWith('.gz') && !canGunzip());
    if (gzUnusable) {
        if (!fallbackUrl) {
            throw new Error(`Failed to load ${url} (${response ? response.status : 'network error'})`);
        }
        const plain = await fetch(fallbackUrl);
        if (!plain.ok)
            throw new Error(`Failed to load ${fallbackUrl}: ${plain.status}`);
        return new Uint8Array(await plain.arrayBuffer());
    }
    const raw = new Uint8Array(await response.arrayBuffer());
    if (!looksGzipped(raw))
        return raw; // server already decoded it (Content-Encoding: gzip)
    const stream = new Blob([raw]).stream().pipeThrough(new DecompressionStream('gzip'));
    return new Uint8Array(await new Response(stream).arrayBuffer());
}
//# sourceMappingURL=assets.js.map
