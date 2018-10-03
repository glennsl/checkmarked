'use strict';

var Fs = require("fs");
var Json_decode = require("@glennsl/bs-json/lib/js/src/Json_decode.bs.js");

var filename = "checkmarked.config.json";

function task(json) {
  return /* record */[/* command */Json_decode.field("command", Json_decode.string, json)];
}

function task_spec(json) {
  return /* record */[
          /* name */Json_decode.field("name", Json_decode.string, json),
          /* arguments */Json_decode.optional((function (param) {
                  return Json_decode.field("arguments", Json_decode.string, param);
                }), json)
        ];
}

function string_to_task_spec(json) {
  return /* record */[
          /* name */Json_decode.string(json),
          /* arguments */undefined
        ];
}

function rule(json) {
  var partial_arg = Json_decode.either(task_spec, string_to_task_spec);
  return /* record */[
          /* tasks */Json_decode.field("tasks", (function (param) {
                  return Json_decode.list(partial_arg, param);
                }), json),
          /* extension */Json_decode.optional((function (param) {
                  return Json_decode.field("extension", Json_decode.string, param);
                }), json)
        ];
}

function config(json) {
  return /* record */[
          /* tasks */Json_decode.field("tasks", (function (param) {
                  return Json_decode.dict(task, param);
                }), json),
          /* sources */Json_decode.field("sources", (function (param) {
                  return Json_decode.list(Json_decode.string, param);
                }), json),
          /* rules */Json_decode.field("rules", (function (param) {
                  return Json_decode.dict(rule, param);
                }), json)
        ];
}

var Decode = /* module */[
  /* task */task,
  /* task_spec */task_spec,
  /* string_to_task_spec */string_to_task_spec,
  /* rule */rule,
  /* config */config
];

function read() {
  return config(JSON.parse(Fs.readFileSync(filename, "utf8")));
}

exports.filename = filename;
exports.Decode = Decode;
exports.read = read;
/* fs Not a pure module */
