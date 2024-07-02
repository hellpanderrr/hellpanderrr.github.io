self.onmessage = function (e) {
  console.time("B");

  json = JSON.parse(e.data);
  console.timeLog("B");
  // dict = new Map(Object.entries(json));
  // console.timeEnd("A");
  self.postMessage(json);
};
