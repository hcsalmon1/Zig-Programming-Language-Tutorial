
pub const ARRAY_FUNCTION = 
\\
\\fn []int getArray([]int array) {
\\
\\}
\\
\\fn void main() {
\\
\\}
;

pub const ARRAY_FUNCTION_2 = 
\\
\\fn []int getArray([]int array) {
\\  array[0] += 1
\\  return array
\\}
\\
\\fn void main() {
\\  
\\}
;

pub const TWO_SUM = 
\\
\\fn []int twoSum([]int array, int target){
\\  []int output = {0, 0};
\\  for (int first_index = 0; first_index < 4; first_index += 1) {
\\
\\      for (int second_index = first_index + 1; second_index < 4; second_index += 1) {
\\
\\          bool is_target = array[first_index] + array[second_index] == target;
\\          if (is_target == true) {
\\
\\              output[0] = first_index;
\\              output[1] = second_index;
\\              return output;
\\          }
\\      }
\\  }
\\  return output;
\\}
\\
\\fn void main() {
\\
\\  []int numbers = {2,7,11,15};
\\  []int result = twoSum(numbers, 9);
\\  println("result 0:", result[0], "result 1:", result[1]);
\\}
\\
;

pub const MANY_EXAMPLES = 

\\
\\fn void main() {
\\  int value = 10;
\\  if (value == 10) {
\\      println("global = ", global);
\\  }
\\  
\\  string phrase = "Hello World!";
\\  println(phrase);
\\  for (i32 i = 0; i < 10; i += 1) {
\\      println(i);
\\  }
\\}
;

pub const HELLO_WORLD =
\\fn void main() {
\\    println("Hello world!");
\\}
;