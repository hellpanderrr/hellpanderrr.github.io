function insertLiaisonMarkers(text) {
    if (!text || typeof text !== 'string' || !text.trim()) {
        return {text: text || '', liaisons: [], omissions: []};
    }


    const doc = frCompromise(text);
    if (!doc.terms().document || doc.terms().document.length === 0) {
        return {text: text, liaisons: [], omissions: []};
    }
    const terms = doc.terms().document.flat();
    const result = [];
    const liaisons = [];
    const omissions = [];

    const silentConsonants = new Set(['s', 'x', 'z', 'd', 't', 'p', 'r', 'g', 'f', 'n']);
    const vowels = new Set(['a', 'e', 'i', 'o', 'u', 'y', 'A', 'E', 'I', 'O', 'U', 'Y', 'œ', 'Œ']);

    const normalizedAspiratedHWords = new Set([
        'ha', 'hache', 'hachette', 'hachis', 'hachoir', 'hachure', 'haddock', 'hafiz', 'haggis', 'haie', 'haillon', 'haine',
        'hair', 'halage', 'halbran', 'hale', 'haleine', 'half', 'halifax', 'halio', 'hall', 'halles', 'hallier',
        'halma', 'halo', 'halt', 'halte', 'halva', 'halètement', 'hamac', 'hameau', 'hameçon', 'hamburger', 'hameur', 'hami',
        'hamilton', 'hamiltonien', 'hamis', 'hammam', 'hamster', 'han', 'hanap', 'hanche', 'handball', 'handicap', 'handicapé',
        'hangar', 'hangarage', 'hanjar', 'hanota', 'hans', 'hansart', 'hanté', 'hantise', 'hanuman', 'happe', 'happer',
        'hara-kiri', 'harangue', 'harangueur', 'harasser', 'harassé', 'harasseur', 'harcelant', 'harceler', 'harcèlement',
        'hard', 'hardant', 'harem', 'harfang', 'haricot', 'haridelle', 'harmonica', 'harnachement',
        'harnacher', 'harpagon', 'harpe', 'harpiste', 'hasard', 'haschisch', 'hase', 'hasta', 'hasté', 'hat', 'hatha', 'hauban',
        'haubert', 'haud', 'hauge', 'haussa', 'hausse', 'haussé', 'haussière', 'haut', 'haute', 'hautement', 'hauteur', 'havane',
        'haven', 'havre', 'hayon', 'hazard', 'hâbleur', 'héraut', 'hêche', 'hêchée', 'hêcheur', 'hélas', 'hélianthème', 'hélico',
        'hélicon', 'hélicoptère', 'hélium', 'hématome', 'hénau', 'hénon', 'hépate', 'hépatalgie', 'hépatique', 'her', 'herbacée',
        'herbage', 'herbe', 'herbes', 'herbier', 'herboriser', 'herboriste', 'hercule', 'herculéen', 'herdier', 'hère', 'hérédo',
        'hérédosyphilis', 'hérésie', 'hérétique', 'hérissé', 'hérisson', 'héritage', 'héritier', 'héritière', 'héros',
        'hésychaste', 'hétéroclite', 'hétérogène', 'hétérologue', 'hêtre', 'heur', 'heurter', 'heurtoir', 'heurté', 'heurtée',
        'hibiscus', 'hibou', 'hiboux', 'hickory', 'hi-fi', 'hiéroglyphe', 'hidalgo', 'hideur', 'hideux', 'hilarant', 'hilichurl',
        'himalaya', 'hinder', 'hindou', 'hindouisme', 'hindous', 'hip', 'hippie', 'hippodrome', 'hira', 'hirondelle', 'hispanique',
        'hispanisme', 'hispaniste', 'hissage', 'hisser', 'hochepot', 'hockey', 'hog', 'hoir',
        'hoire', 'holà', 'holding', 'holistique', 'hollandais', 'hollande', 'hollywoodien', 'holocauste', 'homard', 'home',
        'homéomorphe', 'homéopathie', 'homéopathe', 'homéopathique', 'hominidé', 'hominy', 'hommage',
        'homogène', 'homologation', 'homologue', 'homonyme', 'homophobie', 'homophone', 'hongkongais',
        'hongre', 'hongrer', 'hongrois', 'hongroise', 'honnête', 'honnêteté', 'honte', 'honteux', 'hoot', 'hoquet',
        'horde', 'hors', 'horst', 'hosanna', 'hot', 'hot-dog', 'houache', 'houari', 'houblon', 'houe', 'houer', 'houille',
        'houillères', 'houle', 'houleux', 'houligan', 'houligane', 'houliganisme', 'houm', 'houppette', 'houquet', 'hour',
        'hourra', 'house', 'housses', 'houx', 'hoverboard', 'hu', 'hub', 'hublot', 'huche', 'huchement', 'hue', 'huer', 'huile',
        'huiler', 'huilerie', 'huileux', 'huit', 'huitaine', 'huitante', 'huitième', 'huitre', 'huître', 'hull', 'humble',
        'humecter', 'humecté', 'humide', 'humidifier', 'humidifié', 'humidité', 'humilier', 'humilié', 'humour', 'hune', 'huppé',
        'hure', 'hurlant', 'hurler', 'hurluberlu', 'hurlure', 'huron', 'hurrah', 'hurlement', 'hussard', 'hussarde', 'hussein',
        'hutte', 'hutu', 'huy', 'hyaena', 'hybridation', 'hybride', 'hybridité', 'hydraulicité', 'hydraulique', 'hydrazine',
        'hydre', 'hydride', 'hydriodure', 'hydro', 'hydrobromure', 'hydrocarbure', 'hydrocéphale', 'hydrocéphalie', 'hydrochlorure',
        'hydrocortisone', 'hydrocution', 'hydrodynamique', 'hydrofluorocarbone', 'hydrofoyle', 'hydrofuge', 'hydrogène',
        'hydrogénation', 'hydrogénée', 'hydrolat', 'hydrolyse', 'hydromel', 'hydromètre', 'hydrométrie', 'hydrophile',
        'hydrophobie', 'hydropisie', 'hydropique', 'hydropneumatique', 'hydrosoluble', 'hydrostatique', 'hydrosulfure',
        'hydrosystème', 'hydrure', 'hydénique', 'hyène', 'hygiène', 'hygiéniste', 'hygiénique', 'hymen', 'hymne', 'hypallage',
        'hyper', 'hyperactif', 'hyperacuité', 'hyperalgésie', 'hyperalgique', 'hyperbare', 'hyperboloïde', 'hyperbole',
        'hyperbolique', 'hypercellulaire', 'hypercorde', 'hypercorrection', 'hypercube', 'hypercentre', 'hypercinèse',
        'hyperconnectivité', 'hypercorrectement', 'hypercorrecteur', 'hypercritique', 'hypercutané', 'hyperdiffusion',
        'hyperdivision', 'hyperdulie', 'hyperfine', 'hyperfocale', 'hyperfocalisation', 'hyperfocalisé', 'hyperfréquence',
        'hyperfunktion', 'hyperglycémie', 'hypergonadism', 'hypergraphie', 'hypergraphe', 'hyperhémie', 'hyperhémolyse',
        'hyperinflation', 'hyperinflationniste', 'hyperintensité', 'hyperlipémie', 'hyperlipidémie', 'hyperlordose',
        'hypermachinism', 'hypermachism', 'hypermarché', 'hypermarchés', 'hypermétrope', 'hypermétrie', 'hypermétropie',
        'hypermétropique', 'hypermobile', 'hypermobilité', 'hypermotricité', 'hypermyopie', 'hypernymie', 'hyperonymie',
        'hyperparathyroïdie', 'hyperphagie', 'hyperphosphorémie', 'hyperphysique', 'hyperplan', 'hyperpolémique',
        'hyperpression', 'hyperprotéiné', 'hyperpuriste', 'hyperpyrétie', 'hyperréalisme', 'hyperréaliste', 'hyperrectangle',
        'hyperréfléchir', 'hyperréflexion', 'hyperreligieux', 'hyperrémunéré', 'hyperrésonance', 'hypersalivation',
        'hypersaturation', 'hypersexualité', 'hypersensible', 'hypersensibiliser', 'hypersibilité', 'hypersigne', 'hypersomnie',
        'hyperspécialisation', 'hyperspatial', 'hypersphère', 'hypersphérique', 'hypersurface', 'hypertendu', 'hypertendue',
        'hypertension', 'hypertonie', 'hypertrophie', 'hypertrophier', 'hypervascularisation', 'hyperventilation', 'hypervitaminose',
        'hypervolatilité', 'hyperwhite', 'hooligan', 'hooligans', 'hurle', 'hurlent', 'hockey', 'hotel', 'hi-fi', 'hi'
    ].map(w => w.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')));
    const muteHCorrections = ['homme', 'hommes', 'heure', 'heures', 'humain', 'humains', 'hiver', 'héroïne', 'histoire', 'harmonie']
        .map(w => w.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, ''));
    muteHCorrections.forEach(w => normalizedAspiratedHWords.delete(w));

    const obligatoryTriggers = {
        determiners: new Set(['un', 'une', 'des', 'les', 'le', 'la', 'du', 'de', 'au', 'aux', 'ce', 'cet', 'cette', 'ces', 'mon', 'ton', 'son', 'ma', 'ta', 'sa', 'notre', 'votre', 'leur', 'mes', 'tes', 'ses', 'nos', 'vos', 'leurs', 'aucun', 'quels', 'quelles', 'quel', 'quelle', 'tout', 'toute', 'tous', 'toutes']),
        pronouns: new Set(['nous', 'vous', 'ils', 'elles', 'on', 'en', 'y', 'je', 'tu', 'il', 'elle', 'eux', 'tout', 'rien', 'dont', 'chacun']),
        numbers: new Set(['deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix', 'onze', 'douze', 'vingt', 'cent', 'mille']),
        adverbs: new Set(['bien', 'très', 'trop', 'plus', 'moins', 'tout', 'assez', 'autant', 'aussi', 'souvent', 'mieux', 'fort', 'jamais', 'guère', 'pas', 'tant', 'comment']),
        prepositions: new Set(['dans', 'chez', 'quand', 'sans', 'vers', 'sous', 'sur', 'entre', 'devant', 'depuis', 'pendant', 'apres', 'avant', 'mais']),
        adjectives: new Set(['grand', 'petit', 'beau', 'bon', 'mauvais', 'vieux', 'nouveau', 'jeune', 'premier', 'dernier', 'seul', 'certain', 'gros', 'long', 'haut', 'gentil', 'anciens', 'anciennes', 'beaux', 'belles'])
    };
    obligatoryTriggers.adverbs.delete('toujours');


    const safeVerbs = new Set(['est', 'sont', 'ont', 'suis', 'sommes', 'êtes', 'étais', 'était', 'étaient', 'ai', 'as', 'a', 'avons', 'avez', 'avais', 'avait', 'avaient', 'vais', 'vas', 'va', 'allons', 'allez', 'vont', 'dois', 'doit', 'pouvons', 'pouvez', 'peuvent', 'peut', 'veux', 'veut', 'voulons', 'voulez', 'veulent', 'faut', 'vaut', "c'est", "s'est"]);

    const auxiliaryVerbs = new Set(['avons', 'avez', 'ont', 'suis', 'es', 'est', 'sommes', 'êtes', 'sont', 'avais', 'avait', 'avaient']);

    const nasalPreserveGroup = new Set(['un', 'on', 'en', 'mon', 'ton', 'son', 'bien', 'rien', 'aucun', 'commun', 'moyen', 'plein', 'chacun']);
    const nasalDenasalGroup = new Set(['bon', 'certain', 'ancien', 'chrétien', 'européen', 'examen', 'indien', 'moyen', 'païen']);

    const forbiddenWords = new Set(['et', 'ou', 'où', 'où', 'ouis', 'oui', 'huit', 'onze', 'onzes', 'etc', 'etc.']);
    const forbiddenAfter = new Set(['selon']);
    const foreignWords = new Set(['hotel', 'email', 'hi-fi', 'wifi', 'weekend']);

    const fixedExpressions = [
        {pattern: ['petit', 'a'], liaison: true},
        {pattern: ['mot', 'a'], liaison: true},
        {pattern: ['temps', 'en'], liaison: true},
        {pattern: ['plus', 'en'], liaison: true},
        {pattern: ['états', 'unis'], liaison: true},
        {pattern: ['vingt', 'et'], liaison: true}
    ];

    for (let i = 0; i < terms.length; i++) {
        const currentTerm = terms[i];
        const currentWord = currentTerm.text;
        const current = currentWord.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
        const prePunctuation = currentTerm.pre || '';

        result.push(prePunctuation + currentWord);


        if (i < terms.length - 1) {
            const nextTerm = terms[i + 1];
            const nextWord = nextTerm.text;
            const next = nextWord.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
            const lastChar = current[current.length - 1];
            const firstChar = next[0];
            const currentTags = new Set(currentTerm.tags || []);
            const nextTags = new Set(nextTerm.tags || []);
            const postPunctuation = currentTerm.post || '';
            let triggeredRule = null;

            if (/[.,;!?:"»)-]/.test(postPunctuation) || /[.,;!?:"»(]/.test(nextWord[0])) {
                if (postPunctuation === '-') {
                    const isHyphenatedLiaison =
                        (current === 'vas' && next === 'y') ||
                        (current === 'états' && next === 'unis') ||
                        (current === 'etats' && next === 'unis') ||
                        (current === 'vingt' && next === 'et');

                    if (isHyphenatedLiaison) {
                        result.push('‿');
                        liaisons.push({word1: currentWord, word2: nextWord, rule: 'Fixed Hyphenated Expression'});
                        continue;
                    }
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Hyphenated (No Liaison)'});
                }
                result.push(postPunctuation);
                continue;
            }

            if (nextWord.includes('.') ||
                nextWord.toLowerCase() === 'etc' ||
                /^[A-Z]\.$/.test(nextWord) ||
                /^[md]r\.$/i.test(nextWord) ||
                nextWord.includes('-') && !currentWord.includes('-')) {
                result.push(postPunctuation || ' ');
                continue;
            }
            if (postPunctuation === '-') {
                result.push('-');
                continue;
            }

            if (currentWord.includes('-') || nextWord.includes('-')) {
                result.push(postPunctuation || ' ');
                continue;
            }
            if ((next === 'huit' || next === 'onze') && !['heures', 'ans', 'jours'].includes(terms[i + 2]?.text?.toLowerCase())) {
                result.push(postPunctuation || ' ');
                omissions.push({word1: currentWord, word2: nextWord, rule: 'Huit/Onze Exception'});
                continue;
            }
            if ((currentTags.has('Value') || current === 'cent') && (nextTags.has('Value') || next === 'un') && !nextTags.has('Noun')) {
                result.push(postPunctuation || ' ');
                omissions.push({word1: currentWord, word2: nextWord, rule: 'Value Sequence'});
                continue;
            }

            if (current === 'les' && next === 'un') {
                result.push(postPunctuation);
                continue;
            }
            if (current === 'un' && i > 0) {
                const prevTerm = terms[i - 1];
                const prevTags = prevTerm.tags || [];
                if (prevTags.has('Value') || prevTags.has('Cardinal')) {
                    result.push(postPunctuation || ' ');
                    continue;
                }
            }

            let isFixedExpression = false;
            for (const expr of fixedExpressions) {
                if (current === expr.pattern[0] && next === expr.pattern[1]) {
                    isFixedExpression = expr.liaison;
                    break;
                }
            }


            const isAspirated = normalizedAspiratedHWords.has(next) ||
                (next.endsWith('s') && normalizedAspiratedHWords.has(next.slice(0, -1))) || foreignWords.has(next);

            const endsWithSilentConsonant = silentConsonants.has(lastChar);
            const startsWithVowel = vowels.has(firstChar);
            const startsWithMuteH = firstChar === 'h' && !isAspirated;
            const isSangImpur = current === 'sang' && next === 'impur';

            // [CHANGE] Detect H-aspiré explicitly (fixes 'le héros')
            // This runs even if there is no silent consonant (like in "le", "la"),
            // capturing the "omission" of continuity caused by the H-aspiré.
            if (firstChar === 'h' && isAspirated) {
                omissions.push({word1: currentWord, word2: nextWord, rule: 'H Aspiré'});
            }

            if (endsWithSilentConsonant && (startsWithVowel || startsWithMuteH)) {
                const currentTags = currentTerm.tags || [];
                const nextTags = nextTerm.tags || [];
                const currentTagSet = new Set(currentTags);
                const nextTagSet = new Set(nextTags);

                if (current === 'bois' && nextTagSet.has('Determiner')) {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Verb (Bois) + Determiner'});
                    continue;
                }

                const isPluralNoun = ((currentTagSet.has('Noun') && currentTagSet.has('Plural')) ||
                    (currentTagSet.has('Noun') && (current.endsWith('s') || current.endsWith('x')) && !current.endsWith('ss')) || currentTagSet.has('Plural')) && !currentTagSet.has('Singular');

                if (isPluralNoun && (nextTags.has('Verb') || safeVerbs.has(next) || auxiliaryVerbs.has(next)) && !currentTags.has('Pronoun')) {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Plural Noun + Verb'});
                    continue;
                }
                if (currentTags.has('Verb') && !safeVerbs.has(current) && !auxiliaryVerbs.has(current)) {
                    if (nextTags.has('Determiner') || nextTags.has('Noun') || nextTags.has('Value')) {
                        result.push(postPunctuation || ' ');
                        omissions.push({word1: currentWord, word2: nextWord, rule: 'Verb + Determiner/Noun'});
                        continue;
                    }
                }
                if (currentTagSet.has('Verb') && !safeVerbs.has(current) && (nextTagSet.has('Determiner') || nextTagSet.has('Noun'))) {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Verb + Determiner/Noun'});
                    continue;
                }
                if (currentTags.has('Adjective') && (nextTags.has('Preposition') || next === 'a')) {
                    if (!isFixedExpression) {
                        result.push(postPunctuation || ' ');
                        omissions.push({word1: currentWord, word2: nextWord, rule: 'Adjective + Preposition'});
                        continue;
                    }
                }
                const isForbiddenWord = forbiddenWords.has(current);
                const isNextForbidden = forbiddenWords.has(next) && !(current === 'plus' && next === 'ou');
                const isAfterForbidden = forbiddenAfter.has(current);
                const isNextAdjective = nextTagSet.has('Adjective');
                const isNextVerb = nextTagSet.has('Verb');
                const isNextPreposition = nextTagSet.has('Preposition');
                const isPrepositionBeforeProperNoun = currentTagSet.has('Preposition') && nextTagSet.has('ProperNoun');
                const isAdjectiveFollowedByPreposition = currentTagSet.has('Adjective') &&
                    (next === 'à' || next === 'de' || nextTagSet.has('Preposition'));
                const isQuandInversion = current === 'quand' && nextTerm.post && nextTerm.post.includes('-');


                const isPluralNounAdjective = currentTagSet.has('Noun') &&
                    currentTagSet.has('Plural') &&
                    nextTagSet.has('Adjective');

                const isSingularNoun = !isPluralNoun && currentTagSet.has('Noun') &&
                    !obligatoryTriggers.determiners.has(current) &&
                    !obligatoryTriggers.numbers.has(current) &&
                    !obligatoryTriggers.adverbs.has(current) &&
                    !obligatoryTriggers.adjectives.has(current) &&
                    !obligatoryTriggers.pronouns.has(current) &&
                    !safeVerbs.has(current) && current !== 'est' && current !== 'apres';

                const isAfterVerb = currentTagSet.has('Verb') && !safeVerbs.has(current) && !auxiliaryVerbs.has(current);
                const isAdverbInMent = current.endsWith('ment') && currentTagSet.has('Adverb');
                const isBeforeOui = next === 'oui' || next === 'ouï';

                const isVerbSubjectInversion = (currentTagSet.has('Verb') || current === 'est' || current === 'ont' || current === 'sont') &&
                    (next === 'il' || next === 'elle' || next === 'on' || next === 'ils' || next === 'elles');

                const isInvertedPronoun = currentWord.includes('-') &&
                    ['il', 'elle', 'on', 'ils', 'elles', 'je', 'tu', 'nous', 'vous'].some(p =>
                        currentWord.toLowerCase().endsWith('-' + p));
                const followsInversion = (current === 'il' || current === 'elle' || current === 'on' || current === 'ils' || current === 'elles') &&
                    (prePunctuation.includes('-') || (i > 0 && terms[i - 1].post && terms[i - 1].post.includes('-')));
                const isProperNoun = (current[0] === current[0].toUpperCase() && !obligatoryTriggers.determiners.has(current) && current !== 'M.' && currentTagSet.has('Noun')) || currentTagSet.has('ProperNoun');

                const isInterrogativeVerb = ['comment', 'combien', 'quand'].includes(current) && nextTagSet.has('Verb');
                const isRealInterrogativeQuestion =
                    (current === 'comment' || current === 'combien' || current === 'quand') &&
                    nextTags.has('Verb') &&
                    !(current === 'quand' && ['est', 'il', 'elle', 'on', 'a', 'ont', 'avons', 'avez'].includes(next)) &&
                    !(current === 'comment' && next === 'allez');
                const isHuitException = current === 'huit' && (next === 'heures' || next === 'ans' || next === 'jours');
                const isPluralNounVerb = isPluralNoun && !isPluralNounAdjective && (nextTagSet.has('Verb') || safeVerbs.has(next) || auxiliaryVerbs.has(next));

                const isQuandConjunction = current === 'quand' &&
                    next === 'il' &&
                    i > 0 &&
                    terms[i - 1]?.text?.toLowerCase() === 'plus';

                if (isQuandConjunction) {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Quand Conjunction'});
                    continue;
                }
                const isQuandValid = current === 'quand' && ['est', 'il', 'ils', 'elle', 'elles', 'on', 'a'].includes(next);
                if (current === 'quand' && !isQuandValid) {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Quand (Non-Question)'});
                    continue;
                }
                if (current === 'toujours' && nextTagSet.has('Adjective')) {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Toujours + Adjective'});
                    continue;
                }

                if (current === 'es' && i > 0 && terms[i - 1].text.toLowerCase() === 'tu') {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'Tu es'});
                    continue;
                }

                if (isSangImpur || isFixedExpression || (isPluralNoun && isNextAdjective)) {
                    // Bypass forbidden checks
                } else if (!isVerbSubjectInversion && (
                    (isForbiddenWord && !isHuitException) ||
                    isNextForbidden ||
                    isAfterForbidden ||
                    (isSingularNoun && !currentTagSet.has('Adjective')) ||
                    isAfterVerb ||
                    isAdverbInMent ||
                    isBeforeOui ||
                    followsInversion ||
                    isProperNoun || isPrepositionBeforeProperNoun || isRealInterrogativeQuestion

                )) {
                    result.push(postPunctuation);
                    let reason = 'General Restriction';
                    if (isForbiddenWord) reason = 'Forbidden Word';
                    else if (isNextForbidden) reason = 'Next Word Forbidden';
                    else if (isSingularNoun) reason = 'Singular Noun';
                    else if (isAfterVerb) reason = 'After Verb';
                    else if (isAdverbInMent) reason = 'Adverb -ment';
                    else if (isProperNoun) reason = 'Proper Noun';
                    else if (isRealInterrogativeQuestion) reason = 'Interrogative Question';
                    else if (followsInversion) reason = 'Follows Inversion';
                    else if (isPrepositionBeforeProperNoun) reason = 'Prep + Proper Noun';

                    omissions.push({word1: currentWord, word2: nextWord, rule: reason});
                    continue;
                }

                let shouldInsertLiaison = false;

                if (isFixedExpression) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Fixed Expression';
                } else if (current === "c'est" || current === "s'est") {
                    shouldInsertLiaison = true;
                    triggeredRule = 'C\'est / S\'est';
                } else if (isPluralNounAdjective) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Plural Noun + Adjective';
                } else if ((currentTagSet.has('Determiner') || obligatoryTriggers.determiners.has(current)) &&
                    (nextTagSet.has('Noun') || nextTagSet.has('Adjective') || next === 'œuvre')) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Determiner + Noun/Adjective';
                } else if ((currentTagSet.has('Pronoun') || obligatoryTriggers.pronouns.has(current)) &&
                    (nextTagSet.has('Verb') || safeVerbs.has(next) || auxiliaryVerbs.has(next))) {
                    if (auxiliaryVerbs.has(current) && nextTagSet.has('Participle')) {
                        shouldInsertLiaison = true;
                        triggeredRule = 'Auxiliary + Participle';
                    } else if (!auxiliaryVerbs.has(current)) {
                        shouldInsertLiaison = true;
                        triggeredRule = 'Pronoun + Verb';
                    }
                } else if (obligatoryTriggers.pronouns.has(current) && (safeVerbs.has(next) || auxiliaryVerbs.has(next))) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Pronoun + Safe Verb';
                } else if ((currentTagSet.has('Numeral') || obligatoryTriggers.numbers.has(current)) &&
                    (nextTagSet.has('Noun') || nextTagSet.has('Adjective') || next === 'heures')) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Number + Noun/Adjective';
                } else if ((currentTagSet.has('Adverb') || obligatoryTriggers.adverbs.has(current) || ['tant', 'autant', 'trop', 'fort'].includes(current)) &&
                    (nextTagSet.has('Adjective') || nextTagSet.has('Adverb') || nextTagSet.has('Preposition') ||
                        nextTagSet.has('Participle') || nextTagSet.has('Pronoun') || next === 'ou' ||
                        next === 'avoir' || next === 'etre' || next === 'elle' || next === 'il' || next === 'on')) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Adverb + Complement';
                } else if ((currentTagSet.has('Preposition') || obligatoryTriggers.prepositions.has(current)) &&
                    (nextTagSet.has('Pronoun') || nextTagSet.has('Determiner') || nextTagSet.has('Numeral') ||
                        obligatoryTriggers.pronouns.has(next) || nextTagSet.has('Noun') ||
                        nextTagSet.has('Verb') || next === 'avoir' || next === 'etre' ||
                        safeVerbs.has(next) || auxiliaryVerbs.has(next))) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Preposition + Complement';
                } else if ((currentTagSet.has('Adjective') || obligatoryTriggers.adjectives.has(current)) &&
                    (nextTagSet.has('Noun') || next === 'œuvre')) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Adjective + Noun';
                } else if (obligatoryTriggers.determiners.has(current) ||
                    obligatoryTriggers.pronouns.has(current) ||
                    obligatoryTriggers.numbers.has(current)) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Obligatory Trigger';
                } else if (current === 'tout' && (next === 'est' || next === 'a' || next === 'etre' || next === 'avoir' || nextTagSet.has('Adjective'))) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Tout + Être/Avoir';
                } else if (current === 'en') {
                    shouldInsertLiaison = true;
                    triggeredRule = 'En (Pronoun/Prep)';
                } else if (current === 'rien' && (nextTagSet.has('Preposition') || next === 'a')) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Rien + Preposition';
                } else if (current === 'chacun' && (nextTagSet.has('Verb') || safeVerbs.has(next) || auxiliaryVerbs.has(next) || vowels.has(firstChar))) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Chacun + Verb';
                } else if (current === 'apres' && (next === 'avoir' || next === 'etre')) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Après + Aux';
                } else if (safeVerbs.has(current)) {
                    if ((current === 'avez' || current === 'avons' || current === 'ont') &&
                        (next === 'eu' || next === 'été')) {
                        shouldInsertLiaison = false;
                        omissions.push({word1: currentWord, word2: nextWord, rule: 'Eu/Ete Exclusion'});
                    } else if (nextTagSet.has('Participle') || nextTagSet.has('Adjective') || nextTagSet.has('Noun') || nextTagSet.has('Adverb') || nextTagSet.has('Verb') || nextTagSet.has('Determiner')) {
                        shouldInsertLiaison = true;
                        triggeredRule = 'Safe Verb + Complement';
                    }
                } else if (vowels.has(firstChar)) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Vowel Start (Generic)';
                } else if (safeVerbs.has(current)) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Safe Verb (Generic)';
                } else if (isVerbSubjectInversion && !isInvertedPronoun) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Verb Subject Inversion';
                } else if (isSangImpur) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Sang Impur';
                } else if (auxiliaryVerbs.has(current) && (nextTagSet.has('Participle') || nextTagSet.has('Adjective'))) {
                    shouldInsertLiaison = true;
                    triggeredRule = 'Auxiliary + Participle';
                } else if (['est', 'sont', 'ont', 'suis', 'sommes', 'êtes', 'étais', 'était', 'étaient', 'ai', 'as', 'a', 'avons', 'avez',
                    'dois', 'doit', 'peut', 'veux', 'veut', 'vais', 'vas', 'va', 'allons', 'allez', 'vont']
                    .includes(current)) {
                    if (startsWithVowel || startsWithMuteH) {
                        shouldInsertLiaison = true;
                        triggeredRule = 'Common Verb Form';
                    }
                }

                if (shouldInsertLiaison) {
                    liaisons.push({
                        word1: currentWord,
                        word2: nextWord,
                        rule: triggeredRule || 'Unknown Rule'
                    });

                    if (lastChar === 'n' || lastChar === 'm') {
                        if (nasalPreserveGroup.has(current) || nasalDenasalGroup.has(current)) {
                            result.push('‿');
                        } else {
                            result.push(postPunctuation || ' ');
                        }
                    } else {
                        result.push('‿');
                    }
                } else {
                    result.push(postPunctuation || ' ');
                    omissions.push({word1: currentWord, word2: nextWord, rule: 'No matching rule (Generic)'});
                }
            } else {
                result.push(postPunctuation || ' ');
            }
        } else {
            result.push(currentTerm.post || '');
        }
    }

    return {text: result.join(''), liaisons: liaisons, omissions: omissions};
}

// Convenience function to get just the text with liaison markers
const insertLiaisonMarkersText = (text) => insertLiaisonMarkers(text).text;