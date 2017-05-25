
let filename = "mdcc.config.json"

type task = {
  command: string
}
and task_spec = {
  name: string;
  arguments: string option
}
and rule = {
  tasks: task_spec list
}
and config = {
  tasks: task Js.Dict.t;
  sources: string list;
  rules: rule Js.Dict.t
}

module Decode = struct
  let task json = Json.Decode.{
    command = json |> field "command" string
  }
  
  let task_spec json = Json.Decode.{
    name = json |> field "name" string;
    arguments = json |> optional (field "arguments" string)
  }

  let string_to_task_spec json = Json.Decode.{
    name = json |> string;
    arguments = None
  }

  let rule json = Json.Decode.{
    tasks = json |> field "tasks" (list (either task_spec string_to_task_spec))
  }

  let config json = Json.Decode.{
    tasks = json |> field "tasks" (dict task);
    sources = json |> field "sources" (list string);
    rules = json |> field "rules" (dict rule)
  }
end

let read () =
  Node.Fs.readFileAsUtf8Sync filename
  |> Js.Json.parseExn
  |> Decode.config