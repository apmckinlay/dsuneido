
import std.algorithm;
import set;

class TokenInfo {
	int other;
	string str;
	private Feature feature;
	ResultType resultType;
	string method;
	int oldnum;

	this(T...)(T args) {
		foreach (arg; args) {
			if (string s = cast(string) arg)
				str = s;
		}
	}

}

static TokenInfo[int] info;

enum Feature {
	INFIX, ASSIGN, TERMOP, SUMOP
}

enum ResultType {
	I, N, S, B, B_, O
}

string t(T...)(int token, T args) {
	import std.conv;
	string s = "info[" ~ to!string(token) ~ "] = new TokenInfo(";
	foreach (i, arg; args) {
		if (i > 0)
			s ~= ", ";
		if (cast(string) arg)
			s ~= "\"" ~ arg ~ "\"";
		else
			s ~= arg;
	}
	return s ~ ");";
}

enum Token {
	NIL, EOF, ERROR, 
	IDENTIFIER = 1001, NUMBER, STRING, AND, OR, WHITE, COMMENT, NEWLINE,
	HASH = 35, L_PAREN = 40, R_PAREN = 41, COMMA = 44, DOT = 46, 
	COLON = 58, SEMICOLON = 59, Q_MARK = 63, AT = 64, 
	L_BRACKET = 91, R_BRACKET = 93, L_CURLY = 123, R_CURLY = 125,
	ADDEQ = 128, SUBEQ, CATEQ, MULEQ, DIVEQ, MODEQ, LSHIFTEQ, RSHIFTEQ,
	BITOREQ, BITANDEQ, BITXOREQ, RANGETO, RANGELEN,

	IS = 251, ISNT, MATCH, MATCHNOT, 
	LT = 6, LTE, GT, GTE, NOT, BITNOT,
	EQ = 139, INC = 140, DEC = 142,
	ADD = 240, SUB, CAT, MUL, DIV, MOD, LSHIFT, RSHIFT,
	BITOR, BITAND, BITXOR,

	IF = 2000, ELSE, WHILE, DO, FOR, FOREVER, BREAK, CONTINUE, 
	SWITCH, CASE, DEFAULT, FUNCTION, CLASS, CATCH, DLL, STRUCT, CALLBACK,
	NEW, RETURN, TRY, THROW, SUPER, TRUE, FALSE, IN, THIS,
	VIEW
};
alias Token T;

static Set!T keywords;
static this() {
	keywords = mkSet(T.IF , T.ELSE, T.WHILE, T.DO, 
		T.FOR, T.FOREVER, T.BREAK, T.CONTINUE, 
		T.SWITCH, T.CASE, T.DEFAULT, T.FUNCTION, T.CLASS, 
		T.CATCH, T.DLL, T.STRUCT, T.CALLBACK, T.NEW, 
		T.RETURN, T.TRY, T.THROW, T.SUPER, T.TRUE, 
		T.FALSE, T.IN, T.THIS);
}

bool isKeyword(T token) {
	return keywords.contains(token);
}

static this() {
	//mixin(t(T.AND, INFIX));
	//mixin(t(T.VIEW, "view"));
/*	NIL, EOF, ERROR(1000),
	IDENTIFIER(1001), NUMBER(1002), STRING(1003),
	AND("and", INFIX, 1004), OR("or", INFIX, 1005),
	WHITE(1006), COMMENT(1007), NEWLINE(1008),
	HASH(35), COMMA(44), COLON(58), SEMICOLON(59), Q_MARK(INFIX, 63), AT(64), DOT(46),
	R_PAREN(41), L_PAREN(R_PAREN, 40),
	R_BRACKET(93), L_BRACKET(R_BRACKET, 91),
	R_CURLY(125), L_CURLY(R_CURLY, 123),
	IS("is", TERMOP, B, 251), ISNT("isnt", TERMOP, B, 252),
	MATCH("=~", INFIX, B, 253), MATCHNOT("!~", INFIX, B, 254),
	LT("<", TERMOP, B, 6), LTE("<=", TERMOP, B, 7),
	GT(">", TERMOP, B, 8), GTE(">=", TERMOP, B, 9),
	NOT("not", B, 10), INC(140), DEC(142), BITNOT("~", 11),
	ADD("+", INFIX, N, 240), SUB("-", INFIX, N, 241), CAT("$", INFIX, O, 242),
	MUL("*", INFIX, N, 243), DIV("/", INFIX, N, 244), MOD("%", INFIX, N, 245),
	LSHIFT("<<", INFIX, I, 246), RSHIFT(">>", INFIX, I, 247),
	BITOR("|", INFIX, I, 248), BITAND("&", INFIX, I, 249), BITXOR("^", INFIX, I, 250),
	EQ("=", ASSIGN, 139),
	ADDEQ("+=", ASSIGN, N, 128), SUBEQ("-=", ASSIGN, N, 129), CATEQ("$=", ASSIGN, O, 130),
	MULEQ("*=", ASSIGN, N, 131), DIVEQ("/=", ASSIGN, N, 132), MODEQ("%=", ASSIGN, N, 133),
	LSHIFTEQ("<<=", ASSIGN, I, 134), RSHIFTEQ(">>=", ASSIGN, I, 135),
	BITOREQ("|=", ASSIGN, I, 136), BITANDEQ("&=", ASSIGN, I, 137), BITXOREQ("^=", ASSIGN, I, 138),
	RANGETO(".."), RANGELEN("::"),
	// keywords
	IF("if", 1), ELSE("else", 2),
	WHILE("while", 3), DO("do", 4), FOR("for", 5), FOREVER("forever", 7),
	BREAK("break", 8), CONTINUE("continue", 9),
	SWITCH("switch", 10), CASE("case", 11), DEFAULT("default", 12),
	FUNCTION("function", 13), CLASS("class", 14), CATCH("catch", 15),
	DLL("dll", 16), STRUCT("struct", 17), CALLBACK("callback", 18),
	NEW("new", 19), RETURN("return", 20), TRY("try", 21), THROW("throw", 22),
	SUPER("super", 23), TRUE("true", 24), FALSE("false", 25),
	IN("in", 27), THIS("this", 29),
	// for queries
	VIEW("view"), SVIEW("sview"), CREATE("create"), ENSURE("ensure"),
	DROP("drop"), ALTER("alter"), DELETE("delete"),
	RENAME("rename"), TO("to"), UNIQUE("unique"),
	CASCADE("cascade"), UPDATES("updates"), INDEX("index"), KEY("key"),
	TOTAL("total", SUMOP), SORT("sort"), PROJECT("project"), MAX("max", SUMOP),
	MIN("min", SUMOP), MINUS("minus"), INTERSECT("intersect"),
	LIST("list", SUMOP), UNION("union"), REMOVE("remove"), HISTORY("history"),
	EXTEND("extend"), COUNT("count", SUMOP), TIMES("times"), BY("by"),
	SUMMARIZE("summarize"), WHERE("where"), JOIN("join"), LEFTJOIN("leftjoin"),
	REVERSE("reverse"), AVERAGE("average", SUMOP),
	INTO("into"), INSERT("insert"), UPDATE("update"), SET("set"),
	// for AST
	DATE, SYMBOL, CALL, MEMBER, SUBSCRIPT, ARG, FOR_IN, RECORD, OBJECT, BINARYOP,
	SELFREF, ASSIGNOP, PREINCDEC, POSTINCDEC, BLOCK, RVALUE, METHOD,
	NOT_(NOT, "not_", B_), IS_(IS, "is_", B_), ISNT_(ISNT, "isnt_", B_),
	MATCH_(MATCH, "match_", B_), MATCHNOT_(MATCHNOT, "matchnot_", B_),
	LT_(LT, "lt_", B_), LTE_(LTE, "lte_", B_), GT_(GT, "gt_", B_), GTE_(GTE, "gte_", B_),
	CLOSURE */
}

unittest {
	assert(T.NIL != T.EOF);
	//assert(info[T.VIEW].str == "view");
	assert(T.FOREVER.isKeyword());
}

import std.stdio; 

void main() {
}