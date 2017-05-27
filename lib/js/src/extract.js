'use strict';


var extract = (
  function (text) {
    const marked = require('marked');

    return marked.lexer(text)
      .filter(node => node.type == 'code')
      .map(node => [node.lang, node.text]);
  }
);

exports.extract = extract;
/* extract Not a pure module */
