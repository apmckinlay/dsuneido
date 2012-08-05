import std.ascii;
import std.conv;
import std.string;
import std.array;
import token;

class Lexer {
	private string source;
	private int si;
	private int prev;
	private int lineNumber = 1;
	private string value;
	private bool ignoreCase = false;

	this(string source) {
		this.source = source;
	}

	/// Returns: The next token, skipping comments and whitespace (but not newlines)
	Token next() {
		Token token;
		do
			token = nextAll();
			while (token == WHITE || token == COMMENT);
		return token;
	}

	/// Returns: The next token.
	Token nextAll() {
		prev = si;
		value = "";
		if (si >= source.length)
			return EOF;
		char c = source[si];
		if (isWhite(c))
			return whitespace();
		++si;
		switch (c) {
		case '#': 
			return HASH;
		case '(': 
			return L_PAREN;
		case ')':
			return R_PAREN;
		case ',': 
			return COMMA;
		case ';':
			return SEMICOLON;
		case '?':
			return Q_MARK;
		case '@': 
			return AT;
		case '[':
			return L_BRACKET;
		case ']': 
			return R_BRACKET;
		case '{':
			return L_CURLY;
		case '}':
			return R_CURLY;
		case '~':
			return BITNOT;
		case ':':
			return match(':') ? RANGELEN : COLON;
		case '=' :
			return match('=') ? IS : match('~') ? MATCH : EQ;
		case '!':
			return match('=') ? ISNT : match('~') ? MATCHNOT : NOT;
		case '<':
			return match('<') ? (match('=') ? LSHIFTEQ : LSHIFT)
				: match('>') ? ISNT : match('=') ? LTE : LT;
		case '>':
			return match('>') ? (match('=') ? RSHIFTEQ : RSHIFT)
				: match('=') ? GTE : GT;
		case '|':
			return match('|') ? OR : match('=') ? BITOREQ : BITOR;
		case '&':
			return match('&') ? AND : match('=') ? BITANDEQ : BITAND;
		case '^':
			return match('=') ? BITXOREQ : BITXOR;
		case '-':
			return match('-') ? DEC : match('=') ? SUBEQ : SUB;
		case '+':
			return match('+') ? INC : match('=') ? ADDEQ : ADD;
		case '/':
			return match('/') ? lineComment() : match('*') ? spanComment()
				: match('=') ? DIVEQ : DIV;
		case '*':
			return match('=') ? MULEQ : MUL;
		case '%':
			return match('=') ? MODEQ : MOD;
		case '$':
			return match('=') ? CATEQ : CAT;
		case '`':
			return rawString();
		case '"':
		case '\'':
			return quotedString(c);
		case '.':
			return match('.') ? RANGETO
				: charAt(si).isDigit() ? number() : DOT;
		case '0':
			if (match('x') || match('X'))
				return hexNumber();
			goto case; // fall thru
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			return number();
		default:
			return (isAlpha(c) || c == '_') ? identifier() : ERROR;
		}
	}

	private bool match(char c) {
		return (charAt(si) == c) ? ++si, true : false;
	}

	private char charAt(int i) {
		return i < source.length ? source[i] : 0;
	}

	private Token whitespace() {
		char c;
		bool eol = false;
		for (; isWhite(c = charAt(si)); ++si)
			if (c == '\n') {
				eol = true;
				++lineNumber;
			} else if (c == '\r')
				eol = true;
		return eol ? NEWLINE : WHITE;
	}

	private Token lineComment() {
		for (++si; si < source.length &&
				'\r' != charAt(si) && '\n' != charAt(si); ++si) {
		}
		return COMMENT;
	}

	private Token spanComment() {
		for (++si; si < source.length && 
			(charAt(si) != '*' || charAt(si + 1) != '/'); ++si) {
		}
		if (si < source.length)
			si += 2;
		return COMMENT;
	}

	private Token rawString() {
		char c;
		value = "";
		for (; si < source.length && (c = source[si]) != '`'; ++si)
			value ~= c;
		value = source[prev+1 .. si];
		match('`');
		return STRING;
	}

	private Token quotedString(char quote) {
		char c;
		auto app = appender!string();
		for (; si < source.length && (c = source[si]) != quote; ++si)
			app.put(c == '\\' ? doesc() : c);
		if (si < source.length)
			++si;	// skip closing quote
		value = app.data;
		return STRING;
	}

	private char doesc() {
		++si; // backslash
		int dig1, dig2, dig3;
		switch (charAt(si)) {
		case 'n' :
			return '\n';
		case 't' :
			return '\t';
		case 'r' :
			return '\r';
		case 'x' :
			if (-1 != (dig1 = digit(charAt(si + 1), 16)) && 
				-1 != (dig2 = digit(charAt(si + 2), 16))) {
				si += 2;
				return cast(char)(16 * dig1 + dig2);
			} else
				return source[--si];
		case '\\' :
		case '"' :
		case '\'' :
			return charAt(si);
		default :
			if (-1 != (dig1 = digit(charAt(si), 8)) &&
					-1 != (dig2 = digit(charAt(si + 1), 8)) &&
					-1 != (dig3 = digit(charAt(si + 2), 8))) {
				si += 2;
				return cast(char)(64 * dig1 + 8 * dig2 + dig3);
			} else
				return source[--si];
		}
	}

	private Token hexNumber() {
		while (-1 != digit(charAt(si)))
			++si;
		return (si - prev > 2) ? getValue(NUMBER) : ERROR;
	}
	private static int digit(char c, int radix = 16) {
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

	private Token number() {
		while (isDigit(charAt(si)))
			++si;
		if (charAt(si) == '.' && charAt(si + 1) != '.') {
			++si;
			while (isDigit(charAt(si)))
				++si;
		}
		if (charAt(si).toLower() == 'e' &&
				(isDigit(charAt(si + 1)) ||
				((charAt(si + 1) == '+' || charAt(si + 1) == '-') && isDigit(charAt(si + 2))))) {
			si += 2;
			while (isDigit(charAt(si)))
				++si;
		}
		if (charAt(si - 1) == '.')
			--si;
		return getValue(NUMBER);
	}

	private Token getValue(Token token) {
		value = source[prev .. si];
		return token;
	}

	private Token identifier() {
		char c;
		while (true) {
			c = charAt(si);
			if (isAlphaNum(c) || c == '_')
				++si;
			else
				break;
		}
		if (c == '?' || c == '!')
			++si;
		value = source[prev .. si];

		Token keyword = keywords.get(ignoreCase ? value.toLower() : value, null);
		if (charAt(si) == ':' &&
				(keyword == IS || keyword == ISNT ||
				keyword == AND || keyword == OR || keyword == NOT))
			keyword = null;
		return keyword !is null //&& keyword.isOperator()
				? keyword : IDENTIFIER;
	}

}

unittest {
	import asserts;

	void test(string s, Token[] tokens...) {
		Lexer lexer = new Lexer(s);
		foreach (t; tokens)
			Assert(lexer.next(), Is(t), "input: '" ~ s ~ "'");
	}
	void testAll(string s, Token[] tokens...) {
		Lexer lexer = new Lexer(s);
		foreach (t; tokens)
			Assert(lexer.nextAll(), Is(t), "input: '" ~ s ~ "'");
	}
	void testVal(string s, Token token, string value = null) {
		if (value is null)
			value = s;
		Lexer lexer = new Lexer(s);
		Assert(lexer.nextAll(), Is(token));
		Assert(lexer.value, Is(value));	
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
	test("0xx", ERROR);
	testVal("0x7f", NUMBER);
	test("0xg", ERROR);
	testVal("123", NUMBER);
	testVal("0123", NUMBER);
}