
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

pub const BRACKET_LEETCODE = 
\\fn bool bracketsMatch(char c, char top_char) {
\\
\\   return c == ')' && top_char == '(' ||
\\          c == '}' && top_char == '{' ||
\\          c == ']' && top_char == '[';
\\}
\\fn bool isValid(string input) {
\\  
\\  [10000]char stack;
\\  int top = -1;
\\  int length = len(input);
\\    
\\  for (int i = 0; i < length; i += 1) {
\\  
\\      char c = input[i];
\\        
\\      bool is_opening_bracket = 
\\          c == '(' ||
\\          c == '{' ||
\\          c == '[';   
\\
\\      if (is_opening_bracket == true) {
\\          top += 1;
\\          stack[top] = c;
\\          continue;
\\      }
\\
\\      if (top == -1) {
\\          return false;
\\      }
\\
\\      char top_char = stack[top];
\\  
\\      if (bracketsMatch(c, top_char) == true) {
\\          top -= 1;
\\          continue;
\\      }
\\      return false;
\\  }
\\    
\\  return top == -1;
\\}
\\
\\fn void main() {
\\
\\  string test1 = "()[]{}";
\\  string test2 = "{[]}";
\\  string test3 = "(]";
\\  string test4 = "([)]";
\\  string test5 = "{[()]}";
\\
\\  bool test1_result = isValid(test1);
\\  bool test2_result = isValid(test2);
\\  bool test3_result = isValid(test3);
\\  bool test4_result = isValid(test4);
\\  bool test5_result = isValid(test5);
\\    
\\  println("Test 1: ", test1, "is valid:", test1_result);
\\  println("Test 2: ", test2, "is valid:", test2_result);
\\  println("Test 3: ", test3, "is valid:", test3_result);
\\  println("Test 4: ", test4, "is valid:", test4_result);
\\  println("Test 5: ", test5, "is valid:", test5_result);
\\}
;