
let out_dir = "__mdcc__"
let config = Config.read ()

let rec ensureDirExists path =
  let dir = Node.Path.dirname path in
  if not @@ Node.Fs.existsSync dir then begin
    ensureDirExists dir;
    Node.Fs.mkdirSync dir
  end

let writeFile filename content =
  ensureDirExists filename;
  Node.Fs.writeFileSync ~filename:filename ~text:content

let checkCode filename lang =
  match Js.Dict.get Config.(config.rules) lang with
  | Some rule ->
    rule.tasks
    |> List.iter (fun task_spec ->
      match Js.Dict.get config.tasks task_spec.Config.name with
      | Some task ->
        let cmd = task.command |> Js.String.replaceByRe [%re {|/\$\(file\)/|}] filename in
        let cmd =
          match task_spec.arguments with
          | Some args ->
            cmd |> Js.String.replaceByRe [%re {|/\$\(args\)/|}] args
          | None -> cmd
          in
        Js.log cmd;
        let _ : string = Node.ChildProcess.execSync cmd (Node.Options.options ~cwd:"__mdcc__" ()) in
        print_endline "done"
      | None ->
        print_endline ("Task not found: " ^ task_spec.name)
    )
  | None -> print_endline ("Unrecognized language: " ^ lang)

let checkFile path =
  print_endline {j|Parsing $path... |j};
  Node.Fs.readFileAsUtf8Sync path
  |> Extract.extract
  |> Array.to_list
  |> List.iteri (fun i (lang, content) -> begin
      let i = string_of_int i in
      let target_file = {j|$path.$i.$lang|j} in
      let target_path = Node.Path.join [|out_dir; target_file|] in
      writeFile target_path content;
      print_string @@ "Checking " ^ target_file ^ "... ";
      checkCode target_file lang
    end;
  );
  print_endline ""

let _ =
  config.sources
  |> List.map (fun pattern -> pattern |> Glob.sync |> Array.to_list)
  |> List.flatten
  |> List.map checkFile