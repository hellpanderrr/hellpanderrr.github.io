self.onmessage = function (e) {
  dict = new Map(JSON.parse(e.data));
  self.postMessage(dict);
};
