let extract : string -> (string * string) array = [%raw {|
  function (text) {
    const marked = require('marked');

    return marked.lexer(text)
      .filter(node => node.type == 'code')
      .map(node => [node.lang, node.text]);
  }
|}]