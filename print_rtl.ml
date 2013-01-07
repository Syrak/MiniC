open Iselect
open Rtl
open Print_ist
open Int32
open Format

let ub_string = function
  | Bgtz -> "bgtz"
  | Bgtzal -> "bgtzal"
  | Bgez -> "bgez"
  | Bgezal -> "bgezal"
  | Blez -> "blez"
  | Bltz -> "bltz"
  | Bltzal -> "bltzal"
  | Beqzi -> "beqzi"
  | Bnez -> "bnez"
  | Beqz -> "beqz"
  | Beqi n -> "beqi("^to_string n^")"
  | Blti n -> "blti("^to_string n^")"
  | Bgti n -> "bgti("^to_string n^")"
  | Bnei n -> "bnei("^to_string n^")"

let bb_string = function
  | Beq -> "beq"
  | Bne -> "bne"
  | Blt -> "blt"
  | Ble -> "ble"

let reg_string = function
  | R.R r -> "R"^string_of_int r
  | R.F r -> string_of_int r^"($fp)"
  | R.S r -> string_of_int r^"($sp)"

let rec print_rl ch = function
  | [] -> ()
  | [h] -> fprintf ch "#%s" (reg_string h)
  | h::t -> fprintf ch "#%s " (reg_string h);
      print_rl ch t

let print_instr h = function
  | Const (r,n,l) ->
      fprintf h "#%s <- %s\t|%d" (reg_string r) (to_string n) l
  | Move (r,s,l) ->
      fprintf h "#%s <- #%s\t|%d" (reg_string r) (reg_string s) l
  | Unop (r,u,s,l) -> fprintf h "#%s <- %s #%s\t|%d"
      (reg_string r) (unop_string u) (reg_string s) l
  | Binop (r,o,s,t,l) -> fprintf h "#%s <- %s #%s #%s\t|%d"
      (reg_string r) (binop_string o) (reg_string s) (reg_string t) l
  | La (r,x,l) -> fprintf h "#%s <- la %s\t|%d" (reg_string r) x l
  | Addr (r,s,l) ->
      fprintf h "#%s <- &#%s\t|%d" (reg_string r) (reg_string s) l
  | Load (r,sz,n,s,l) -> fprintf h "#%s <- Load(%d) %s(#%s)\t|%d"
      (reg_string r) sz (to_string n) (reg_string s) l
  | Lw (r,n,s,l)
  | Lb (r,n,s,l) -> fprintf h "#%s <- l- %s(#%s)\t|%d"
      (reg_string r) (to_string n) (reg_string s) l
  | Stor (r,t,sz,n,s,l) ->
      fprintf h "#%s <- Store(%d) #%s %s(#%s)\t|%d"
      (reg_string r) sz (reg_string t) (to_string n) (reg_string s) l
  | Sw (r,t,n,s,l)
  | Sb (r,t,n,s,l) -> fprintf h "#%s <- s- #%s %s(#%s)\t|%d"
      (reg_string r) (reg_string t) (to_string n) (reg_string s) l
  | Call (r,f,rl,l) -> fprintf h "#%s <- %s(%a)\t|%d"
      (reg_string r) f print_rl rl l
  | Jump l -> fprintf h "j|%d" l
  | Ubch (u,r,l,m) ->
      fprintf h "%s #%s |%d %d" (ub_string u) (reg_string r) l m
  | Bbch (b,r,s,l,m) -> fprintf h "%s #%s #%s |%d %d"
      (bb_string b) (reg_string r) (reg_string s) l m
  | ECall (f,l) -> fprintf h "[%s] |%d" f l
  | Syscall l -> fprintf h "syscall | %d" l
  | Alloc_frame l -> fprintf h "alloc_frame | %d" l
  | Free_frame l -> fprintf h "free_frame | %d" l
  | Return -> fprintf h "return"
  | ETCall (f) -> fprintf h "return [%s]" f
  | Label (s,l) -> fprintf h "lab:%s | %d" s l
  | Blok _ -> assert false

let print_fct h {
  ident=f;
  s_ident=_;
  formals=formals;
  locals=_;
  return=ret;
  entry=entry;
  exit=exit;
  body=body;
  } =
    fprintf h "#%s %s(%a)@\n  @[Entry: %d@\n"
      (reg_string ret) f print_rl formals entry;
    L.M.iter (fun l i -> fprintf h "%d : %a@\n" l print_instr i) body;
    fprintf h "@]@."

let print_instr2 h = function
  | Const (r,n,l) -> fprintf h "#%s <- %s" (reg_string r) (to_string n)
  | Move (r,s,l) ->
      fprintf h "#%s <- #%s" (reg_string r) (reg_string s)
  | Unop (r,u,s,l) -> fprintf h "#%s <- %s #%s"
      (reg_string r) (unop_string u) (reg_string s)
  | Binop (r,o,s,t,l) -> fprintf h "#%s <- %s #%s #%s"
      (reg_string r) (binop_string o) (reg_string s) (reg_string t)
  | La (r,x,l) -> fprintf h "#%s <- la %s" (reg_string r) x
  | Addr (r,s,l) ->
      fprintf h "#%s <- &#%s" (reg_string r) (reg_string s)
  | Load (r,sz,n,s,l) -> fprintf h "#%s <- Load(%d) %s(#%s)"
      (reg_string r) sz (to_string n) (reg_string s)
  | Lw (r,n,s,l)
  | Lb (r,n,s,l) -> fprintf h "#%s <- l- %s(#%s)"
      (reg_string r) (to_string n) (reg_string s)
  | Stor (r,t,sz,n,s,l) -> fprintf h "#%s <- Store(%d) #%s %s(#%s)"
      (reg_string r) sz (reg_string t) (to_string n) (reg_string s)
  | Sw (r,t,n,s,l)
  | Sb (r,t,n,s,l) -> fprintf h "#%s <- s- #%s %s(#%s)"
      (reg_string r) (reg_string t) (to_string n) (reg_string s)
  | Call (r,f,rl,l) -> fprintf h "#%s <- %s(%a)"
      (reg_string r) f print_rl rl
  | Jump l -> fprintf h "j"
  | Ubch (u,r,l,m) -> fprintf h "%s #%s |%d %d" (ub_string u) (reg_string r) l m
  | Bbch (b,r,s,l,m) -> fprintf h "%s #%s #%s |%d %d"
      (bb_string b) (reg_string r) (reg_string s) l m
  | ECall (f,l) -> fprintf h "[%s]" f
  | Syscall l -> fprintf h "syscall"
  | Alloc_frame l -> fprintf h "alloc_frame"
  | Free_frame l -> fprintf h "free_frame"
  | Return -> fprintf h "return"
  | ETCall (f) -> fprintf h "return [%s]" f
  | Label (s,l) -> fprintf h "lab:%s" s
  | Blok _ -> assert false

let rec print_block h = function
  | [] -> ()
  | [i] -> fprintf h "%a@\n" print_instr i;
  | i::t -> fprintf h "%a@\n" print_instr2 i;
      print_block h t

let print_blocks h =
  List.iter (fun (l,block) ->
    fprintf h "%d :@\n  @[%a@]@\n" l print_block
      (match block with
        | Blok l -> l
        | _ -> assert false))

let print_blokfkt h (ls,f) =
  fprintf h "#%s %s(%a)@\n  @[Entry: %d@\n"
    (reg_string f.return) f.ident print_rl f.formals f.entry;
  print_blocks h ls
