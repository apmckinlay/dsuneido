struct Set(T) {
	bool[T] values;

	this(T[] args...) {
		foreach (arg; args)
			values[arg] = true;
	}

	bool contains(T x) {
		return (x in values) != null;
	}
}

auto mkSet(T)(T[] args...) {
	return Set!T(args);
}

unittest {
	auto x = mkSet(12, 34, 56);
	assert(x.contains(34));
	assert(! x.contains(78));
}