import { languages } from "./languages.js";

const sampleTexts = {
  Latin: `Abecedarium Phoneticum Internationale, saepe notum ob litteras primas nominis Anglici IPA (International Phonetic Alphabet), sive Francogallici API (Alphabet phonétique international), est abecedarium phoneticum, a linguistis Francicis et Britannicis anno 1888 excogitatum, cuius ratio creandi est sonos omnium linguarum eodem orthographiae systemate explicare.`,
  German: `Das Internationale Phonetische Alphabet (kurz IPA) ist ein phonetisches Alphabet und somit eine Sammlung von Zeichen, mit deren Hilfe die Laute aller menschlichen Sprachen nahezu genau beschrieben und notiert werden können. Es wurde von der International Phonetic Association (kurz IPA) entwickelt, kam in seinem ersten Entwurf 1888 heraus und ist die heute am weitesten verbreitete Lautschrift.`,
  Polish: `Transkrypcja fonetyczna (zwana również transkrypcją wąską lub alofoniczną) – system pisowni lub system konwersji pisma oparty na zasadzie ścisłej odpowiedniości głosek i liter - jednej głosce odpowiada tu zawsze jeden znak (czasem z diakrytyką), a jednemu znakowi jedna głoska. W węższym rozumieniu jest to sposób zapisu wymowy danego języka za pomocą ustalonego wzorca zrozumiałego także dla osób nieznających obowiązujących w piśmie tego języka zasad ortografii`,
  French: `Une transcription phonétique est une méthode de transcription plus ou moins formalisée des sons d'une ou de plusieurs langues.
Cette transcription rend normalement une approximation de la prononciation standard de la langue. Les variantes dialectales et individuelles sont difficiles à rendre dans la transcription.`,
  Greek: `Φωνητική καταγραφή (ή φωνητική σημείωση) είναι η οπτική αντιπροσώπευση των ήχων (ή των φώνων) της ομιλίας. Ο πιο κοινός τύπος φωνητικής καταγραφής χρησιμοποιεί ένα φωνητικό αλφάβητο π.χ. το Διεθνές Φωνητικό Αλφάβητο.`,
  Armenian: `Միջազգային հնչյունական այբուբենը  գրանշանների հնչյունային համակարգ է՝ տառադարձությունների գրառության համար, ստեղծված լեզվաբանների կողմից։ Այն նախատեսված է ստանդարտ, ճշգրիտ և միանշանակ ձևով աշխարհի բոլոր լեզուների հնչյունների գրառության համար։`,
  Czech: `Mezinárodní fonetická abeceda  je znakový systém navržený jazykovědci k fonetickému zápisu a popisu hlasových projevů lidí mluvících rozdílnými jazyky. Úkolem mezinárodní fonetické abecedy je věrně, výstižně a široce zachytit mluvený projev lidí různých jazykových skupin, tak aby byl fonémicky a foneticky správný.`,
  Russian: `Фонетическая транскрипция — графическая запись звучания слова и один из видов транскрипции.
Фонетическая транскрипция преследует цели точной графической записи произношения. Каждый отдельный звук (и в некоторых языках его варианты) должен быть отдельно зафиксирован в записи. Фонетическая транскрипция пишется в квадратных скобках. Упрощённая фонетическая транскрипция используется в школьном фонетическом разборе слова. Одна из первых систем унифицированной фонетической транскрипции, именуемая «Стандартным алфавитом», принадлежит Карлу Рихарду Лепсиусу, однако уже в начале XX столетия она считалась устарелой`,
  Ukrainian: `Фонетична транскрипція може бути використана для транскрипції фонем мови, або вона може піти далі та вказати їх точну фонетичну реалізацію. У всіх системах транскрипції розрізняють широку транскрипцію та вузьку транскрипцію. Широка транскрипція вказує лише на найбільш помітні фонетичні особливості мовлення, тоді як вузька транскрипція надає більше даних про фонетичні характеристики алофонів у мовленні.`,
  Portuguese: `Uma transcrição fonética é um método mais ou menos formalizado de transcrever os sons de uma ou várias línguas.
Esta transcrição normalmente se aproxima de maneira padrão de pronunciar determinada língua. As variantes dialetais e individuais são dificilmente representadas na transcrição. As variantes de uma mesmo fonema (alofonia) são quase nunca representados. Alfabetos especiais como o alfabeto fonético internacional foram criados para realizar transcrições.`,
  Spanish: `La transcripción fonética (o notación fonética) es un sistema de símbolos gráficos para representar los sonidos del habla humana. Típicamente se usa como convención para superar las peculiaridades alfabéticas usadas en cada lengua escrita y también para representar lenguas sin tradición escrita.`,
  Belorussian: `Фанетычная транскрыпцыя беларускай мовы адлюстроўвае асаблівасці беларускага вуснага маўлення. Яна ажыццяўляецца паводле спецыяльнай сістэмы запісу. Кожная літара ў транскрыпцыі абазначае толькі адзін гук (а не спалучэнне гукаў) і заключаецца ў квадратныя дужкі [ ]. Беларуская транскрыпцыя грунтуецца на базе літар беларускага алфавіта. Але паколькі ў беларускай мове гукаў больш, чым літар, то для абазначэння некаторых гукаў выкарыстоўваюцца асобныя літары з іншых графічных сістэм (лацінскай, грэчаскай), а таксама спецыяльныя дыякрытычныя значкі.`,
  Bulgarian: `Международната фонетична азбука (МФА) (на английски: International Phonetic Alphabet, IPA) е система за фонетична транскрипция създадена за употреба от езиковедите. Тя е предназначена да представи стандартизирано, точно и еднозначно всеки звуков елемент в човешкия език, разпознат като фонема`,
  Lithuanian: `Tarptautinė fonetinė abėcėlė arba TFA – abėcėlinė fonetinio žymėjimo sistema, paremta lotynų abėcėle. Ją sukūrė Tarptautinė fonetikos asociacija, siekdama sunorminti įvairių kalbų garsų užrašymą. Tarptautinę fonetinę abėcėlę naudoja leksikografai, žmonės, kurie moko(si) užsienio kalbų, lingvistai, kalbos ir kalbėsenos patologai, dainininkai, aktoriai, dirbtinių kalbų kūrėjai bei vertėjai.`,
};

try {
  const urlParams = new URLSearchParams(window.location.search);
  const selectedLanguage = urlParams.get("lang");
  if (selectedLanguage) {
    document.title = `Online ${selectedLanguage} IPA transcription`;
    const lang = languages[selectedLanguage];
    if (lang) {
      const availableStyles = lang.styles.join(", ");
      const availableForms = lang.forms
        .map((form) => form.toLowerCase())
        .join("/");
      document.head.children.description.content = `Online ${selectedLanguage} to IPA ${availableForms} transcription generator. Dialects: ${availableStyles}`;
    }
    document.querySelector("#text_to_transcribe").value =
      sampleTexts[selectedLanguage];
    console.log("sample text", sampleTexts[selectedLanguage]);
  }
} catch (err) {
  console.log(err);
}
