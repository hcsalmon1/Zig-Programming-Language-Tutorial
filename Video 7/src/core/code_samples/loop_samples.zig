

pub const FOR_1 = 
\\fn void main() {
\\  for (int i = 0; i < 10; i += 1) {
\\      println("i: ", i);
\\  }
\\}
;

pub const FOR_CONTINUE_1 = 
\\fn void main() {
\\  for (int i = 0; i < 10; i += 1) {
\\      if (i < 2) {
\\          continue;
\\      }
\\      println("i: ", i);
\\  }
\\}
;

pub const FOR_BREAK_1 = 
\\fn void main() {
\\  for (int i = 0; i < 10; i += 1) {
\\      if (i > 8) {
\\          break;
\\      }
\\      println("i: ", i);
\\  }
\\}
;

pub const WHILE_1 =
\\
\\fn void main() {
\\  int value = 1;
\\  while(value < 10) {
\\      println("value:", value);
\\      value += 1;
\\  }
\\}
\\
;