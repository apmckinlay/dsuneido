import std.ascii;
import std.stdio; 
import std.string;
import std.algorithm;

class Token {
	Token other;
	string str;
	TokenFeature feature;
	int oldnum;

	this(T...)(T args) {
		foreach (i, arg; args) {
			static if (is(T[i] == string)) {
				str = arg;
			} else static if (is(T[i] == TokenFeature)) {
				feature = arg;
			} else static if (is(T[i] == int)) {
				oldnum = arg;
			} else static if (is(T[i] == Token)) {
				other = arg;
			}
		}
	}
}

alias long TokenFeature;
enum : TokenFeature {
	INFIX, ASSIGN, TERMOP, SUMOP
}

string tokens(string s) {
	s = s.strip();
	string result = "";
	foreach (line; s.splitLines()) {
		auto words = splitter(line.strip());
		string name = words.front().toUpper();
		result ~= "static Token " ~ name ~ ";\n";
		result ~= "static this() { " ~ name ~ " = new Token(";
		if (name == words.front())
			words.popFront();
		foreach (word; words) {
			if (word[0].isDigit() || word[0].isUpper())
				result ~= word ~ ", ";
			else
				result ~= `"` ~ word ~ `", `;
		}
		if (result.endsWith(", "))
			result = result[0 .. $-2]; 
		result ~= "); }\n";
	}
	return result;
}

void main() {
	writeln(tokens("
		NIL
		EOF
		ERROR 1000
		if
		LT < TERMOP
		ADD + INFIX
		R_PAREN ) L_PAREN
		L_PAREN ( R_PAREN
		"));

	//assert(IF.str == "if");
	//assert(LT.str == "<");
	//assert(ERROR.oldnum == 1000);
	//assert(ADD.feature == INFIX);
	//assert(L_PAREN.other == R_PAREN);
	//assert(R_PAREN.other == L_PAREN);
}

static Token NIL;
static this() { NIL = new Token(); }
static Token EOF;
static this() { EOF = new Token(); }
static Token ERROR;
static this() { ERROR = new Token(1000); }
static Token IF;
static this() { IF = new Token("if"); }
static Token LT;
static this() { LT = new Token("<", TERMOP); }
static Token ADD;
static this() { ADD = new Token("+", INFIX); }
static Token R_PAREN;
static this() { R_PAREN = new Token(")", L_PAREN); }
static Token L_PAREN;
static this() { L_PAREN = new Token("(", R_PAREN); }

//mixin(tokens("
//	NIL
//	EOF
//	ERROR 1000
//	if
//	LT < TERMOP
//	ADD + INFIX
//	R_PAREN ) L_PAREN
//	L_PAREN ( R_PAREN
//	"));
