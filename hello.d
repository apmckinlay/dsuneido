import std.stdio; 

void main() {
   writeln("Hello, world!");
   int[][] as = new int[][0];
   as ~= new int[0];
   as[0] ~= 123;
   writeln(as[0][0]);
}