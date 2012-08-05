@safe
import std.string;
import std.conv;

const class Token {
	string name;
	int oldnum;
	TokenFeature feature;
	string str;

	this(string name, int oldnum = 0, TokenFeature feature = 0, string str = "") {
		this.name = name;
		this.oldnum = oldnum;
		this.feature = feature;
		this.str = str;
	}

	bool opEquals(Object rhs) const {
		return this is rhs;
	}

	string toString() const {
		return name;
	}
}

alias long TokenFeature;
enum : TokenFeature {
	INFIX, ASSIGN, TERMOP, SUMOP
}

static Token[string] keywords;

private string tokens(string[] ts...) {
	return join(ts, "\n");
}

private string t(string name, int num = 0) {
	return t(name, 0, num);
}

private string t(string name, TokenFeature feature, int num) {
	return t(name, "", feature, num);
}

private string t(string name, string str, int num = 0) {
	return t(name, str, 0, num);
}

private string t(string name, string str, TokenFeature feature, int num) {
	string uname = name.toUpper();
	string result = "static const(Token) " ~ uname ~ ";\n";
	result ~= init(uname ~ ` = new Token("` ~ name ~ `", ` ~ 
		to!string(num) ~ `, ` ~ to!string(feature) ~ `, "` ~ str ~ `");`);
	if (uname != name) 
		result ~= "\n" ~ init(`keywords["` ~ name ~ `"] = cast(Token) ` ~ uname ~ `;`);
	return result;
}

private string init(string s) {
	return "static this() { " ~ s ~ " }";
}

mixin(tokens(
	t("NIL"), t("EOF"), t("ERROR", 1000),
	t("IDENTIFIER", 1001), t("NUMBER", 1002), t("STRING", 1003),
	t("and", INFIX, 1004), t("or", INFIX, 1005),
	t("WHITE", 1006), t("COMMENT", 1007), t("NEWLINE", 1008),
	t("HASH", 35), t("COMMA", 44), t("COLON", 58), t("SEMICOLON", 59), 
	t("Q_MARK", INFIX, 63), t("AT", 64), t("DOT", 46),
	t("R_PAREN", 41), t("L_PAREN", 40),
	t("R_BRACKET", 93), t("L_BRACKET", 91),
	t("R_CURLY", 125), t("L_CURLY", 123),
	t("IS", "is", TERMOP, 251), t("ISNT", "isnt", TERMOP, 252),
	t("MATCH", "=~", INFIX, 253), t("MATCHNOT", "!~", INFIX, 254),
	t("LT", "<", TERMOP, 6), t("LTE", "<=", TERMOP, 7),
	t("GT", ">", TERMOP, 8), t("GTE", ">=", TERMOP, 9),
	t("not", 10), t("INC", 140), t("DEC", 142), t("BITNOT", "~", 11),
	t("ADD", "+", INFIX, 240), t("SUB", "-", INFIX, 241), 
	t("CAT", "$", INFIX, 242),
	t("MUL", "*", INFIX, 243), t("DIV", "/", INFIX, 244), 
	t("MOD", "%", INFIX, 245),
	t("LSHIFT", "<<", INFIX, 246), t("RSHIFT", ">>", INFIX, 247),
	t("BITOR", "|", INFIX, 248), t("BITAND", "&", INFIX, 249), 
	t("BITXOR", "^", INFIX, 250),
	t("EQ", "=", ASSIGN, 139),
	t("ADDEQ", "+=", ASSIGN, 128), t("SUBEQ", "-=", ASSIGN, 129), 
	t("CATEQ", "$=", ASSIGN, 130),
	t("MULEQ", "*=", ASSIGN, 131), t("DIVEQ", "/=", ASSIGN, 132), 
	t("MODEQ", "%=", ASSIGN, 133),
	t("LSHIFTEQ", "<<=", ASSIGN, 134), t("RSHIFTEQ", ">>=", ASSIGN, 135),
	t("BITOREQ", "|=", ASSIGN, 136), t("BITANDEQ", "&=", ASSIGN, 137), 
	t("BITXOREQ", "^=", ASSIGN, 138),
	t("RANGETO", ".."), t("RANGELEN", "::"),
	// keywords
	t("if", 1), t("else", 2), t("while", 3), t("do", 4), t("for", 5), 
	t("forever", 7), t("break", 8), t("continue", 9), t("switch", 10), 
	t("case", 11), t("default", 12), t("function", 13), t("class", 14), 
	t("catch", 15), t("dll", 16), t("struct", 17), t("callback", 18),
	t("new", 19), t("return", 20), t("try", 21), t("throw", 22),
	t("super", 23), t("true", 24), t("false", 25), t("in", 27), 
	t("this", 29),
	// for queries
	t("view"), t("sview"), t("create"), t("ensure"),
	t("drop"), t("alter"), t("delete"),
	t("rename"), t("to"), t("unique"),
	t("cascade"), t("updates"), t("index"), t("key"),
	t("total", SUMOP), t("sort"), t("project"), t("max", SUMOP),
	t("min", SUMOP), t("minus"), t("intersect"),
	t("list", SUMOP), t("union"), t("remove"), t("history"),
	t("extend"), t("count", SUMOP), t("times"), t("by"),
	t("summarize"), t("where"), t("join"), t("leftjoin"),
	t("reverse"), t("average", SUMOP),
	t("into"), t("insert"), t("update"), t("set"),
	// for AST
	t("DATE"), t("SYMBOL"), t("CALL"), t("MEMBER"), t("SUBSCRIPT"), t("ARG"), 
	t("FOR_IN"), t("RECORD"), t("OBJECT"), t("BINARYOP"), t("SELFREF"), 
	t("ASSIGNOP"), t("PREINCDEC"), t("POSTINCDEC"), t("BLOCK"), t("RVALUE"), 
	t("METHOD")
	));

unittest {
	import asserts;

	Assert(NIL.name, Is("NIL"));
	Assert(AND.oldnum, Is(1004));
	Assert(MATCH.str, Is("=~"));
	Assert(keywords["view"], Is(VIEW));
}
/*
import std.stdio; 

void main() {

	writeln(tokens(
	t("NIL"), t("EOF"), t("ERROR", 1000),
	t("IDENTIFIER", 1001), t("NUMBER", 1002), t("STRING", 1003),
	t("and", INFIX, 1004), t("or", INFIX, 1005),
	t("WHITE", 1006), t("COMMENT", 1007), t("NEWLINE", 1008),
	t("HASH", 35), t("COMMA", 44), t("COLON", 58), t("SEMICOLON", 59), 
	t("Q_MARK", INFIX, 63), t("AT", 64), t("DOT", 46),
	t("R_PAREN", 41), t("L_PAREN", 40),
	t("R_BRACKET", 93), t("L_BRACKET", 91),
	t("R_CURLY", 125), t("L_CURLY", 123),
	t("IS", "is", TERMOP, 251), t("ISNT", "isnt", TERMOP, 252),
	t("MATCH", "=~", INFIX, 253), t("MATCHNOT", "!~", INFIX, 254),
	t("LT", "<", TERMOP, 6), t("LTE", "<=", TERMOP, 7),
	t("GT", ">", TERMOP, 8), t("GTE", ">=", TERMOP, 9),
	t("not", 10), t("INC", 140), t("DEC", 142), t("BITNOT", "~", 11),
	t("ADD", "+", INFIX, 240), t("SUB", "-", INFIX, 241), 
	t("CAT", "$", INFIX, 242),
	t("MUL", "*", INFIX, 243), t("DIV", "/", INFIX, 244), 
	t("MOD", "%", INFIX, 245),
	t("LSHIFT", "<<", INFIX, 246), t("RSHIFT", ">>", INFIX, 247),
	t("BITOR", "|", INFIX, 248), t("BITAND", "&", INFIX, 249), 
	t("BITXOR", "^", INFIX, 250),
	t("EQ", "=", ASSIGN, 139),
	t("ADDEQ", "+=", ASSIGN, 128), t("SUBEQ", "-=", ASSIGN, 129), 
	t("CATEQ", "$=", ASSIGN, 130),
	t("MULEQ", "*=", ASSIGN, 131), t("DIVEQ", "/=", ASSIGN, 132), 
	t("MODEQ", "%=", ASSIGN, 133),
	t("LSHIFTEQ", "<<=", ASSIGN, 134), t("RSHIFTEQ", ">>=", ASSIGN, 135),
	t("BITOREQ", "|=", ASSIGN, 136), t("BITANDEQ", "&=", ASSIGN, 137), 
	t("BITXOREQ", "^=", ASSIGN, 138),
	t("RANGETO", ".."), t("RANGELEN", "::"),
	// keywords
	t("if", 1), t("else", 2), t("while", 3), t("do", 4), t("for", 5), 
	t("forever", 7), t("break", 8), t("continue", 9), t("switch", 10), 
	t("case", 11), t("default", 12), t("function", 13), t("class", 14), 
	t("catch", 15), t("dll", 16), t("struct", 17), t("callback", 18),
	t("new", 19), t("return", 20), t("try", 21), t("throw", 22),
	t("super", 23), t("true", 24), t("false", 25), t("in", 27), 
	t("this", 29),
	// for queries
	t("view"), t("sview"), t("create"), t("ensure"),
	t("drop"), t("alter"), t("delete"),
	t("rename"), t("to"), t("unique"),
	t("cascade"), t("updates"), t("index"), t("key"),
	t("total", SUMOP), t("sort"), t("project"), t("max", SUMOP),
	t("min", SUMOP), t("minus"), t("intersect"),
	t("list", SUMOP), t("union"), t("remove"), t("history"),
	t("extend"), t("count", SUMOP), t("times"), t("by"),
	t("summarize"), t("where"), t("join"), t("leftjoin"),
	t("reverse"), t("average", SUMOP),
	t("into"), t("insert"), t("update"), t("set"),
	// for AST
	t("DATE"), t("SYMBOL"), t("CALL"), t("MEMBER"), t("SUBSCRIPT"), t("ARG"), 
	t("FOR_IN"), t("RECORD"), t("OBJECT"), t("BINARYOP"), t("SELFREF"), 
	t("ASSIGNOP"), t("PREINCDEC"), t("POSTINCDEC"), t("BLOCK"), t("RVALUE"), 
	t("METHOD")
	));
	writeln("keywords ", keywords);
}
*/
