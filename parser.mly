/* Mini-C Parser */
/* Li-yao Xia */

%{
  open Ast
  
  let loc startpos endpos =
    { start_p=startpos ; end_p=endpos }

  let mk_pointer t n =
    if n = 0 then t else Point (n,t) 

  let vstmt_of_var_list t {desc=n,x ;loc=loc} =
    {desc=mk_pointer t n,x ; loc=loc}

  let while_of_for e1 e2 e3 i loc =
    let bool_optexpr = function
      | None -> { desc=Cint 1 ; loc=loc }
      | Some e -> e
    in
    Bloc ([],
      List.fold_right
        ( fun e -> fun l -> Expr e::l )
        e1
        [
          Instr
          {
            desc=While
            (
              bool_optexpr e2,
              Instr 
              { desc=Bloc (
                  [], [i]@
                  (List.map (fun e -> Expr e) e3)) ;
                loc=loc }
            ) ;
            loc=loc
          }
        ]
               ) 
%}

%token <int> CST
%token <string> IDENT STR
%token CHAR ELSE FOR IF INT RETURN SIZEOF STRUCT UNION VOID WHILE
%token STAR LPAR RPAR LBKT RBKT LBRC RBRC EOF
%token SEMICOLON COMMA DOT ARROW ASSIGN
%token INCR DECR ADDRESS NOT PLUS MINUS
%token EQ NEQ LT LEQ GT GEQ DIV MOD AND OR

%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT LEQ GT GEQ
%left PLUS MINUS
%left STAR DIV MOD
%right NOT INCR DECR ADDRESS /*UStar UPlus UMinus*/
%left ARROW DOT

%start prog

%type <Ast.file> prog

%%
prog:
  stmt_list_rev EOF
  { List.rev $1 }

stmt_list_rev:
  | /*EMPTY*/			{ [] }
  | stmt_list_rev vstmt_list	{ (List.map (fun v -> V v) $2)@$1 }
  | sl=stmt_list_rev s=tstmt
  | sl=stmt_list_rev s=fstmt 	{
      (Stmt { desc=s ; loc=loc $startpos(s) $endpos(s) })::sl }

vstmt_list:
  | ty separated_nonempty_list(COMMA,var) SEMICOLON
      { List.map (vstmt_of_var_list $1) $2 }

tstmt:
  | STRUCT IDENT LBRC vstmt_list RBRC SEMICOLON
    { Typ (Struct $2, $4) }
  | UNION IDENT LBRC vstmt_list RBRC SEMICOLON
    { Typ (Union $2, $4) }

fstmt:
  t=ty count=star_count f=IDENT LPAR args=separated_list(COMMA,arg) RPAR
    LBRC vslist=vstmt_list ilist=instr* RBRC
    { Fct (mk_pointer t count,f,args,vslist,ilist) }

var:
  star_count IDENT 	{ {desc=$1,$2 ; loc=loc $startpos $endpos} }

star_count:
  | /*EMPTY*/ 		{ 0 }
  | star_count STAR	{ $1+1 }

ty:
  | VOID 		{ Void }
  | INT 		{ Int }
  | CHAR 		{ Char }
  | STRUCT IDENT 	{ Struct $2 }
  | UNION IDENT 	{ Union $2 }

arg:
  ty star_count IDENT
    { { desc=mk_pointer $1 $2,$3 ; loc=loc $startpos $endpos } }

expr:
  | edesc { { desc=$1 ; loc=loc $startpos $endpos } }
  | LPAR expr RPAR		{ $2 }

edesc:
  | CST 			{ Cint $1 }
  | STR 			{ Cstring $1 }
  | IDENT			{ Ident $1 }
  | expr DOT IDENT		{ Dot ($1,$3) }
  | expr ARROW IDENT
      { Dot ( { desc=Unop (Star,$1) ; loc=loc $startpos($1) $endpos($1) },$3) }
  | expr LBKT expr RBKT
      { Unop (Star, { desc=Binop (Plus,$1,$3) ; loc=loc $startpos $endpos }) }
  | expr ASSIGN expr		{ Assign ($1,$3) }
  | f=IDENT LPAR args=separated_list(COMMA,expr) RPAR
				{ Call (f,args) }
  | u=unop e=expr		{ Unop(u,e) }
  | expr INCR			{ Unop(Incrs,$1) }
  | expr DECR			{ Unop(Decrs,$1) }
  | e1=expr o=binop e2=expr	{ Binop(o,e1,e2) }
  | SIZEOF LPAR ty star_count RPAR
		{ Sizeof (if $4=0 then $3 else Point ($4,$3)) }

%inline unop:
  | INCR	{ Incrp }
  | DECR	{ Decrp }
  | ADDRESS	{ Address }
  | NOT 	{ Not }
  | PLUS 	{ Uplus }
  | MINUS	{ Uminus }
  | STAR 	{ Star }

%inline binop:
  | EQ  	{ Eq }
  | NEQ 	{ Neq }
  | LT  	{ Lt }
  | LEQ 	{ Leq }
  | GT  	{ Gt }
  | GEQ 	{ Geq }
  | PLUS 	{ Plus }
  | MINUS 	{ Minus }
  | STAR 	{ Mul }
  | DIV 	{ Div }
  | MOD 	{ Mod }
  | AND 	{ And }
  | OR  	{ Or }

instr:
  | expr SEMICOLON	{ Expr $1 }
  | idesc	{ Instr { desc=$1 ; loc=loc $startpos $endpos } }

idesc:
  | SEMICOLON		 		{ Nop }
  | IF LPAR expr RPAR instr
      { If ($3,$5,Instr {desc=Nop;loc=loc $endpos $endpos}) }
  | IF LPAR expr RPAR instr ELSE instr	{ If ($3,$5,$7) }
  | WHILE LPAR expr RPAR instr		{ While ($3,$5) }
  | FOR LPAR init=separated_list(COMMA,expr) SEMICOLON
      test=expr? SEMICOLON
      inc=separated_list(COMMA,expr) RPAR i=instr
	{ while_of_for init test inc i (loc $startpos $endpos) }
  | LBRC vstmt_list instr* RBRC 		{ Bloc ($2,$3) }
  | RETURN expr? SEMICOLON		{ Return $2 }

