

pub const RETURN_ZERO = 
\\fn i32 main() {
\\   return 0;
\\}
;

pub const RETURN_ZERO_WITH_INT = 
\\fn i32 main() {
\\   i32 number = 10;
\\   return 0;
\\}
;

pub const RETURN_10_PLUS_10 = 
\\fn void main() {
\\   return 10 + 10;
\\}
;

pub const HELLO_WORLD =
\\fn void main() {
\\    println("Hello world!");
\\    return 0;
\\}
;

pub const ADD = 

\\fn i32 add(i32 a, i32 b) {
\\   return a + b;
\\}
\\
\\fn i32 main() {
\\    i32 add_result = add(10, 10);
\\    return 0;
\\}
;

pub const GLOBAL = 
\\i32 number = 10;
;

pub const MANY_EXAMPLES = 
\\i32 global = 10;
\\
\\fn main() {
\\  if (global == 10) {
\\      println("global = ", global);
\\  }
\\  //this is a comment
\\  string phrase = "Hello World!";
\\  println(phrase);
\\  for (i32 i = 0; i < 10; i += 1) {
\\      println(i);
\\  }
\\}
;
