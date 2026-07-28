/**
 * Tokenizer.ts
 * Browser-compatible tokenizer for Latin text
 * No subprocess dependencies - pure regex implementation
 */
import { Token } from './Token.js';
export class Tokenizer {
    /**
     * Tokenize Latin text into words and punctuation
     * Handles abbreviations, numbers, and Unicode characters
     */
    tokenize(text) {
        if (!text || text.trim().length === 0) {
            return [];
        }
        // Normalize to NFC form for consistent macron handling
        const normalized = text.normalize('NFC');
        // Split by word boundaries
        const rawTokens = normalized.split(Tokenizer.WORD_BOUNDARY)
            .filter(t => t.length > 0);
        const tokens = [];
        // Python: possiblesentenceend tracks whether the previous word was long enough
        // to credibly end a sentence. Single-char words like "M" in "M." don't trigger
        // sentence boundaries. This is critical for HMM context in Latin texts full of
        // abbreviations (M., L., P., T., Id., etc.).
        let possibleSentenceEnd = false;
        let sentenceHasEnded = true; // Start of text = start of sentence
        for (let i = 0; i < rawTokens.length; i++) {
            const rawToken = rawTokens[i];
            const isWord = /[^\W\d_]/.test(rawToken); // contains letters
            if (isWord) {
                if (sentenceHasEnded) {
                    // This word starts a new sentence
                    const token = new Token(rawToken, { originalText: rawToken, startssentence: true });
                    tokens.push(token);
                    sentenceHasEnded = false;
                }
                else {
                    tokens.push(new Token(rawToken, { originalText: rawToken }));
                }
                // Only words with len > 1 can be plausible sentence-enders
                // (matches Python: possiblesentenceend = (len(token.text) > 1))
                possibleSentenceEnd = (rawToken.length > 1);
            }
            else if (possibleSentenceEnd && /[.;:?!]/.test(rawToken)) {
                // Punctuation that ends a sentence — only after a credible word
                tokens.push(new Token(rawToken, { originalText: rawToken, endssentence: true }));
                possibleSentenceEnd = false;
                sentenceHasEnded = true;
            }
            else if (/[.;:?!]/.test(rawToken)) {
                // Punctuation after a single-char word (like "M.") — does NOT end sentence
                tokens.push(new Token(rawToken, { originalText: rawToken }));
            }
            else {
                // Whitespace or other punctuation
                tokens.push(new Token(rawToken, { originalText: rawToken }));
            }
        }
        return tokens;
    }
    /**
     * Detokenize: join tokens back into text
     */
    detokenize(tokens) {
        return tokens.map(t => t.text).join(' ');
    }
    /**
     * Split text into sentences
     */
    splitSentences(text) {
        const sentences = [];
        let currentSentence = '';
        const tokens = this.tokenize(text);
        for (let i = 0; i < tokens.length; i++) {
            const token = tokens[i];
            currentSentence += token.text;
            // Check for sentence end (set by tokenize() during punctuation handling)
            if (token.endssentence) {
                sentences.push(currentSentence.trim());
                currentSentence = '';
            }
            else if (!/[.;:?!]/.test(token.text)) {
                currentSentence += ' ';
            }
        }
        // Add remaining text
        if (currentSentence.trim().length > 0) {
            sentences.push(currentSentence.trim());
        }
        return sentences;
    }
}
// Unicode-aware regex patterns for Latin text
Object.defineProperty(Tokenizer, "WORD_BOUNDARY", {
    enumerable: true,
    configurable: true,
    writable: true,
    value: /[\s\p{P}\p{S}]+/gu
});
Object.defineProperty(Tokenizer, "SENTENCE_END", {
    enumerable: true,
    configurable: true,
    writable: true,
    value: /[.!?]+/
});
Object.defineProperty(Tokenizer, "ABBREVIATION", {
    enumerable: true,
    configurable: true,
    writable: true,
    value: /^(M|D|L|C|P|S|T|Q)\.$/i
});
Object.defineProperty(Tokenizer, "NUMBER", {
    enumerable: true,
    configurable: true,
    writable: true,
    value: /^\d+([.,]\d+)?$/
});
Object.defineProperty(Tokenizer, "PUNCTUATION", {
    enumerable: true,
    configurable: true,
    writable: true,
    value: /^[^\p{L}\p{N}]+$/u
});
//# sourceMappingURL=Tokenizer.js.map