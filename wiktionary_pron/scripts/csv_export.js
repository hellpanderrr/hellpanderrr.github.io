async function toCsv(lines, layoutType, transcriptionLang) {
  await main(lines, layoutType, transcriptionLang);
}

async function main(lines, layoutType, transcriptionLang) {
  function convertToCSV(lines, layoutType) {
    let csvContent = [];

    switch (layoutType) {
      case "line":
        csvContent.push("Text\tIPA");
        // Format: word\tIPA
        lines.forEach((cells) => {
          cells.forEach((cell) => {
            const word = cell.text.normalize("NFKC");
            const ipa = cell.ipa.normalize("NFC").trim();
            csvContent.push(`"${word}"\t"${ipa}"`);
          });
          csvContent.push(""); // Empty line between groups
        });
        break;

      case "sideBySide":
        // Add headers
        csvContent.push("Text\tIPA");

        // Format: text and IPA in separate columns with tab separator
        lines.forEach((line) => {
          const words = line.text
            .map((word) => word.normalize("NFKC"))
            .join(" ");
          const ipas = line.ipa
            .map((ipa) => ipa.normalize("NFC").trim())
            .join(" ");
          csvContent.push(`${words}\t${ipas}`);
        });
        break;

      case "default":
        // Format: IPA only
        lines.forEach((row) => {
          if (row) {
            console.log(row);
            const ipas = row.map((cell) => `${cell.normalize("NFC").trim()}`);
            csvContent.push(ipas.join(" "));
          }
        });
        console.log(csvContent);
        break;
    }

    return csvContent.join("\n");
  }

  function saveFile(content, filename) {
    const blob = new Blob([content], { type: "text/csv;charset=utf-8;" });

    if (window.navigator.msSaveOrOpenBlob) {
      window.navigator.msSaveOrOpenBlob(blob, filename);
    } else {
      const a = document.createElement("a");
      document.body.appendChild(a);
      const url = window.URL.createObjectURL(blob);
      a.href = url;
      a.download = filename;
      a.click();
      setTimeout(() => {
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }, 0);
    }
  }

  async function exportCsv(lines, layoutType, transcriptionLang) {
    const csvContent = convertToCSV(lines, layoutType);

    const layoutTypeStr = layoutType === "default" ? "" : layoutType;
    const dateStr = new Date().toJSON();
    const transcriptionLangStr = transcriptionLang ? transcriptionLang : "";
    const filename = `transcription_${transcriptionLangStr}_${layoutTypeStr}_${dateStr}.csv`;

    saveFile(csvContent, filename);
  }

  await exportCsv(lines, layoutType, transcriptionLang);
}

export { toCsv };
