

pub const ENUM_1 = 
\\
\\enum EmployeeType {
\\  Admin,
\\  Regular,
\\  Intern,
\\}
\\
;

pub const ENUM_2 = 
\\
\\enum EmployeeType {
\\  Admin,
\\  Regular,
\\  Intern,
\\}
\\
\\fn void main() {
\\  int employee_type = EmployeeType.Admin;
\\  string employee_type_text = EmployeeTypeToString(employee_type);
\\  println("employee type:", employee_type_text);
\\}
;