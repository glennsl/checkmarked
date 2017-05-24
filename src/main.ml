
let out_dir = "__mdcc__"
let tmp_dir = Node.Path.join [|out_dir; "tmp"|]

let rec ensureDirExists path =
  let dir = Node.Path.dirname path in
  if not @@ Node.Fs.existsSync dir then begin
    ensureDirExists dir;
    Node.Fs.mkdirSync dir
  end

let writeFile filename content =
  ensureDirExists filename;
  Node.Fs.writeFileSync ~filename:filename ~text:content

let checkWithBsc file =
  let ml_path = Node.Path.join [|".."; file|] in
  let js_path = (Node.Path.basename file) ^ ".js" in
  let cmd = {j|../../node_modules/bs-platform/bin/bsc.exe -color always -c -o $js_path $ml_path|j} in
  (*print_endline @@ tmp_dir ^ " : " ^ cmd;*)
  let _ : string = Node.ChildProcess.execSync cmd (Node.Options.options ~cwd:tmp_dir ()) in
  print_endline "done"

let checkExtracted filename = function
| "ml" -> checkWithBsc filename
| lang -> print_endline @@ "Unrecognized language: " ^ lang

let checkFile path =
  print_endline @@ "Parsing " ^ path ^ "... ";
  Node.Fs.readFileAsUtf8Sync path
  |> Extract.extract
  |> Array.to_list
  |> List.iteri (fun i (lang, content) -> begin
      let i = string_of_int i in
      let target_file = {j|$path.$i.$lang|j} in
      let target_path = Node.Path.join [|out_dir; target_file|] in
      writeFile target_path content;
      print_string @@ "Checking " ^ target_file ^ "... ";
      checkExtracted target_file lang
    end;
  );
  print_endline ""

let args =
  Node.Process.argv
  |> Js.Array.sliceFrom 2
  |> Minimist.parseArgs

let files = Minimist.orphans args

let _ = begin
  ensureDirExists (Node.Path.join [|tmp_dir; "dummy"|]);
  files
  |> Array.to_list
  |> List.map checkFile;
end