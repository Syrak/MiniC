let parse_only = ref false
let type_only = ref false
let batch = ref false

let usage = Printf.sprintf
  "Usage : %s program.c [-parse-only] [-type-only]"
  (Filename.basename Sys.argv.(0))

let speclist = [
  "-parse-only",Arg.Unit (fun () -> parse_only := true),
    "Exit after parsing";
  "-type-only",Arg.Unit (fun () -> type_only := true),
    "Exit after typing";
  "-batch",Arg.Unit (fun () -> batch := true),
    "Compile multiple files (separately)"
  ]

let args = ref []

let collect arg = args := arg :: !args

let compile file =
  let h = open_in file in
  let lexbuf = Lexing.from_channel h in
  try
    let ast = Parser.prog Lexer.token lexbuf in
    if !parse_only then exit 0;
    let tast = Typing.type_prog ast in
    0;
  with
    | Error.E (sp,ep,s) -> Error.prerr file sp ep s; 1
    | Parser.Error -> Error.catch file lexbuf; 1
    | _ -> Printf.eprintf "Unexpected error.\n%!"; 2


let () =
  try 
    Arg.parse speclist collect usage;
    let rec main = function
      | [] ->
        Printf.eprintf "No file to compile specified.\n%s\n%!" usage;
        exit 2;
      | [file] -> exit (compile file)
      | file::t -> if !batch
        then begin ignore (compile file); main t end
        else begin
          Printf.eprintf "Too many arguments.\n%s\n%!" usage;
          exit 2; end
    in main !args
  with
    | _ -> Printf.eprintf "Unexpected error.\n%!"; exit 2