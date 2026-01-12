

pub const IF_1 = 
\\
\\fn void main() {
\\  if (0 < 1) {
\\      println("zero is less than one");
\\  }
\\}
;

pub const IF_2 = 
\\
\\fn int add(int a, int b) {
\\  return a + b;
\\}
\\
\\fn void main() {
\\  int add_result = add(10, 10);
\\  if (add_result > 10) {
\\      println("result > 10");
\\  }
\\}
;

pub const IF_3 = 
\\
\\fn int add(int a, int b) {
\\  return a + b;
\\}
\\
\\fn void main() {
\\  int add_result = add(10, 10);
\\  bool is_true = true;
\\  if (add_result > 10 && is_true) {
\\      println("result > 10");
\\  }
\\}
;

pub const IF_ELSE_1 = 
\\
\\fn void main() {
\\  int value = 1;
\\  if (value > 1) {
\\      println("value is higher than one");
\\  } else if (value < 1) {
\\      println("value is less than one");
\\  } else {
\\      println("value is one");  
\\  }
\\}
\\
;
