// (C) 2021 Foxil Developers. All rights reserved. Use of this source
// code is governed by an MIT license that can be found in the LICENSE
// file.
module token

// kind of token
pub enum Kind {
	unknown
	eof
	name // foo
	number // 12345
	string // "Look ma, I'm a string!"
	char // 'A'
	nl // '\n'
	minus // -
	mult // *
	mod // %
	not // !
	question // ?
	hash // #
	comma // ,
	colon // :
	amp // &
	dollar // $
	at // @
	assign // =
	dot // .
	dot_dot // ..
	ellipsis // ...
	lbrace // {
	rbrace // }
	lparen // (
	rparen // )
	lbracket // [
	rbracket // ]
	// ========== keywords ==========
	keyword_begin
	key_as // as
	key_const // const
	key_func // func
	key_type // type
	key_true // true
	key_false // false
	key_extern // extern
	keyword_end
}

// value of tokens
const tokens = map{
	Kind.unknown:    'unknown'
	Kind.eof:        'end of file'
	Kind.name:       'name'
	Kind.number:     'number'
	Kind.string:     'string'
	Kind.char:       'character'
	Kind.nl:         '\\n'
	Kind.minus:      '-'
	Kind.mult:       '*'
	Kind.mod:        '%'
	Kind.not:        '!'
	Kind.question:   '?'
	Kind.hash:       '#'
	Kind.comma:      ','
	Kind.colon:      ':'
	Kind.amp:        '&'
	Kind.dollar:     '$'
	Kind.at:         '@'
	Kind.assign:     '='
	Kind.dot:        '.'
	Kind.dot_dot:    '..'
	Kind.ellipsis:   '...'
	Kind.lbrace:     '{'
	Kind.rbrace:     '}'
	Kind.lparen:     '('
	Kind.rparen:     ')'
	Kind.lbracket:   '['
	Kind.rbracket:   ']'
	Kind.key_as:     'as'
	Kind.key_const:  'const'
	Kind.key_func:   'func'
	Kind.key_type:   'type'
	Kind.key_true:   'true'
	Kind.key_false:  'false'
	Kind.key_extern: 'extern'
}

fn make_keys() map[string]Kind {
	mut keys := map[string]Kind{}
	for i := int(Kind.keyword_begin) + 1; i < int(Kind.keyword_end); i++ {
		keys[token.tokens[Kind(i)]] = Kind(i)
	}
	return keys
}

const keywords = make_keys()

// is_key returns a boolean. true if the given kind is a keyword,
// false if the given kind is not a Keyword
[inline]
pub fn is_key(name string) bool {
	return name in token.keywords
}

// String returns a string literal representation of Kind
[inline]
pub fn (kind Kind) str() string {
	return token.tokens[kind]
}

// lookup maps an identifier to its keyword token or .name (if not a keyword).
[inline]
pub fn lookup(name string) Kind {
	return token.keywords[name] or { Kind.name }
}

// Token represents a keyword, name or symbol in a Blux code file.
pub struct Token {
pub:
	file    string
	kind    Kind
	lit     string
	line_nr int
	col     int
	pos     int
	len     int
	tidx    int
}

// str returns the string corresponding to the token.
pub fn (tok Token) str() string {
	mut str := tok.kind.str()
	if !str[0].is_letter() {
		return 'token `$str`'
	}
	if is_key(tok.lit) {
		str = 'keyword'
	}
	if tok.lit != '' {
		str += ' `$tok.lit`'
	}
	return str
}
