import std.ascii, std.conv, std.string, std.array, std.algorithm;
import token;

struct Result {
	Token token;
	string remainder;
	string value;
}

Result next(string src) {
		Result result;
		do
			result = nextAll(src);
			while (result.token == WHITE || result.token == COMMENT);
		return result;
}

Result nextAll(string src) {
	if (src.empty)
		return Result(EOF);
	dchar c = src.front;
	if (isWhite(c))
		return src.whitespace();
	string orig = src;
	src.popFront();
	switch (c) {
	case '#': 
		return Result(HASH, src);
	case '(': 
		return Result(L_PAREN, src);
	case ')':
		return Result(R_PAREN, src);
	case ',': 
		return Result(COMMA, src);
	case ';':
		return Result(SEMICOLON, src);
	case '?':
		return Result(Q_MARK, src);
	case '@': 
		return Result(AT, src);
	case '[':
		return Result(L_BRACKET, src);
	case ']': 
		return Result(R_BRACKET, src);
	case '{':
		return Result(L_CURLY, src);
	case '}':
		return Result(R_CURLY, src);
	case '~':
		return Result(BITNOT, src);
	case ':':
		return Result(src.match(':') ? RANGELEN : COLON, src);
	case '=' :
		return Result(src.match('=') ? IS : src.match('~') ? MATCH : EQ, src);
	case '!':
		return Result(src.match('=') ? ISNT : src.match('~') ? MATCHNOT : NOT, src);
	case '<':
		return Result(src.match('<') ? (src.match('=') ? LSHIFTEQ : LSHIFT)
			: src.match('>') ? ISNT : src.match('=') ? LTE : LT, src);
	case '>':
		return Result(src.match('>') ? (src.match('=') ? RSHIFTEQ : RSHIFT)
			: src.match('=') ? GTE : GT, src);
	case '|':
		return Result(src.match('|') ? OR : src.match('=') ? BITOREQ : BITOR, src);
	case '&':
		return Result(src.match('&') ? AND : src.match('=') ? BITANDEQ : BITAND, src);
	case '^':
		return Result(src.match('=') ? BITXOREQ : BITXOR, src);
	case '-':
		return Result(src.match('-') ? DEC : src.match('=') ? SUBEQ : SUB, src);
	case '+':
		return Result(src.match('+') ? INC : src.match('=') ? ADDEQ : ADD, src);
	case '/':
		return src.match('/') ? src.lineComment() : src.match('*') ? src.spanComment()
			: Result(src.match('=') ? DIVEQ : DIV, src);
	case '*':
		return Result(src.match('=') ? MULEQ : MUL, src);
	case '%':
		return Result(src.match('=') ? MODEQ : MOD, src);
	case '$':
		return Result(src.match('=') ? CATEQ : CAT, src);
	case '`':
		return src.rawString();
	case '"':
	case '\'':
		return src.quotedString(c);
	case '.':
		return src.match('.') ? Result(RANGETO, src)
			: src.first.isDigit() ? src.number() : Result(DOT, src);
	case '0': .. case '9':
		return orig.number();
	default:
		return (isAlpha(c) || c == '_') ? orig.identifier() : Result(ERROR, src);
	}
}

private bool match(ref string src, dchar c) {
	return (! src.empty && src.front == c) ? src.popFront(), true : false;
}

@property private dchar first(string src) {
	return src.empty ? dchar.init : src.front;
}

private dchar pop(ref string src) {
	dchar c = src.first;
	src.popFront;
	return c;
}

private Result whitespace(string src) {
	bool eol = false;
string orig = src;
writeln("whitespace");
	for (; ! src.empty && isWhite(src.front); src.popFront)
		if (src.front == '\n' || src.front == '\r')
			eol = true;
assert(src.length < orig.length);
	return Result(eol ? NEWLINE : WHITE, src);
}

private Result lineComment(string src) {
	for (src.popFront; ! src.empty &&
			src.front != '\r' && src.front != '\n'; src.popFront) {
	}
	return Result(COMMENT, src);
}

private Result spanComment(string src) {
	for (src.popFront; ! src.empty && ! src.startsWith("*/"); src.popFront) {
	}
	src.findSkip("*/");
	return Result(COMMENT, src);
}

private Result rawString(string src) {
	string orig = src;
	while (! src.empty && src.first != '`')
		src.popFront;
	string value = getValue(orig, src);
	src.match('`');
	return Result(STRING, src, value);
}

private Result quotedString(string src, dchar quote) {
	dchar c;
	auto app = appender!string();
	for (; ! src.empty && (c = src.first) != quote; src.popFront)
		app.put(c == '\\' ? doesc(src) : c);
	src.match(quote);
	return Result(STRING, src, app.data);
}

// src must be popped once after this
private dchar doesc(ref string src) {
	assert(src.front == '\\');
	string s = src;
	s.popFront;
	int dig1, dig2, dig3;
	switch (src.first) {
	case 'n' :
		return src = s, '\n';
	case 't' :
		return src = s, '\t';
	case 'r' :
		return src = s, '\r';
	case 'x' :
		s.popFront;
		if (-1 != (dig1 = digit(s.pop(), 16)) && 
			-1 != (dig2 = digit(s.first, 16)))
			return src = s, cast(char)(16 * dig1 + dig2);
		else
			return '\\';
	case '\\' :
	case '"' :
	case '\'' :
		return src = s, s.first;
	default :
		if (-1 != (dig1 = digit(s.pop(), 8)) &&
				-1 != (dig2 = digit(s.pop(), 8)) &&
				-1 != (dig3 = digit(s.first, 8)))
			return src = s, cast(char)(64 * dig1 + 8 * dig2 + dig3);
		else
			return '\\';
	}
}

private static int digit(dchar c, int radix = 16) {
	int n = c.isDigit() ? c - '0'
		: c.isHexDigit() ? 10 + c.toLower() - 'a'
		: 99;
	return n < radix ? n : -1;
}
unittest {
	import asserts;
	Assert(digit('0'), Is(0));
	Assert(digit('9'), Is(9));
	Assert(digit('a'), Is(10));
	Assert(digit('F'), Is(15));
	Assert(digit('g'), Is(-1));
}

private Result number(string src) {
	string orig = src;
	if (hexNumber(src))
		return Result(NUMBER, src, getValue(orig, src));
	do
		src.popFront;
		while (isDigit(src.first));
	if (! src.startsWith("..")) { // range
		if (src.match('.'))
			while (isDigit(src.first))
				src.popFront;
		exponent(src);
	}
	return Result(NUMBER, src, getValue(orig, src));
}
private bool hexNumber(ref string src) {
	string s = src;
	if (! s.match('0') || 
		! (s.match('x') || s.match('X')) ||
		! isHexDigit(s.first))
		return false;
	do
		s.popFront();
		while (isHexDigit(s.first));
	src = s;
	return true;
}
private void exponent(ref string src) {
	string s = src;
	if (s.empty || ! s.pop().toLower() == 'e')
		return;
	s.match('+') || s.match('-');
	if (s.empty || ! s.pop().isDigit())
		return;
	do
		s.popFront();
		while(! s.empty && isDigit(s.front));
	src = s;
}

private string getValue(string orig, string src) {
	size_t len = orig.length - src.length;
	return orig[0 .. len];
}

private Result identifier(string src) {
	string orig = src;
	while (isAlphaNum(src.first) || src.first == '_')
		src.popFront();
	src.match('?') || src.match('!');
	string value = getValue(orig, src);

	Token keyword = keywords.get(value, null);
	if (src.first == ':' &&
			(keyword == IS || keyword == ISNT ||
			keyword == AND || keyword == OR || keyword == NOT))
		keyword = null;
	return Result(keyword !is null //&& keyword.isOperator()
			? keyword : IDENTIFIER, src, value);
}

import std.stdio : writeln;

unittest {
	import asserts;

	void test(string s, Token[] tokens...) {
writeln("test ", s);
		Result r = s.next();
		foreach (t; tokens) {
writeln(r);
			Assert(r.token, Is(t), "input: '" ~ s ~ "'");
			r = next(r.remainder);
		}
	}
	void testAll(string s, Token[] tokens...) {
writeln("testAll ", s);
		Result r = s.nextAll();
		foreach (t; tokens) {
writeln(r);
			Assert(r.token, Is(t), "input: '" ~ s ~ "'");
			r = nextAll(r.remainder);
		}
	}
	void testVal(string s, Token token, string value = null) {
writeln("testVal ", s);
		if (value is null)
			value = s;
		Result r = lexer.nextAll(s);
writeln(r);
		Assert(r.token, Is(token));
		Assert(r.value, Is(value));	
	}

	testAll(" \t", WHITE);
	test(" \n \t", NEWLINE);
	test("#(),;?@[]{}~", HASH, L_PAREN, R_PAREN, COMMA, SEMICOLON,
		Q_MARK, AT, L_BRACKET, R_BRACKET, L_CURLY, R_CURLY, BITNOT);
	test(":", COLON);
	test("::", RANGELEN);
	test("==", IS); 
	test("=~", MATCH);
	test("=", EQ);
	test("\n", NEWLINE);
	test("::", RANGELEN);
	test(":", COLON);
	test("==", IS);
	test("=~", MATCH);
	test("=", EQ);
	test("!=", ISNT);
	test("!~", MATCHNOT);
	test("!", NOT);
	test("<<=", LSHIFTEQ);
	test("<<", LSHIFT);
	test("<>", ISNT);
	test("<=", LTE);
	test("<", LT);
	test(">>=", RSHIFTEQ);
	test(">=", GTE);
	test(">", GT);
	test("||", OR);
	test("|=", BITOREQ);
	test("|", BITOR);
	test("&&", AND);
	test("&=", BITANDEQ);
	test("&", BITAND);
	test("^=", BITXOREQ);
	test("^", BITXOR);
	test("--", DEC);
	test("-=", SUBEQ);
	test("-", SUB);
	test("++", INC);
	test("+=", ADDEQ);
	test("+", ADD);
	testAll("// blah blah\n", COMMENT, NEWLINE);
	testAll("/* blah blah */+", COMMENT, ADD);
	test("/=", DIVEQ);
	test("/", DIV);
	test("*=", MULEQ);
	test("*", MUL);
	test("%=", MODEQ);
	test("%", MOD);
	test("$=", CATEQ);
	test("$", CAT);
	test("`blah \n blah`+", STRING, ADD);

	testVal("`hello`", STRING, "hello");
	testVal(`"hello"`, STRING, "hello");
	testVal(`'hello'`, STRING, "hello");
	testVal("'\x20'", STRING, " ");
	testVal("'\040'", STRING, " ");
	testVal("'hello\nworld'", STRING, "hello\nworld");

	testVal("fred", IDENTIFIER);

	testVal("and", AND);

	testVal("0", NUMBER);
	test("0xx", NUMBER, IDENTIFIER);
	testVal("0xx", NUMBER, "0");
	testVal("0x7f", NUMBER);
	testVal("123", NUMBER);
	testVal("0123", NUMBER);
}