

pub const DECLARATION_1 = 

\\fn void main() {
\\
\\  int value = 10;
\\
\\}
;

pub const DECLARATION_2 = 

\\fn void main() {
\\
\\  string value = "hello";
\\
\\}
;

pub const DECLARATION_3 = 

\\fn void main() {
\\
\\  []int value = {1,2,3,4,5};
\\
\\}
;

pub const GLOBAL = 
\\i32 number = 10;
;

pub const REASSIGNMENT_1 = 
\\
\\fn void main() {
\\  int value = 1;
\\  value += 1;
\\  println(value);
\\}
;