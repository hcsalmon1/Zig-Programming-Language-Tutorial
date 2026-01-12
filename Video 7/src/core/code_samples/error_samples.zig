

pub const ERROR_1 = 
\\
\\fn void main() {
\\  int value = 10
\\  println(value);
\\}
;

pub const ERROR_2 = 
\\
\\fnbbbbb void main() {
\\
\\}
;

pub const ERROR_3 = 
\\
\\fn void main() DEERRRRP {
\\
\\}
;

pub const ERROR_4 = 
\\
\\
\\fn void main() {
\\  Thing thing;
\\  thing.value = 10;
\\  println(thing.value);
\\}
\\
;