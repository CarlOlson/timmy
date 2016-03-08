Definitions.

TYPENAME = [A-Z][A-Za-z]*

Rules.

% λ is \ because leex errors with lambda

\\         : {token, {lambda,   TokenLine}}.
\(         : {token, {lparen,   TokenLine}}.
\)         : {token, {rparen,   TokenLine}}.
\[         : {token, {lbracket, TokenLine}}.
\]         : {token, {rbracket, TokenLine}}.
\.         : {token, {dot,      TokenLine}}.
\:         : {token, {colon,    TokenLine}}.
\-\>       : {token, {arrow,    TokenLine}}.
[a-z]      : {token, {variable, TokenLine, TokenChars}}.
{TYPENAME} : {token, {typename, TokenLine, TokenChars}}.
[\s\t\r\n] : skip_token.

Erlang code.

% :leex.file 'timmy_lexer.xrl'
% c "timmy_lexer.erl"