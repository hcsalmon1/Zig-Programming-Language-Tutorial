

pub const STRUCT_1 = 
\\
\\struct Person {
\\  int age;
\\  string name;
\\}
;

pub const STRUCT_2 = 
\\
\\struct Person {
\\  int age;
\\  string name;
\\}
\\
\\fn void main() {
\\  Person person;
\\  person.age = 20;
\\  person.name = "john";
\\  println("name:", person.name, ", age:", person.age);
\\}
;

pub const STRUCT_3 = 
\\
\\struct Person {
\\  []*int age;
\\  string name;
\\}
\\
;

pub const STRUCT_ERROR = 
\\
\\struct Person {
\\  int age
\\  string name
\\}
\\
\\fn void main() {
\\  Person person;
\\  person.age = 20;
\\  person.name = "john";
\\  println("name:", person.name, ", age:", person.age);
\\}
;