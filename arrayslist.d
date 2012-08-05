class ArraysList(T) {
	immutable ARRAY_SIZE = 1024;
	private T[][] arrays;

	this() {
		arrays = new T[][0];
	}

	void add(T value) {
		if (array(size()) >= arrays.length)
			arrays ~= new T[0];
		arrays[arrays.length - 1] ~= value;
	}

	T get(size_t i) {
		return arrays[array(i)][index(i)];
	}

	size_t size() {
		return arrays.length is 0 ? 0
			: ARRAY_SIZE * (arrays.length - 1) + arrays[arrays.length - 1].length;
	}

	private size_t array(size_t i) {
		return i / ARRAY_SIZE;
	}
	private size_t index(size_t i) {
		return i % ARRAY_SIZE;
	}

}

unittest {
	import std.stdio; 

	auto a = new ArraysList!int();
	assert(a.size() == 0);
	a.add(123);
	assert(a.size() == 1);
	assert(a.get(0) == 123);
	foreach (i; 0 .. 2000)
		a.add(i);
	assert(a.get(1001) == 1000);
	writeln("ok");
}