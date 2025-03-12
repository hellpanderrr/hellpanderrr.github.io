import { languages } from "./languages.js";

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
  }
} catch (err) {
  console.log(err);
}
