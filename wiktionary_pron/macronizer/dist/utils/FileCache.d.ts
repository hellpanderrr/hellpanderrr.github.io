/**
 * FileCache.ts
 * Caches large binary files (WASM, data, models) via the Cache API.
 * Enables offline-capable loading of heavy WASM resources on repeat visits.
 */
export declare class FileCache {
    private cacheName;
    private ready;
    constructor(cacheName?: string);
    private init;
    private ensureReady;
    /**
     * Check if a file is cached
     */
    has(path: string): Promise<boolean>;
    /**
     * Get cached file as Blob
     */
    getBlob(path: string): Promise<Blob | undefined>;
    /**
     * Store a file in cache
     */
    put(path: string, blobOrResponse: Blob | Response): Promise<void>;
    /**
     * Fetch and cache a file if not already cached
     */
    fetchAndCache(path: string): Promise<Blob>;
    /**
     * Get an object URL for a cached file
     */
    createObjectURL(path: string): Promise<string | undefined>;
    /**
     * Clear all cached files
     */
    clear(): Promise<void>;
    /**
     * List all cached file paths
     */
    list(): Promise<string[]>;
}
//# sourceMappingURL=FileCache.d.ts.map