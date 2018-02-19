'use strict';

var Fs = require("fs");
var List = require("bs-platform/lib/js/list.js");
var Glob = require("glob");
var Path = require("path");
var $$Array = require("bs-platform/lib/js/array.js");
var Curry = require("bs-platform/lib/js/curry.js");
var Config = require("./config.js");
var Extract = require("./extract.js");
var Js_option = require("bs-platform/lib/js/js_option.js");
var Pervasives = require("bs-platform/lib/js/pervasives.js");
var Js_primitive = require("bs-platform/lib/js/js_primitive.js");
var Child_process = require("child_process");

var out_dir = "__checkmarked__";

var config = Config.read(/* () */0);

function ensureDirExists(path) {
  var dir = Path.dirname(path);
  if (Fs.existsSync(dir)) {
    return 0;
  } else {
    ensureDirExists(dir);
    Fs.mkdirSync(dir);
    return /* () */0;
  }
}

function writeFile(filename, content) {
  var path = Path.join(out_dir, filename);
  ensureDirExists(path);
  Fs.writeFileSync(path, content);
  return /* () */0;
}

function ruleFor(lang) {
  return Js_primitive.undefined_to_opt(config[/* rules */2][lang]);
}

function checkCode(filename, rule) {
  return List.iter((function (task_spec) {
                var match = config[/* tasks */0][task_spec[/* name */0]];
                if (match !== undefined) {
                  var cmd = match[/* command */0].replace((/\$\(file\)/), filename);
                  var match$1 = task_spec[/* arguments */1];
                  var cmd$1 = match$1 ? cmd.replace((/\$\(args\)/), match$1[0]) : cmd;
                  console.log(cmd$1);
                  Child_process.execSync(cmd$1, {
                        cwd: out_dir
                      });
                  console.log("done");
                  return /* () */0;
                } else {
                  console.log("Task not found: " + task_spec[/* name */0]);
                  return /* () */0;
                }
              }), rule[/* tasks */0]);
}

function checkFile(path) {
  console.log("Parsing " + (String(path) + "... "));
  List.iteri((function (i, param) {
          var lang = param[0];
          var match = ruleFor(lang);
          if (match) {
            var rule = match[0];
            var extension = Js_option.$$default(lang, rule[/* extension */1]);
            var target_file = "" + (String(path) + ("." + (String(i) + ("." + (String(extension) + "")))));
            writeFile(target_file, param[1]);
            Pervasives.print_string("Checking " + (target_file + "... "));
            return checkCode(target_file, rule);
          } else {
            console.log("No rule for language: " + lang);
            return /* () */0;
          }
        }), $$Array.to_list(Curry._1(Extract.extract, Fs.readFileSync(path, "utf8"))));
  console.log("");
  return /* () */0;
}

List.map(checkFile, List.flatten(List.map((function (pattern) {
                return $$Array.to_list(Glob.sync(pattern));
              }), config[/* sources */1])));

exports.out_dir = out_dir;
exports.config = config;
exports.ensureDirExists = ensureDirExists;
exports.writeFile = writeFile;
exports.ruleFor = ruleFor;
exports.checkCode = checkCode;
exports.checkFile = checkFile;
/* config Not a pure module */
