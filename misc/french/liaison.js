function insertLiaisonMarkers(text) {
    if (!text || typeof text !== 'string') {
        return {text: text || '', liaisons: [], omissions: []};
    }

    const doc = frCompromise(text);
    const terms = doc.terms().document.flat();
    const result = [];
    const liaisons = [];
    const omissions = [];

    const normalize = (str) => str.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

    // ==========================================
    // 1. DEFINITIONS & LISTS
    // ==========================================

    const VOWELS = /^[aeiouyàâéèêëîïôùûüœæh]/i;
    const LIAISON_CONSONANTS = /[szxtdnprgf]$/i;
    // Used to detect invariant nouns (e.g., "Le temps")
    const SINGULAR_DETERMINERS = new Set([
        'le', 'la', 'l', 'un', 'une', 'ce', 'cet', 'cette',
        'mon', 'ton', 'son', 'notre', 'votre', 'leur', 'chaque'
    ]);
    const PLURAL_DETERMINERS = new Set([
        'les', 'des', 'ces', 'mes', 'tes', 'ses', 'nos', 'vos', 'leurs', 'aux',
        'quelques', 'plusieurs', 'certains', 'différents', 'divers',
        'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix'
    ]);
    // --- DICTIONARY FOR PRECISE USER FEEDBACK ---
    const WORD_SPECIFIC_RULES = {
        // Articles
        'un': 'Article + Noun', 'les': 'Article + Noun', 'des': 'Article + Noun',
        'aux': 'Article + Noun',
        // Possessives
        'mon': 'Possessive + Noun', 'ton': 'Possessive + Noun', 'son': 'Possessive + Noun',
        'mes': 'Possessive + Noun', 'tes': 'Possessive + Noun', 'ses': 'Possessive + Noun',
        'nos': 'Possessive + Noun', 'vos': 'Possessive + Noun', 'leurs': 'Possessive + Noun',
        // Demonstratives
        'ces': 'Demonstrative + Noun', 'cet': 'Demonstrative + Noun', 'cette': 'Demonstrative + Noun',
        // Quantifiers
        'aucun': 'Quantifier + Noun', 'tout': 'Quantifier + Noun', 'tous': 'Quantifier + Noun',
        'plusieurs': 'Quantifier + Noun', 'quels': 'Interrogative + Noun', 'quelles': 'Interrogative + Noun',
        // Pronouns
        'nous': 'Pronoun + Verb', 'vous': 'Pronoun + Verb', 'ils': 'Pronoun + Verb',
        'elles': 'Pronoun + Verb', 'on': 'Pronoun + Verb', 'en': 'Pronoun + Verb',
        'dont': 'Relative Pronoun', 'rien': 'Pronoun + Adjective/Verb',
        // Adjectives (Pre-nominal) - Added missing ones here
        'petit': 'Adjective + Noun', 'grand': 'Adjective + Noun', 'gros': 'Adjective + Noun',
        'mauvais': 'Adjective + Noun', 'bon': 'Adjective + Noun', 'beaux': 'Adjective + Noun',
        'vieux': 'Adjective + Noun', 'premier': 'Adjective + Noun', 'premiers': 'Adjective + Noun',
        'certain': 'Adjective + Noun', 'moyen': 'Adjective + Noun', 'ancien': 'Adjective + Noun',
        'anciens': 'Adjective + Noun', 'nouveaux': 'Adjective + Noun', 'hauts': 'Adjective + Noun',
        // Adverbs
        'tres': 'Adverb + Adjective', 'bien': 'Adverb + Adjective', 'plus': 'Adverb + Adjective',
        'moins': 'Adverb + Adjective', 'trop': 'Adverb + Adjective', 'fort': 'Adverb + Adjective',
        'tant': 'Adverb + Adjective', 'autant': 'Adverb + Adjective', 'pas': 'Negative Adverb',
        'jamais': 'Negative Adverb',
        // Prepositions
        'dans': 'Preposition + Noun', 'chez': 'Preposition + Noun', 'sans': 'Preposition + Noun',
        'sous': 'Preposition + Noun', 'en': 'Preposition + Noun', 'apres': 'Preposition + Noun',
        // Conjunctions
        'mais': 'Conjunction',
        // Numbers (Removed 'huit' from here to prevent "huit hommes")
        'deux': 'Number + Noun', 'trois': 'Number + Noun', 'vingt': 'Number + Noun',
        'cent': 'Number + Noun', 'dix': 'Number + Noun', 'six': 'Number + Noun',
        'neuf': 'Number + Noun'
    };

    const BLOCK_LIAISON_BEFORE = new Set([
        'hache', 'haie', 'haine', 'hair', 'halage', 'hale', 'haleter', 'hall', 'halle', 'halte',
        'hamac', 'hamburger', 'hameau', 'hamster', 'hanche', 'handball', 'handicap', 'hangar',
        'hanter', 'happer', 'harangue', 'harasser', 'harceler', 'hardes', 'hardi', 'hareng',
        'haricot', 'harnais', 'harpe', 'hasard', 'hate', 'hausse', 'haut', 'hauteur', 'havre',
        'herisson', 'heron', 'heros', 'herse', 'hetre', 'heurter', 'hibou', 'hic', 'hideux',
        'hierarchie', 'hocher', 'hockey', 'hollandais', 'homard', 'honte', 'horde', 'hors',
        'hot-dog', 'hotte', 'houblon', 'houille', 'houle', 'houppe', 'housse', 'houx', 'hublot',
        'huche', 'huer', 'huit', 'huitieme', 'hurler', 'hussard', 'hutte', 'hyene',
        'helicoptere', 'hotel', 'hi-fi', 'y', 'oui', 'onze', 'et', 'ou', 'etc', 'hot', 'hi'
    ]);

    const BLOCK_LIAISON_AFTER = new Set([
        'et', 'ou', 'selon', 'vers', 'envers', 'hormis', 'non', 'quelqu\'un', 'chacun',
        'comment', 'quand', 'combien', 'toujours'
        // Removed 'cent' to allow "cent euros"
    ]);

    const MANDATORY_LIAISON_WORDS = new Set(Object.keys(WORD_SPECIFIC_RULES));

    const SAFE_VERBS = new Set([
        'est', 'sont', 'ont', 'suis', 'sommes', 'etes', 'etais', 'etait', 'etaient',
        'ai', 'as', 'a', 'avons', 'avez', 'avais', 'avait', 'avaient',
        'dois', 'doit', 'peut', 'veux', 'veut', 'faut', 'vaut', 'vont',
        "c'est", "s'est"
    ]);

    const NON_NOUN_S_ENDINGS = new Set([
        'mais', 'pas', 'tres', 'plus', 'moins', 'dans', 'sans', 'sous', 'apres', 'jamais',
        'toujours', 'alors', 'depuis', 'vers', 'envers', 'hormis', 'fois', 'temps', 'corps', 'ailleurs'
    ]);

    const isBlockedBefore = (wordNorm) => {
        if (BLOCK_LIAISON_BEFORE.has(wordNorm)) return true;
        if (wordNorm.endsWith('s') || wordNorm.endsWith('x')) {
            const singular = wordNorm.slice(0, -1);
            if (BLOCK_LIAISON_BEFORE.has(singular)) return true;
        }
        return false;
    };

    const getRuleName = (wordNorm, tags1, tags2, fallback) => {
        if (WORD_SPECIFIC_RULES[wordNorm]) return WORD_SPECIFIC_RULES[wordNorm];
        if (tags1.has('Adjective') && tags2.has('Noun')) return "Adjective + Noun";
        if (tags1.has('Pronoun') && tags2.has('Verb')) return "Pronoun + Verb";
        if (SAFE_VERBS.has(wordNorm)) return "Verb (Être/Avoir)";
        return fallback;
    };

    // ==========================================
    // 2. MAIN LOOP
    // ==========================================

    for (let i = 0; i < terms.length; i++) {
        const t1 = terms[i];
        const t2 = terms[i + 1];

        result.push((t1.pre || '') + t1.text);

        if (!t2) {
            result.push(t1.post || '');
            continue;
        }

        const w1 = t1.text;
        const w2 = t2.text;
        const w1Norm = normalize(w1);
        const w2Norm = normalize(w2);
        const tags1 = new Set(t1.tags);
        const tags2 = new Set(t2.tags);

        // --- HYPHEN HANDLING ---
        if (t1.post.includes('-')) {
            const isEtatsUnis = w1Norm === 'etats' && w2Norm === 'unis';
            const isVingtEt = w1Norm === 'vingt' && w2Norm === 'et';
            const isVasY = (w1Norm === 'vas' || w1Norm === 'allez') && w2Norm === 'y';

            if (isEtatsUnis || isVingtEt || isVasY) {
                result.push('‿');
                liaisons.push({word1: w1, word2: w2, rule: 'Fixed Hyphenated Expression'});
                continue;
            }
            result.push(t1.post);
            omissions.push({word1: w1, word2: w2, rule: 'Hyphenated (No Liaison)'});
            continue;
        }

        // --- PUNCTUATION ---
        if (/[.,;!?:"»)]/.test(t1.post)) {
            result.push(t1.post);
            continue;
        }

        // --- BLOCKING (Word 2) ---
        if (isBlockedBefore(w2Norm)) {
            const isHuitException = w1Norm === 'huit' && (w2Norm === 'heures' || w2Norm === 'ans');
            const isPlusOu = w1Norm === 'plus' && w2Norm === 'ou';
            const isVingtEt = w1Norm === 'vingt' && w2Norm === 'et';

            if (!isHuitException && !isPlusOu && !isVingtEt) {
                // Fix for double space: check if t2.pre already has a space
                const defaultSpace = (t2.pre && /^\s/.test(t2.pre)) ? '' : ' ';
                result.push(t1.post !== undefined ? t1.post : defaultSpace);

                omissions.push({word1: w1, word2: w2, rule: 'H-Aspiré / Blocked Word'});
                continue;
            }
        }

        // --- BLOCKING (Word 1) ---
        if (BLOCK_LIAISON_AFTER.has(w1Norm)) {
            // Removed exception for 'comment allez-vous' to match test expectation (no liaison marker)
            const isChacunEst = w1Norm === 'chacun' && w2Norm === 'est';
            const isQuandValid = w1Norm === 'quand' &&
                (w2Norm === 'il' || w2Norm === 'elle' || w2Norm === 'on' || w2Norm === 'ils' || w2Norm === 'elles' || w2Norm === 'est') &&
                !(i > 0 && ['plus', 'a', 'est'].includes(normalize(terms[i - 1].text)));

            if (!isQuandValid && !isChacunEst) {
                const defaultSpace = (t2.pre && /^\s/.test(t2.pre)) ? '' : ' ';
                result.push(t1.post !== undefined ? t1.post : defaultSpace);

                let reason = 'Forbidden Word';
                if (w1Norm === 'et') reason = "Conjunction 'et'";
                else if (w1Norm === 'ou') reason = "Conjunction 'ou'";
                omissions.push({word1: w1, word2: w2, rule: reason});
                continue;
            }
        }

        // --- INVERSION ---
        const isPrevInversion = i > 0 && terms[i - 1].post && terms[i - 1].post.includes('-');
        if (tags1.has('Pronoun') && (isPrevInversion || (t1.pre && t1.pre.includes('-')))) {
            const defaultSpace = (t2.pre && /^\s/.test(t2.pre)) ? '' : ' ';
            result.push(t1.post !== undefined ? t1.post : defaultSpace);
            omissions.push({word1: w1, word2: w2, rule: 'Follows Inversion'});
            continue;
        }

        // --- PROPER NOUNS ---
        if ((tags1.has('ProperNoun') && w1Norm !== 'etats') || (tags2.has('ProperNoun') && w2Norm !== 'unis')) {
            const defaultSpace = (t2.pre && /^\s/.test(t2.pre)) ? '' : ' ';
            result.push(t1.post !== undefined ? t1.post : defaultSpace);
            omissions.push({word1: w1, word2: w2, rule: 'Proper Noun'});
            continue;
        }

        // --- PHONETICS ---
        const endsWithLiaisonCon = LIAISON_CONSONANTS.test(w1);
        const startsWithVowel = VOWELS.test(w2);
        const isVingtEt = w1Norm === 'vingt' && w2Norm === 'et';

        if ((!endsWithLiaisonCon || !startsWithVowel) && !isVingtEt) {
            const defaultSpace = (t2.pre && /^\s/.test(t2.pre)) ? '' : ' ';
            result.push(t1.post !== undefined ? t1.post : defaultSpace);
            continue;
        }

        // --- GRAMMAR RULES ---
        let shouldLiaison = false;
        let ruleName = '';
        console.log(t1, t2)
        console.log(w1Norm === 'sang', w2Norm === 'impur')
        console.log(tags1, tags2, tags1.has('Noun'), (tags1.has('PluralNoun') || tags1.has('Plural')))
        // 1. Fixed Expressions & Exceptions
        if (w1Norm === 'sang' && w2Norm === 'impur') {
            shouldLiaison = true;
            ruleName = 'Fixed: Sang Impur';
        } else if (w1Norm === 'chacun' && w2Norm === 'est') {
            shouldLiaison = true;
            ruleName = 'Fixed: Chacun est';
        } else if (w1Norm === 'mot' && w2Norm === 'a') {
            shouldLiaison = true;
            ruleName = 'Fixed: Mot à mot';
        } else if (w1Norm === 'temps' && w2Norm === 'en') {
            shouldLiaison = true;
            ruleName = 'Fixed: Temps en temps';
        } else if (w1Norm === 'quand' && (w2Norm === 'il' || w2Norm === 'elle' || w2Norm === 'on' || w2Norm === 'est')) {
            shouldLiaison = true;
            ruleName = 'Quand + Pronoun';
        } else if (w1Norm === 'vingt' && w2Norm === 'et') {
            shouldLiaison = true;
            ruleName = 'Fixed: Vingt et';
        } else if (w1Norm === 'plus' && w2Norm === 'ou') {
            shouldLiaison = true;
            ruleName = 'Fixed: Plus ou moins';
        } else if (w1Norm === 'est' && (w2Norm === 'un' || w2Norm === 'une')) {
            shouldLiaison = true;
            ruleName = 'Verb (Être) + Article';
        } else if (w1Norm === 'huit' && (w2Norm === 'heures' || w2Norm === 'ans')) {
            shouldLiaison = true;
            ruleName = 'Number + Noun';
        }

        // 2. Mandatory List (Dictionary Lookup)
        else if (MANDATORY_LIAISON_WORDS.has(w1Norm)) {
            const prevWord = i > 0 ? normalize(terms[i - 1].text) : '';
            const isNumberCompound = (w1Norm === 'un' && (prevWord === 'cent' || prevWord === 'vingt'));

            if (w1Norm === 'cent' && w2Norm === 'un') {
                shouldLiaison = false;
                omissions.push({word1: w1, word2: w2, rule: 'Compound Number (Cent un)'});
            } else if (isNumberCompound) {
                shouldLiaison = false;
                omissions.push({word1: w1, word2: w2, rule: 'Compound Number (...un)'});
            } else {
                shouldLiaison = true;
                ruleName = getRuleName(w1Norm, tags1, tags2, "Mandatory Word");
            }
        }

        // 3. Adjective + Noun
        else if (tags1.has('Adjective') && (tags2.has('Noun') || tags2.has('Adjective'))) {
            shouldLiaison = true;
            ruleName = 'Adjective + Noun';
        }

        // 4. Pronoun + Verb
        else if (tags1.has('Pronoun') && (tags2.has('Verb') || tags2.has('Auxiliary') || SAFE_VERBS.has(w2Norm))) {
            shouldLiaison = true;
            ruleName = 'Pronoun + Verb';
        }

        // 5. Safe Verbs
        else if (SAFE_VERBS.has(w1Norm)) {
            if (w2Norm === 'eu') {
                shouldLiaison = false;
                omissions.push({word1: w1, word2: w2, rule: 'Past Participle "eu"'});
            } else if (w1Norm === 'es' && i > 0 && normalize(terms[i - 1].text) === 'tu') {
                shouldLiaison = false;
                omissions.push({word1: w1, word2: w2, rule: 'Tu es (Informal)'});
            } else {
                shouldLiaison = true;
                ruleName = 'Verb (Être/Avoir)';
            }
        }

            // Replaced raw suffix check with compromise Plural tag check
        // 6. Plural Noun + Adjective (ROBUST CONTEXT CHECK)
        else if (tags1.has('Noun') && (tags2.has('Adjective') || tags2.has('Preposition'))) {

            // 1. Start with tagger's opinion
            let isPlural = (tags1.has('Plural') || tags1.has('PluralNoun'));

            // 2. Contextual Overrides for Invariant Nouns (ending in s/x/z)
            if (w1Norm.endsWith('s') || w1Norm.endsWith('x') || w1Norm.endsWith('z')) {
                if (i > 0) {
                    const prevTerm = terms[i - 1];
                    const prevNorm = normalize(prevTerm.text);

                    // Force Plural (e.g. "des corps")
                    if (PLURAL_DETERMINERS.has(prevNorm)) {
                        isPlural = true;
                    }
                    // Force Singular (e.g. "le temps")
                    else if (SINGULAR_DETERMINERS.has(prevNorm)) {
                        isPlural = false;
                    }
                }
            }

            if (isPlural) {
                shouldLiaison = true;
                ruleName = 'Plural Noun + Adjective';
            }
            console.log('Hmmm')
        }


        // --- APPLY RESULT ---
        if (shouldLiaison) {
            result.push('‿');
            liaisons.push({word1: w1, word2: w2, rule: ruleName});
        } else {
            const defaultSpace = (t2.pre && /^\s/.test(t2.pre)) ? '' : ' ';
            result.push(t1.post !== undefined ? t1.post : defaultSpace);

            if (!omissions.some(o => o.word1 === w1 && o.word2 === w2)) {
                let reason = 'General Restriction';
                if (tags1.has('Noun') && tags1.has('Singular')) reason = 'Singular Noun';
                else if (w1Norm.endsWith('ment')) reason = 'Adverb -ment';
                else if (tags1.has('Noun') && tags2.has('Verb')) reason = 'Noun + Verb (Forbidden)';
                else if (tags1.has('Noun') && tags2.has('Noun')) reason = 'Noun + Noun (Forbidden)';
                else if (tags1.has('Verb')) reason = 'Verb (Non-Safe)';

                omissions.push({word1: w1, word2: w2, rule: reason});
            }
        }
    }

    return {text: result.join(''), liaisons: liaisons, omissions: omissions};
}