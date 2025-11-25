

pub const ARRAY_1 = 
\\
\\fn void main() {
\\  []int array = {1,2,3,4,5};
\\}
;

pub const ARRAY_2 = 
\\
\\fn void main() {
\\  []int array = {1,2,3,4,5};
\\  int index = 0;
\\  while (index < 5) {
\\      println("index", index, "=", array[index]);
\\      index += 1;
\\  }
\\}
;

pub const ARRAY_3 = 
\\
\\fn void main() {
\\  []int array = {1,2,3,4,5};
\\  array = append(array, 6);
\\  int length = len(array);
\\  int index = 0;
\\  while (index < length) {
\\      println("index", index, "=", array[index]);
\\      index += 1;
\\  }
\\}
;