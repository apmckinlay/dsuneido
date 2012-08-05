@safe
import std.conv;
import std.algorithm;

class Matcher(T) {
	abstract bool matches(const T x);
	abstract string message(const T x);
}

class IsMatcher(T) : Matcher!T {
	private const T expected;

	this(const T expected) {
		this.expected = expected;
	}
	bool matches(const T x) {
		return x == expected;
	}
	string message(const T x) {
		return "Expected: " ~ expected.to!string() ~ 
				" but it was: " ~ x.to!string();
	}
}
static auto Is(T)(const T x) {
	return new IsMatcher!T(x);
}

class StartsWithMatcher(T) : Matcher!T {
	private const T prefix;

	this(const T prefix) {
		this.prefix = prefix;
	}
	bool matches(const T x) {
		return startsWith(x, prefix);
	}
	string message(const T x) {
		static if (is(T == string))
			return `Expected a string starting with: "` ~ prefix ~ 
				`" but it was: "` ~ x ~ `"`;
		else
			return "Expected a range starting with: " ~ prefix.to!string() ~ 
				" but it was: " ~ x.to!string();
	}
}
static auto StartsWith(T)(const T x) {
	return new StartsWithMatcher!T(x);
}

void Assert(T1,T2)(T1 x, Matcher!T2 matcher, lazy string message = "") {
	assert(matcher.matches(x), matcher.message(x) ~ " " ~ message);
}

unittest {
	Assert(100 + 20 + 3, Is(123));
	Assert("hi" ~ "lo", Is("hilo"));
	Assert("fred", StartsWith("fre"));
	Assert([1,2,3], StartsWith([1,2]));
}