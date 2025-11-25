

pub const INT_DECLARATION_1 = 

\\fn void main() {
\\
\\  int value = 10;
\\
\\}
;

pub const STRING_DECLARATION_1 = 

\\fn void main() {
\\
\\  string value = "hello";
\\
\\}
;

pub const ARRAY_DECLARATION_1 = 

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

pub const CHAR_DECLARATION_1 = 
\\
\\fn void main() {
\\  char letter = 'a';
\\  println(letter);
\\}
\\
;

pub const FLOAT_DECLARATION_1 = 
\\
\\fn void main() {
\\  f32 decimal = 10.1;
\\  println(decimal);
\\}
\\
;

pub const FLOAT_DECLARATION_2 = 
\\
\\fn void main() {
\\  f32 decimal_a = 0.99999;
\\  f32 decimal_b = 0.00001;
\\  f32 decimal = decimal_a + decimal_b;
\\  println(decimal);
\\}
\\
;

pub const FLOAT_DECLARATION_3 = 
\\
\\fn void main() {
\\  f64 decimal_a = 1;
\\  f64 decimal_b = 0.00001;
\\  f64 decimal = decimal_a + decimal_b;
\\  println(decimal);
\\}
\\
;

pub const PRINT_TEST_1 =
\\
\\fn void main() {
\\  
\\  println(10.1);
\\}
;

pub const ARRAY_SIZE_1 = 
\\
\\fn void main() {
\\  [10000]char array;
\\}
\\
;