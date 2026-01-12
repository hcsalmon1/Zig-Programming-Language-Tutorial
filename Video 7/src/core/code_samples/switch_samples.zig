

pub const SWITCH_1 = 
\\
\\fn void main() {
\\  int value = 1;
\\  switch (value) {
\\      case 0:
\\          println("Zero");
\\      case 1:
\\          println("One");
\\      case 2:
\\          println("Two");
\\      default:
\\          println("Other");
\\  }
\\}
;

pub const SWITCH_2 = 
\\
\\struct Thing {
\\  int value;
\\}
\\
\\fn void main() {
\\  Thing thing;
\\  thing.value = 0;
\\  switch (thing.value) {
\\      case 0:
\\          println("Zero");
\\      case 1:
\\          println("One");
\\      case 2:
\\          println("Two");
\\      default:
\\          println("Other");
\\  }
\\}
;