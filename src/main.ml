
let out_dir = "__checkmarked__"
let config = Config.read ()

let rec ensureDirExists path =
  let dir = BsNode.Node.Path.dirname path in
  if not @@ BsNode.Node.Fs.existsSync dir then begin
    ensureDirExists dir;
    BsNode.Node.Fs.mkdirSync dir
  end

let writeFile filename content =
  let path = BsNode.Node.Path.join [| out_dir; filename |] in
  ensureDirExists path;
  BsNode.Node.Fs.writeFileSync ~filename:path ~text:content

let ruleFor lang =
  Js.Dict.get Config.(config.rules) lang

let checkCode filename (rule: Config.rule) =
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
        let _ : string = BsNode.Node.ChildProcess.execSync cmd (BsNode.Node.Options.options ~cwd:out_dir ()) in
        print_endline "done"
      | None ->
        print_endline ("Task not found: " ^ task_spec.name)
    )

let checkFile path =
  print_endline {j|Parsing $path... |j};
  BsNode.Node.Fs.readFileAsUtf8Sync path
  |> Extract.extract
  |> Array.to_list
  |> List.iteri (fun i (lang, content) ->
    match ruleFor lang with
    | Some rule ->
      let extension = Js.Option.(rule.extension |> getWithDefault lang) in
      let target_file = {j|$path.$i.$extension|j} in

      writeFile target_file content;

      print_string @@ "Checking " ^ target_file ^ "... ";
      checkCode target_file rule

    | None -> print_endline ("No rule for language: " ^ lang)
  );
  print_endline ""

let _ =
  config.sources
  |> List.map (fun pattern -> pattern |> Glob.sync |> Array.to_list)
  |> List.flatten
  |> List.map checkFile
