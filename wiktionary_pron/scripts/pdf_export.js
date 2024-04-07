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

function toPdf(type, darkMode) {
  loadJs("https://unpkg.com/@pdf-lib/fontkit/dist/fontkit.umd.js", () =>
    loadJs("https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js", () =>
      main(type, darkMode),
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

async function main(type, darkMode) {
  const { PageSizes, PDFDocument, rgb } = PDFLib;

  console.log(PDFDocument);

  const fillDoc = async (pdfDoc, type, darkMode) => {
    pdfDoc.registerFontkit(fontkit);

    const [GaramdondBytes, VocesBytes] = await fetchFonts();

    const Garamdond = await pdfDoc.embedFont(GaramdondBytes);
    const Voces = await pdfDoc.embedFont(VocesBytes);

    function putDivsLineByLine(divs, pdfDoc, lineHeight, fontSize, darkMode) {
      console.log(darkMode);
      let x = 50;
      let y = 750;
      let page = pdfDoc.addPage(PageSizes.Letter);
      if (darkMode) {
        page.drawRectangle({
          color: rgb(0.18, 0.18, 0.18),
          width: page.getWidth(),
          height: page.getHeight(),
        });
      }
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      divs.forEach((div, index) => {
        const divs = div.querySelectorAll("div");
        const word = divs[0].textContent;
        const ipa = divs[1].textContent;

        function max(array) {
          return Math.max.apply(Math, array);
        }

        const wordWidth = max([
          Voces.widthOfTextAtSize(ipa, fontSize),
          Garamdond.widthOfTextAtSize(word, fontSize),
        ]);
        const spaceWidth = max([
          Voces.widthOfTextAtSize(" ", fontSize),
          Garamdond.widthOfTextAtSize(" ", fontSize),
        ]);
        const lineHeight = max([
          Voces.heightAtSize(fontSize),
          Garamdond.heightAtSize(fontSize),
        ]);

        if (x + wordWidth > pageWidth - 40) {
          x = 50;
          y -= 2 * lineHeight;
          if (y < 100) {
            page = doc.addPage(PageSizes.Letter);
            if (darkMode) {
              page.drawRectangle({
                color: rgb(0.18, 0.18, 0.18),
                width: page.getWidth(),
                height: page.getHeight(),
              });
            }
            y = 750;
          }
        }
        page.drawText(word, {
          font: Garamdond,
          x: x,
          y: y,
          size: fontSize,
          color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
        });
        page.drawText(ipa, {
          font: Voces,
          x: x,
          y: y - lineHeight,
          size: fontSize,
          color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
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
        page.drawRectangle({
          color: rgb(0.18, 0.18, 0.18),
          width: page.getWidth(),
          height: page.getHeight(),
        });
      }
      words.forEach((word, index) => {
        const ipa = ipas[index].textContent;
        word = word.textContent;

        function max(array) {
          return Math.max.apply(Math, array);
        }

        const wordWidth = max([
          Voces.widthOfTextAtSize(ipa, fontSize),
          Garamdond.widthOfTextAtSize(word, fontSize),
        ]);
        const spaceWidth = max([
          Voces.widthOfTextAtSize(" ", fontSize),
          Garamdond.widthOfTextAtSize(" ", fontSize),
        ]);
        const lineHeight = max([
          Voces.heightAtSize(fontSize),
          Garamdond.heightAtSize(fontSize),
        ]);

        if (xLeft + wordWidth > pageWidth / 2 - 20) {
          xLeft = 50;
          xRight = pageWidth / 2 + 20;
          y -= 2 * lineHeight;
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
          size: fontSize,
          color: darkMode ? rgb(1, 1, 1) : rgb(0, 0, 0),
        });

        xLeft += wordWidth + 5 + spaceWidth; // Add a small space between words
        xRight += wordWidth + 5 + spaceWidth; // Add a small space between words
      });
    }

    function putDivsDefault(divs, pdfDoc, lineHeight, fontSize) {
      console.log(divs);
      let x = 50;
      let y = 750;
      let page = pdfDoc.addPage(PageSizes.Letter);
      const [pageWidth, pageHeight] = [page.getWidth(), page.getHeight()];
      if (darkMode) {
        page.drawRectangle({
          color: rgb(0.18, 0.18, 0.18),
          width: pageWidth,
          height: pageHeight,
        });
      }
      divs.forEach((div, index) => {
        const ipa = div.textContent;

        function max(array) {
          return Math.max.apply(Math, array);
        }

        const wordWidth = max([Voces.widthOfTextAtSize(ipa, fontSize)]);
        const spaceWidth = max([
          Voces.widthOfTextAtSize(" ", fontSize),
          Garamdond.widthOfTextAtSize(" ", fontSize),
        ]);
        const lineHeight = max([
          Voces.heightAtSize(fontSize),
          Garamdond.heightAtSize(fontSize),
        ]);

        if (x + wordWidth > pageWidth - 40) {
          x = 50;
          y -= 2 * lineHeight;
          if (y < 100) {
            page = doc.addPage(PageSizes.Letter);
            y = 750;
            if (darkMode) {
              page.drawRectangle({
                color: rgb(0.18, 0.18, 0.18),
                width: page.getWidth(),
                height: page.getHeight(),
              });
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
    switch (type) {
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

  async function exportPdf(type, darkMode) {
    const pdfDoc = await PDFDocument.create();
    await fillDoc(pdfDoc, type, darkMode);

    const pdfBytes = await pdfDoc.save();

    function saveFile(blob, filename) {
      if (window.navigator.msSaveOrOpenBlob) {
        window.navigator.msSaveOrOpenBlob(blob, filename);
      } else {
        const a = document.createElement("a");
        document.body.appendChild(a);
        var blobObj = new Blob([blob], { type: "application/pdf" });
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

    await saveFile(pdfBytes, "transcription_" + new Date().toJSON() + ".pdf");
  }

  await exportPdf(type, darkMode);
}

export { toPdf };
