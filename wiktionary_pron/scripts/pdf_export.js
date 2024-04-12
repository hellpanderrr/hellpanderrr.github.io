const loadedScripts = {};

function loadJs(url, code) {
  if (loadedScripts[url]) {
    code();
    return;
  }
  loadedScripts[url] = true;

  var script = document.createElement("script");
  script.onload = code;
  script.src = url;

  document.head.appendChild(script);
}

function toPdf(layoutType, darkMode, transcriptionLang) {
  loadJs("https://unpkg.com/@pdf-lib/fontkit/dist/fontkit.umd.min.js", () =>
    loadJs("https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js", () =>
      main(layoutType, darkMode, transcriptionLang),
    ),
  );
}

let fonts = [];

async function fetchFonts() {
  if (fonts.length) {
    return fonts;
  }
  const fetchAsset = (asset) =>
    fetch(`${asset}`)
      .then((res) => res.arrayBuffer())
      .then((res) => new Uint8Array(res));

  const [GaramdondBytes, VocesBytes] = await Promise.all([
    fetchAsset(
      "https://cdn.jsdelivr.net/gh/hellpanderrr/hellpanderrr.github.io/wiktionary_pron/fonts/GoudyBookletter1911-Regular.ttf",
    ),
    fetchAsset(
      "https://cdn.jsdelivr.net/gh/hellpanderrr/hellpanderrr.github.io/wiktionary_pron/fonts/Voces-Regular.ttf",
    ),
  ]);
  fonts = [GaramdondBytes, VocesBytes];
  return fonts;
}

async function main(layoutType, darkMode, transcriptionLang) {
  const { PageSizes, PDFDocument, rgb } = PDFLib;

  console.log(PDFDocument);

  const fillDoc = async (pdfDoc, layoutType, darkMode) => {
    pdfDoc.registerFontkit(fontkit);

    const [GaramdondBytes, VocesBytes] = await fetchFonts();

    const Garamdond = await pdfDoc.embedFont(GaramdondBytes);
    const Voces = await pdfDoc.embedFont(VocesBytes);

    function fillPage(page, color = rgb(0.18, 0.18, 0.18)) {
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      page.drawRectangle({
        color: color,
        width: pageWidth,
        height: pageHeight + 10,
      });
    }

    function putDivsLineByLine(divs, pdfDoc, lineHeight, fontSize, darkMode) {
      console.log(darkMode);
      let x = 50;
      let y = 750;
      let page = pdfDoc.addPage(PageSizes.Letter);
      if (darkMode) {
        fillPage(page);
      }
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      divs.forEach((div, index) => {
        const divs = div.querySelectorAll("div");
        const [word, ipa] = [divs[0].textContent, divs[1].textContent];

        const wordWidth = Math.max(
          Voces.widthOfTextAtSize(ipa, fontSize),
          Garamdond.widthOfTextAtSize(word, fontSize),
        );
        const spaceWidth = Math.max(
          Voces.widthOfTextAtSize(" ", fontSize),
          Garamdond.widthOfTextAtSize(" ", fontSize),
        );
        const lineHeight = Math.max(
          Voces.heightAtSize(fontSize),
          Garamdond.heightAtSize(fontSize),
        );

        if (x + wordWidth > pageWidth - 40) {
          x = 50;
          y -= 2 * lineHeight;
          if (y < 100) {
            page = pdfDoc.addPage(PageSizes.Letter);
            if (darkMode) {
              fillPage(page);
            }
            y = 750;
          }
        }
        const color = darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0);
        page.drawText(word, {
          font: Garamdond,
          x: x,
          y: y,
          size: fontSize,
          color: color,
        });
        page.drawText(ipa, {
          font: Voces,
          x: x,
          y: y - lineHeight,
          size: fontSize,
          color: color,
        });

        x += wordWidth + 5 + spaceWidth; // Add a small space between words
      });
    }

    function putDivsSideBySide(words, ipas, pdfDoc, lineHeight, fontSize) {
      let page = pdfDoc.addPage(PageSizes.Letter);
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      let xLeft = 50;
      let xRight = pageWidth / 2 + 20;
      let y = 750;
      if (darkMode) {
        fillPage(page);
      }
      words.forEach((word, index) => {
        const ipa = ipas[index].textContent;
        word = word.textContent;
        const wordFontSize = fontSize;
        const ipaFontSize = fontSize - 2;
        const wordWidth = Math.max(
          Garamdond.widthOfTextAtSize(word, wordFontSize),
        );
        const ipaWidth = Math.max(Voces.widthOfTextAtSize(ipa, ipaFontSize));
        const spaceWidth = Math.max(
          Garamdond.widthOfTextAtSize(" ", wordFontSize),
          Voces.widthOfTextAtSize(" ", ipaFontSize),
        );
        const lineHeight = Math.max(
          Garamdond.heightAtSize(wordFontSize),
          Voces.heightAtSize(ipaFontSize),
        );

        if (xLeft + wordWidth > pageWidth / 2 - 20) {
          xLeft = 50;
          xRight = pageWidth / 2 + 20;
          y -= lineHeight;
          if (y < 50) {
            page = pdfDoc.addPage(PageSizes.Letter);
            y = pageHeight - 50;
            if (darkMode) {
              page.drawRectangle({
                color: rgb(0.18, 0.18, 0.18),
                width: page.getWidth(),
                height: page.getHeight(),
              });
            }
          }
        }
        page.drawText(word, {
          font: Garamdond,
          x: xLeft,
          y: y,
          size: fontSize,
          color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
        });
        page.drawText(ipa, {
          font: Voces,
          x: xRight,
          y: y,
          size: ipaFontSize,
          color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
        });

        xLeft += wordWidth + spaceWidth; // Add a small space between words
        xRight += ipaWidth + spaceWidth; // Add a small space between words
      });
    }

    function putDivsDefault(divs, pdfDoc, lineHeight, fontSize) {
      console.log(divs);
      let x = 50;
      let y = 750;
      let page = pdfDoc.addPage(PageSizes.Letter);
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      if (darkMode) {
        fillPage(page);
      }
      divs.forEach((div, index) => {
        const ipa = div.textContent;

        const wordWidth = Voces.widthOfTextAtSize(ipa, fontSize);
        const spaceWidth = Voces.widthOfTextAtSize(" ", fontSize);
        const lineHeight = Math.max(
          Voces.heightAtSize(fontSize),
          Garamdond.heightAtSize(fontSize),
        );

        if (x + wordWidth > pageWidth - 40) {
          x = 50;
          y -= lineHeight;
          if (y < 100) {
            page = pdfDoc.addPage(PageSizes.Letter);
            y = 750;
            if (darkMode) {
              fillPage(page);
            }
          }
        }
        page.drawText(ipa, {
          font: Voces,
          x: x,
          y: y,
          size: fontSize,
          color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
        });

        x += wordWidth + 5 + spaceWidth; // Add a small space between words
      });
    }

    let items;
    switch (layoutType) {
      case "line":
        items = document.querySelectorAll("div.cell");
        putDivsLineByLine(items, pdfDoc, 50, 15, darkMode);
        break;
      case "sideBySide":
        const words = document.querySelectorAll("span.input_text");
        const ipas = document.querySelectorAll("span.ipa,span.error");
        putDivsSideBySide(words, ipas, pdfDoc, 50, 15, darkMode);
        break;
      case "default":
        items = document.querySelectorAll("tbody span");
        putDivsDefault(items, pdfDoc, 50, 15, darkMode);
        break;
    }
  };

  async function exportPdf(layoutType, darkMode, transcriptionLang) {
    const pdfDoc = await PDFDocument.create();
    await fillDoc(pdfDoc, layoutType, darkMode);

    const pdfBytes = await pdfDoc.save();

    function saveFile(blob, filename) {
      if (window.navigator.msSaveOrOpenBlob) {
        window.navigator.msSaveOrOpenBlob(blob, filename);
      } else {
        const a = document.createElement("a");
        document.body.appendChild(a);
        const blobObj = new Blob([blob], { type: "application/pdf" });
        const url = window.URL.createObjectURL(blobObj);
        a.href = url;
        a.download = filename;
        a.click();
        setTimeout(() => {
          window.URL.revokeObjectURL(url);
          document.body.removeChild(a);
        }, 0);
      }
    }
    const darkModeStr = darkMode ? "dark" : "light";
    const layoutTypeStr = layoutType === "default" ? "" : layoutType;
    const dateStr = new Date().toJSON();
    const transcriptionLangStr = transcriptionLang ? transcriptionLang : "";
    const filename = `transcription_${transcriptionLangStr}_${darkModeStr}_${layoutTypeStr}_${dateStr}.pdf`;

    await saveFile(pdfBytes, filename);
  }

  await exportPdf(layoutType, darkMode, transcriptionLang);
}

export { toPdf };
