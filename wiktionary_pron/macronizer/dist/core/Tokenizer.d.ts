/**
 * Tokenizer.ts
 * Browser-compatible tokenizer for Latin text
 * No subprocess dependencies - pure regex implementation
 */
import { Token } from './Token';
export declare class Tokenizer {
    private static readonly WORD_BOUNDARY;
    private static readonly SENTENCE_END;
    private static readonly ABBREVIATION;
    private static readonly NUMBER;
    private static readonly PUNCTUATION;
    /**
     * Tokenize Latin text into words and punctuation
     * Handles abbreviations, numbers, and Unicode characters
     */
    tokenize(text: string): Token[];
    /**
     * Detokenize: join tokens back into text
     */
    detokenize(tokens: Token[]): string;
    /**
     * Split text into sentences
     */
    splitSentences(text: string): string[];
}
//# sourceMappingURL=Tokenizer.d.ts.map