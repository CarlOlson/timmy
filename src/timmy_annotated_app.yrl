Nonterminals terms term type.
Terminals lambda lparen rparen lbracket rbracket
	  dot colon arrow variable typename.
Rootsymbol terms.


terms -> term colon type : {terms, '$1', '$3'}.


% variable
term -> variable : {var, extract_token('$1')}.

% application w/ type
term -> term term lbracket type rbracket :
     {app, '$1', '$2', '$4'}.

% lambda w/o type
term -> lambda variable dot term :
     {lambda, extract_token('$2'), '$4'}.

% application w/o type
% term -> term term :
%      {app, '$1', '$2'}.
% 
% lambda w/ type
% term -> lambda variable colon type dot term :
%      {lambda, {extract_token('$2'), '4'}, '$6'}

% paren
term -> lparen term rparen : '$2'.


% type variable
type -> typename : extract_token('$1').

% type function
type -> type arrow type : {'$1', '$3'}.

% type paren
type -> lparen type rparen : '$2'.


Erlang code.

extract_token({_Token, _Line, Value}) -> Value.


% :yecc.file './src/timmy_annotated_app'
% c "./src/timmy_annotated_app.erl"