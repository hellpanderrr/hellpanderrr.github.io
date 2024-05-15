self.onmessage = function (e) {
  const splitAndAppend = (str, delim, count) => {
    const index = str.indexOf(delim);
    return [str.slice(0, index), str.slice(index + 1)];
  };
  const split = e.data.split(/\r?\n/);
  const lines = [];

  for (let index = 0; index < split.length; index++) {
    const [text, ipa] = splitAndAppend(split[index], "\t", 1);
    lines.push([text, ipa.split(" ").join("")]);
  }

  const dict = new Map(lines.reverse());
  self.postMessage(dict);
};
