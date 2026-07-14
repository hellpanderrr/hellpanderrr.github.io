/**
 * Meters data — conversion of meters.json to TypeScript
 * Avoids JSON import compatibility issues between Node ESM and browsers
 */
declare const metersData: Record<string, Record<string, [number, string, number]>>;
export default metersData;
//# sourceMappingURL=meters.d.ts.map