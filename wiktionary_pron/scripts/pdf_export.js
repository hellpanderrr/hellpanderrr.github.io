import { loadJs } from "./utils.js";

async function toPdf(layoutType, darkMode, transcriptionLang) {
  await loadJs(
    "https://unpkg.com/@pdf-lib/fontkit/dist/fontkit.umd.min.js",
    async () => {
      await loadJs(
        "https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js",
        async () => {
          await main(layoutType, darkMode, transcriptionLang);
        },
      );
    },
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

  const [GaramondBytes, VocesBytes] = await Promise.all([
    fetchAsset("fonts/EBGaramond-Regular.ttf"),
    fetchAsset(
      "https://cdn.jsdelivr.net/gh/hellpanderrr/hellpanderrr.github.io/wiktionary_pron/fonts/Voces-Regular.ttf",
    ),
  ]);
  fonts = [GaramondBytes, VocesBytes];
  return fonts;
}

async function main(layoutType, darkMode, transcriptionLang) {
  /** @namespace PDFLib **/
  const { PageSizes, PDFDocument, rgb } = PDFLib;

  console.log(PDFDocument);

  const fillDoc = async (pdfDoc, layoutType, darkMode) => {
    pdfDoc.registerFontkit(fontkit);

    const [GaramondBytes, VocesBytes] = await fetchFonts();

    const Garamond = await pdfDoc.embedFont(GaramondBytes);
    const Voces = await pdfDoc.embedFont(VocesBytes);

    function fillPage(page, color = rgb(0.18, 0.18, 0.18)) {
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      page.drawRectangle({
        color: color,
        width: pageWidth + 10,
        height: pageHeight + 10,
      });
    }

    function putDivsLineByLine(lines, pdfDoc, fontSize, darkMode) {
      let x = 50;
      let y = 750;
      let page = pdfDoc.addPage(PageSizes.Letter);
      if (darkMode) {
        fillPage(page);
      }
      const spaceWidth = Math.max(
        Voces.widthOfTextAtSize(" ", fontSize),
        Garamond.widthOfTextAtSize(" ", fontSize),
      );
      const lineHeight = Math.max(
        Voces.heightAtSize(fontSize),
        Garamond.heightAtSize(fontSize),
      );

      function nextPageTransition(y, pdfDoc, pageHeight, darkMode) {
        if (y < 50) {
          page = pdfDoc.addPage(PageSizes.Letter);
          if (darkMode) {
            fillPage(page);
          }
          y = pageHeight - 50;
        }
        return [y, page];
      }

      function newLineTransition(x, y, lineHeight) {
        x = 50;
        y -= 2 * lineHeight;
        return [x, y];
      }

      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      lines.forEach((divs) => {
        divs.forEach((div) => {
          const cell = div.querySelectorAll("div");
          const [word, ipa] = [cell[0].textContent, cell[1].textContent];
          const wordWidth = Math.max(
            Voces.widthOfTextAtSize(ipa, fontSize),
            Garamond.widthOfTextAtSize(word, fontSize),
          );
          const isNewLine = x + wordWidth > pageWidth - 40;
          if (isNewLine) {
            [x, y] = newLineTransition(x, y, lineHeight);
            [y, page] = nextPageTransition(y, pdfDoc, pageHeight, darkMode);
          }
          const color = darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0);
          page.drawText(word, {
            font: Garamond,
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
        [x, y] = newLineTransition(x, y, lineHeight);
        [y, page] = nextPageTransition(y, pdfDoc, pageHeight, darkMode);
      });
    }

    function putDivsSideBySide(lines, pdfDoc, fontSize) {
      let page = pdfDoc.addPage(PageSizes.Letter);
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      let xLeft = 50;
      let xRight = pageWidth / 2 + 20;
      let y = 750;
      if (darkMode) {
        fillPage(page);
      }
      const wordFontSize = fontSize;
      const ipaFontSize = fontSize - 2;
      const spaceWidth = Math.max(
        Garamond.widthOfTextAtSize(" ", wordFontSize),
        Voces.widthOfTextAtSize(" ", ipaFontSize),
      );
      const lineHeight = Math.max(
        Garamond.heightAtSize(wordFontSize),
        Voces.heightAtSize(ipaFontSize),
      );

      function nextPageTransition(y, pdfDoc, pageHeight, darkMode) {
        if (y < 50) {
          page = pdfDoc.addPage(PageSizes.Letter);
          y = pageHeight - 50;
          if (darkMode) {
            fillPage(page);
          }
        }
        return [y, page];
      }

      function newLineTransition(xLeft, xRight, y, pageWidth) {
        xLeft = 50;
        xRight = pageWidth / 2 + 20;
        y -= lineHeight;
        return [xLeft, xRight, y];
      }

      lines.forEach((line, index) => {
        const columns = line.querySelectorAll(":scope > div");

        const words = columns[0].querySelectorAll("div.cell");
        const ipas = columns[1].querySelectorAll("div.cell");

        words.forEach((word, index) => {
          const ipa = ipas[index].textContent;
          word = word.textContent;

          const wordWidth = Math.max(
            Garamond.widthOfTextAtSize(word, wordFontSize),
          );
          const ipaWidth = Math.max(Voces.widthOfTextAtSize(ipa, ipaFontSize));
          const isNewLine = xLeft + wordWidth > pageWidth / 2 - 20;
          if (isNewLine) {
            [xLeft, xRight, y] = newLineTransition(xLeft, xRight, y, pageWidth);
            [y, page] = nextPageTransition(y, pdfDoc, pageHeight, darkMode);
          }
          page.drawText(word.trim(), {
            font: Garamond,
            x: xLeft,
            y: y,
            size: fontSize,
            color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
          });
          page.drawText(ipa.trim(), {
            font: Voces,
            x: xRight,
            y: y,
            size: ipaFontSize,
            color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
          });

          if (word.trim() !== "") {
            xLeft += wordWidth + spaceWidth; // Add a small space between words
            xRight += ipaWidth + spaceWidth; // Add a small space between words
          }
        });
        [xLeft, xRight, y] = newLineTransition(xLeft, xRight, y, pageWidth);
        [y, page] = nextPageTransition(y, pdfDoc, pageHeight, darkMode);
      });
    }

    function putDivsDefault(rows, pdfDoc, fontSize) {
      let x = 50;
      let y = 750;
      let page = pdfDoc.addPage(PageSizes.Letter);
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      if (darkMode) {
        fillPage(page);
      }
      const spaceWidth = Voces.widthOfTextAtSize(" ", fontSize);
      const lineHeight = Math.max(
        Voces.heightAtSize(fontSize),
        Garamond.heightAtSize(fontSize),
      );

      function newLineTransition(x, y, lineHeight) {
        x = 50;
        y -= lineHeight;
        return [x, y];
      }

      function nextPageTransition(y, pdfDoc, darkMode) {
        if (y < 50) {
          page = pdfDoc.addPage(PageSizes.Letter);
          y = pageHeight - 50;
          if (darkMode) {
            fillPage(page);
          }
        }
        return [y, page];
      }

      rows.forEach((row) => {
        const divs = row.querySelectorAll("div.cell");
        divs.forEach((div, index) => {
          const ipa = div.textContent;

          const wordWidth = Voces.widthOfTextAtSize(ipa, fontSize);
          const isNewLine = x + wordWidth > pageWidth - 40;
          if (isNewLine) {
            [x, y] = newLineTransition(x, y, lineHeight);
            [y, page] = nextPageTransition(y, pdfDoc, darkMode);
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
        [x, y] = newLineTransition(x, y, lineHeight);
        [y, page] = nextPageTransition(y, pdfDoc, darkMode);
      });
    }

    const getTableRows = () => {
      return document.querySelectorAll("#result > tr");
    };
    const getTableRowsUnpacked = () => {
      const rows = getTableRows();
      return Array.from(rows).map((x) => x.querySelectorAll("div.cell"));
    };
    const rowsUnpacked = getTableRowsUnpacked();
    const rows = getTableRows();
    switch (layoutType) {
      case "line":
        putDivsLineByLine(rowsUnpacked, pdfDoc, 15, darkMode);
        break;
      case "sideBySide":
        putDivsSideBySide(rows, pdfDoc, 15, darkMode);
        break;
      case "default":
        putDivsDefault(rows, pdfDoc, 15, darkMode);
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
