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
export declare function resolveAssetUrl(pathOrUrl: string, fallback: string): string;
export declare function canGunzip(): boolean;
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
export declare function fetchMaybeGzipped(url: string, fallbackUrl?: string): Promise<Uint8Array>;
//# sourceMappingURL=assets.d.ts.map