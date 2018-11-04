## Go Syntax

### Overview

A Go source file contains a package clause,
followed by zero or more import declarations,
followed by zero or more package-level declarations.

A package-level declaration is a declaration of a package
constant, variable, type, function, or method.
All of these begin with a keyword which is one of
`const`, `var`, `type`, or `func`.
These declarations can appear in any order.
These are the only statements that can appear outside of functions.
This precludes use of the `:=` operator and
non-declaration statements, like `if` and `for`,
outside of functions.

Package-level names that start uppercase are "exported".
This means that other packages that import the package
can access them.

Types follow variable and parameter names, separated by a space.
For example, `var score int8`.

Semicolons are not required, but can be used
to place multiple statements on the same line.
However, the `gofmt` code formatting tool
will place each statement on a separate line
and remove semicolons.

In some languages `string[]` represents an array of strings.
In a GraphQL schema, this would be written as `[string]`.
But Go chooses a third option, `[]string`
which was inspired by Algol 68.

### Packages

All Go code resides in some package.
A package is defined by a collection of Go source files
in a single directory.
It defines a namespace for the names it defines.
The source files that define a package
can have any file name that ends in `.go`.

Exported names of a package start uppercase and are visible
in source files of other packages that import the package.
Unexported names start lowercase and are not in visible
in the source files of other packages.
All names, exported or unexported, are visible
in all source files of the package.

All source files must start with a `package` statement
that includes a package name.
The package name must be lowercase and
match the name of the directory that holds the file,
unless the package name is "main".

The `main` function is the starting point of all Go applications
and must defined in a source that starts with `package main`.

For example, if the file `foo.go` is in a directory named `bar`,
the first non-comment line in the file should be `package bar`.

Changing a package name requires renaming the directory
and modifying the `package` statement in all the files.
It seems Go missed an opportunity to
infer the package name from the directory name.

Packages used by an application or by other packages are not required
to have unique names, but their import paths must be unique.
For example, the import paths `alpha/one` and `beta/one` can coexist
even though the package name for both is `one`.
However, to use both in the same source file,
one of them will need to be given an alias (described later).

The full name used to import a package is referred to as its "import path".
These are slash-separate names.
For standard library packages, this is a simple name
such as `"strings"` or `"math/rand"`.
For community packages, this is the URL without the scheme portion.
For example, to import the package at
<https://github.com/julienschmidt/httprouter>
use `import "github.com/julienschmidt/httprouter"`.
This binds the short name "httprouter" to be used
for accessing the names exported by the package.

Refer to the names exported by an imported package
by preceding them with the package name followed by a period.
For example, `httprouter.ResponseWriter`.
It is not possible to add the exported names to the current namespace
to avoid using the `pkgName.` prefix.

An `import` statement imports all the exported symbols in given packages.
The imported names are available in the source file
containing the `import` statement, but not automatically
available in other source files of the same package.
It is not possible to import just a subset
of the names exported by a given package.

To import one package, `import "pkgName"`.

To import multiple packages, `import ("pkgName1" "pkgName2" ...)`.

Unused imports are treated as errors
and some tools automatically remove them.
This avoids accumulating imports that are
no longer needed as the code is modified.

An alternate name for a package name can be defined
with `import altName "pkgName"`.
Note that the alternate name is not surrounded by quotes,
but the package name is.
When an alternate name is defined,
exported names in the package must be referenced with
`altName.ExportedName`.

Circular imports where an import triggers the
import of the current package are treated as errors.

### Package Initialization

Initialization of package-level variables that require logic,
not just literal values or results of function calls,
must be done in `init` functions
that have no parameters and no return value.

A package can have any number of `init` functions
in any of its source files.
These functions are run in the order they appear,
and alphabetically by source file name within a package.

The `init` functions of all imported packages
are run before those of a given package.
All `init` functions of all imported packages are run
before the `main` function of an application is run.

### Names

Names for variables, types, functions, methods, and parameters
must begin with a unicode letter and can contain
unicode letters, unicode digits, and underscores.

Go convention is for multi-word names to use camelcase and
for acronyms in them to have all their letters in the same case.
For example, `xmlHTTPRequest`.

The `golint` tool requires some well-known acronyms in names
to use the same case for all their letters.
These includes ASCII, HTML, ID, JSON, URL, and XML.

### Comments

Comments in Go use the same syntax as C.

Multi-line comments use `/* ... */`.
These primarily used for the comment at the top of a package
and to temporarily comment out sections of code.
These comments cannot be nested.

Single-line comments use `// ...`.
These are used for all other kinds of comments,
even those above functions.

A single-line comment should precede each exported declaration.
These used by the `go doc` and `godoc` tools that generate documentation.

### Zero Values

Every type as a "zero value" which is the value it takes on when it is not initialized.
There are no uninitialized variables.

| Type                       | Zero Value                                                      |
| -------------------------- | --------------------------------------------------------------- |
| bool                       | false                                                           |
| all numeric types          | 0                                                               |
| rune (single character)    | 0                                                               |
| string                     | ""                                                              |
| array                      | array of proper length where all elements have their zero value |
| slice                      | empty slice with length 0 and capacity 0                        |
| map                        | empty map                                                       |
| struct                     | struct where all fields have their zero value                   |
| pointers & all other types | nil                                                             |

### Variables

Variables in Go have the following characteristics:

- mutable unless primitive and defined with `const`
- block-scoped within functions, so those in
  inner scopes can shadow those in outer scopes
- package-level variables are local to the package
  unless their name starts uppercase

Go distinguishes between declaring, initializing, and assigning variables.

Variables that are declared outside of functions (package-level)
must be declared with a `var` statement.
This accepts a type and/or initial value.
The initial value can be any expression
that yields a value of the desired type.
Examples include:

```go
var name string // defaults to zero value for the type
var name = "Mark"
var name string = "Mark"
```

While both a type and initial value can be provided,
that is usually redundant since
the type can be inferred from the value.
Some editor plugins/extensions will warn about this.

When no type is specified, the largest matching type is assumed.
For example, in `var n = 1.2` the type will be `float64`.

Package-level variables have package scope which means they are
accessible by all files in the package.
They are never garbage collected and so are available for
the entire life of the application in which they are used.

Multiple variables can be declared in one `var` statement.
For example:

```go
var name, age = "Mark", 57 // must initialize all
var (
  name string = "Mark"
  age number // not initialized, so uses zero value
)
```

When multiple consecutive variables have the same type,
the type can be omitted from all but the last.
For example, these are equivalent:

```go
var n1 string, n2 string, a1 int8, a2 int8, a3 int8
var n1, n2 string, a1, a2, a3 int8
```

Variables that are declared inside a function are local to that function.

There are two ways to declare variables inside a function.
One is to use a `var` statement just like when outside a function.
Another is to use the short variable declaration operator `:=`
which does not allow a type to be specified and
instead infers it from the value on the right.
For example, `name := "Mark"`.

Inside function definitions the `var` form of assignment
tends to only be used for two reasons.
The first is when when a variable needs to be declared, but not yet be assigned.
The second is when the desired type differs from that of the initializer.
For example, in the following declaration the type of the variable `n`
would be `int` rather than `int8` if it was not specified: `var n int8 = 19`.

Multiple variables can be declared with one `:=` operator.
For example, `name, age := "Mark", 57`.

It is an error to attempt to declare a variable that has already
been declared, whether with a `var` statement or the `:=` operator.

Variables that have already been declared can be assigned new values
with the `=` operator. For example, `name = "Tami"`.

Multiple variables can be assigned with one `=` operator.
For example, `name, age = "Tami", 56`.
This can also be used to swap values. For example, `x, y = y, x`.
This works with any number of variables.
`x, y, z = y, z, 0` assigns the current value of `y` to `x`,
the current value of `z` to `y`, and zero to `z`.

It is an error to attempt to assign to a variable that has not been defined.

There is an exception to the rule that existing variables cannot be re-declared.
As long as at least one variable on the left of `:=` has not yet been declared,
the other variables can already exist.
A common use case is when the variable `err` is used
to capture possible errors from a function call.

Functions can return any number of values.
The result can be assigned to a list of variables.
For example, `min, max := getXBounds(points)`.
The left-hand side must contain the same number of variables
as values returned by the function.

Sometimes the caller is only interested in a subset of the return values.
The "blank identifier" \_ can be used to discard specific return values.
For example, `_, max := getXBounds(points)`.

### Constants

Go constants are defined using the `const` keyword.
They must be initialized to a primitive literal or an expression
that can be computed at compile-time and results in a primitive value.
For example, `const HOT = 100`.

Non-primitive types such as arrays and structs
cannot be declared with `const`.

Like with `var`, a type can be specified.
This is useful when the desired type cannot be determined from the initializer.
For example, `const HOT float64 = 100`.

When a constant type is not specified they are "untyped".
This allows them to be used in many expressions without explicit conversions
For example, `int` and `float64` values cannot be multiplied
without converting one of the values to the other type.

```go
value := 4.5 // type is float64
const times1 = 3 // type is untyped integer
good := value * times1 // allowed
times2 := 3 // type is int
bad := value * times2 // not allowed
```

For more on untyped constants, see
<https://blog.golang.org/constants>.

### Operators

Go supports the following operators:

- arithmetic: `+`, `-`, `*`, `/`, `%` (mod)
- arithmetic assignment: `+=`, `-=`, `*=`, `/=`, `%=`
- increment: `++`
- decrement: `--`
- assignment: `=` (existing variable), `:=` (new variable)
- comparison: `==`, `!=`, `<`, `<=`, `>`, `>=`
  - Arrays are compared by comparing their elements if they are comparable.
  - Structs are compared by comparing their fields if they are comparable.
  - Slices, maps, and functions are not comparable,
    so cannot be compared using these operators.
- logical: `&&` (and), `||` (or), `!` (not)
- bitwise: `&`, `|`, `^` (xor), `&^` (bit clear)
- bitwise assignment: `&=`, `|=`, `^=`, `&^=`
- bit shift: `<<`, `>>`
- bit shift assignment: `<<=`, `>>=`
- channel direction: `<-`
- variadic parameter: `paramName ...paramType`
- slice spread: `sliceName...`
- pointer creation: `&varName`
- pointer dereference: `*pointerName`
- block delimiters: `{ }`
- expression grouping: `( )`
- function call: `fnName(args)`
- array creation: `[elements]`
- struct member reference: `structName.memberName`
- statement separator: `;`
- array element separator: `,`
- label definition: `someLabel:` (see `goto` keyword)

The increment (`++`) and decrement (`--`) operators form statements,
not expressions. This means they cannot be used in assignment statements.
For example, `var j = i++` is not allowed.

The and (`&&`) and or (`||`) operators short-circuit
like in most programming languages. This means that if the
result is known by only evaluating the left expression,
the right expression is not evaluated.

Go does not include an exponentiation operator.
Use the standard library function
`math.Pow(base, exponent)` function for this.

Go also does not include a ternary operator.
It prefers using an `if` statement which some feel
is more clear, despite being more verbose.

### Keywords

The Go language has 25 keywords which is less than most languages.
This contributes to Go being easy to learn.
These keywords cannot be used as the names of variables,
functions, methods, parameters, interfaces, or types.
The keywords supported by Go include the following,
each of which is described in more detail later:

- `break` - breaks out of a `for` loop, `select`, or `switch`
- `case` - used in a `select` or `switch`
- `chan` - channel type for communicating between goroutines
- `const` - declares a constant
- `continue` - advances to the next iteration of a `for` loop
- `default` - the default case in a `select` or `switch`
- `defer` - defers execution of a given function until the containing function exits
- `else` - part of an `if`
- `fallthrough` - used as last statement in a `case` to execute code in next `case`
- `for` - the only loop syntax; C-style (init, condition, and post) or just a condition
- `func` - defines a named or anonymous function or a method
- `go` - precedes a function call to execute it asynchronously in a goroutine
- `goto` - jumps to a given label (see `:` operator)
- `if` - for conditional logic; also see `else`
- `import` - imports all exported symbols in given package(s)
- `interface` - defines a set of methods;
  typically used to define a type where all implementing types are compatible
- `map` - collection of key/value pairs where keys and values can be any type
- `package` - specifies the package to which the current source file belongs
- `range` - used in a `for` loop to iterate over a
  string, array, slice, map, or receiving channel
- `return` - terminates the containing function and returns zero or more values
- `select` - chooses from a set of channel send or receive operations
- `struct` - collection of fields that each have a specific type
- `switch` - alternative to `if` for choosing a block of code to execute
  based on an expression or type
- `type` - creates an alias for another type; often used to
  give a name to a struct, interface, or function signature
- `var` - defines a variable, its type, and optionally an initial value

There are additional "predeclared names" that are not reserved,
but using them in other contexts could be confusing.
These include the names of primitive types (such as `int` and `string`),
the names of builtin functions (such as `append`, `delete`, `make`, and `range`),
and constants (`true`, `false`, `iota`, and `nil`).

### Pointers

Pointers hold the address of a value or `nil`.
Pointer types begin with an asterisk.
`*Type` is the type for a pointer to a value of type `Type`.

To obtain a pointer to a variable value, `myPtr := &myVar`.
It is not possible to obtain the address of a constant value.

To create a value and get a pointer to it in one line,
`myPtr := new(type)`.
Another way to do this which is preferred by many is
to first create a variable to hold the value
and then get a pointer to it. For example,
`var myThing type; myPtr := &myThing`.
Interestingly the assembly code generated
for these two approaches is identical.

To obtain the value at a pointer, `myValue = *myPtr`.

To modify the value at a pointer, `*myPtr = newValue`.

Pointer arithmetic, as seen in C and C++, is not supported in Go.
This avoids memory safety issues and
simplifies the builtin garbage collector.

Since function parameters are passed by value,
passing a pointer to a variable is required
to allow a function to modify the variable.

### Memory Allocation

The Go specification does not indicate the situations
under which stack memory or heap memory are used.
The primary Go implementation makes some choices
based on the fact that allocating on the stack is
generally faster than allocating on the heap.

The builtin `new` function always allocates on the heap.

Variables declared in functions are typically allocated on the stack
unless access to them escapes from the function
by returning a pointer to it or setting a variable
declared outside the function to a pointer to it.

### Output

Writing to stdout and stderr is supported by the "fmt" package.
The `Println` method writes expression values,
followed by a newline character, to stdout.

```go
import "fmt"
fmt.Println(expr1, expr2)
```

The `Printf` function also writes to stdout and uses a format string
similar to the C `printf` function.

For more detail see the "`fmt` Standard Library" section
in the "Builtins" section.

### If

In Go `if` statements,
parentheses are not needed around the condition being tested
and braces around the body are required.
If parentheses are included, the `gofmt` tool will remove them.
For example:

```go
if x > 7 {
  ...
} else {
  ...
}
```

Almost any single statement can precede the condition,
separated from it by a semicolon.
However, typically an assignment statement is used.
The scope of the assigned variable is the `if` block,
including the `else` block if present. For example:

```go
if y := x * 2; y < 10 {
  ...
}
```

### Switch

Go's `switch` statement is similar to that in other languages,
but it can switch on expressions of any type.
Braces around the body are required.

Case values can be literal values or expressions.
The `case` keyword can be followed by any number of
comma-separated expressions. Matching any of them
causes the statements for that case to be executed.
Case blocks do not fall through to the next by default so
unlike in many other languages, `break` statements are not used.
If it is desirable to fall through, use the
`fallthrough` keyword at the end of a `case` block.

A basic `switch` statement looks like the following:

```go
switch name {
  case "Mark":
    // handle Mark
  case "Tami":
    // handle Tami
  case "Amanda", "Jeremy":
    // handle Amanda or Jeremy
  default:
    // handle all other names
}
```

A `switch` statement can include an initialization statement
just like an `if` statement. For example,

```go
switch name := buildName(person); name {
  ...
}
```

The previous example could also begin with

```go
switch buildName(person) {
```

but then the name would not be available for use inside the `switch`.

A `switch` statement with no expression executes the
first `case` block whose expression evaluates to true.
This is referred to as a "tagless switch".
For example,

```go
switch {
  case name == "Mark":
    // handle Mark
  case age < 20:
    // handle youngsters
  default:
    // handle all other cases
}
```

To switch on the type of an expression
append `.(type)` to the expression.
For example:

```go
switch theType := expression.(type) {
  case int, float:
    // handle int or float
  case string:
    // handle string
  default:
    // handle all other types
}
```

The variable `theType` will hold the actual type.
`theType :=` can be omitted if not needed.
If the value of `expression` is an interface type,
`theType` will be set to the actual type that implements the interface.

### Loops

The `for` statement is the only looping statement in Go.
The syntax is `for init; cond; post { ... }`.
No parentheses are allowed around the the init, cond, and post portions.
The three parts are separated by semicolons.
The init and post parts, if present, must be single statements,
but multiple variables can be assigned in a single statement.
Braces around the body are required.

The `break` and `continue` keywords can be used inside the body.
`break` without a label exits the inner-most loop.
`continue` skips the remainder of the body and continues
at the top of the loop, testing the condition again.

For example:

```go
for i := 0; i < 10; i++ {
  ...
}
```

The init and post parts are optional.
When only the condition is present, the semicolons can be omitted.
A `while` loop in other languages looks like the following in Go:

```go
for i < 10 {
  ...
}
```

For an endless loop, omit the condition as follows:

```go
for {
  ...
}
```

The `range` keyword is often used in `for` loops
to iterate over string characters,
elements of arrays and slices,
and map key/value pairs.
Examples of these appear later.

### Strings

Go strings are immutable sequences of bytes representing UTF-8 characters.
Literal values are delimited with double quotes
or back-ticks (called "raw string literals").

Raw string literals can include newline characters
and characters escaped with backslashes
(such as \n for newline and \t for tab) are not processed.
This makes them ideal for writing regular expressions
and HTML templates which sometimes contain backslashes.

An example of declaring and initializing a string
inside a function is `name := "Mark"`.

To get the length of a string in bytes, use the `len` function.
For example, `len(name)` returns `4`.

To get the length of a string in UTF-8 characters,
use the `unicode/utf8` package.
For example, `utf8.RuneCountInString(name)`.

To retrieve a byte from a string, `char := name[index]`.
Attempting to retrieve a byte at an index beyond the end
triggers a panic, which is a runtime error
that typically causes the application to terminate
(see the "Error Handling" section for more detail).

To retrieve a UTF-8 character as a rune,
use the `unicode/utf8` package.
For example, `r, size := utf8.DecodeRuneInString(name[i:])`.
`i` is the byte index of the start of the character.
`r` is set to the rune.
`size` is the number of bytes in the rune
which can be used to compute `i` for the next character.

To iterate over the UTF-8 characters in a string,
use a `for` loop with the `range` keyword.
For example, `for index, char := range name { ... }`.
Replace `index` with `_` if it is not needed.

To create a new string that is a substring of an existing string,
specify the starting (inclusive) and ending (exclusive) indexes
in square brackets separated by a colon. For example,
`name[m:n]` gets the characters from index `m` to just before index `n`,
`name[m:]` gets characters from `m` to the end,
`name[:n]` gets characters from the beginning to just before `n`,
and `name[:]` gets all the characters.

For efficiency, substrings share memory
with the original string rather than copying bytes.
This is safe because strings are immutable.

While strings are immutable,
variables that hold them can be assigned a different string.
For example, the following is valid: `name = name[:3]`.

To create a new string by concatenating a string to another,
use the `+` and `+=` operators.

The `string` type has no methods.
The standard library package `strings` provides
many functions for operating on strings.
Many of these are described in the "Builtins" section.
For example, to split a string on whitespace characters
and print each word on a separate line:

```go
s := "This is a test."
words := strings.Fields(s)
for _, word := range words {
  fmt.Println(word) // outputs "This", "is", "a", and "test."
}
```

### Types

The `type` keyword defines a new type.
It does not define an alias for an existing type.

For example `type score int` defines the type `score`,
but it cannot be used interchangeably with the type `int`.

```go
type score int
var s score = 1
var i int = 2
sum := s + i // invalid operation - mismatched types
```

The `type` keyword is most often used to define a type for a
struct, slice type, map type, interface, or function signature.
This avoids repeating long type definitions.

Type names must start uppercase to make them accessible (exported)
outside the current package.

The operations supported by a named type
include all those supported by the underlying type.
This means that the `score` type above can be used
in all the same ways that an `int` can be used,
but not in place of an `int`.

Type names can be used as functions that convert a value
that has the same underlying type to that type.
For example, the invalid operation above can be corrected with:

```go
sum : = s + score(i) // works!
```

This can also be used to convert between numeric types,
which is useful since math operations such as addition
require matching types. For example:

```go
a := 1 // int
b := 2.3 // float64
fmt.Println(float64(a) + b) // 3.3
fmt.Println(a + int(b)) // truncates b resulting in 1 + 2 = 3
```

Methods can be added to named types.
These are described later.

### Structs

A struct is a collection of fields defined with the `struct` keyword.
Field values can have any type,
including other structs nested to any depth.
A struct cannot inherit from another struct,
but can utilize composition of structs.

Struct fields whose names start uppercase (exported) are visible in
other packages that import the package that defines the struct.
Otherwise fields are only visible in the package that defines the struct.

It is often desirable to define a type alias for a struct to
make it easy to refer to in variable and parameter declarations.
Otherwise the struct is anonymous and
can only be referred to where it is defined.

Here is an example of using an anonymous `struct`
that is not assigned to a type name:

```go
var me = struct{
  name string
  age int8
}{
  "Mark",
  57,
}
```

Assigning a type name makes the code easier to understand
and makes `struct` definitions reusable.
For example:

```go
type person struct {
  name string
  age int8
}
```

A struct literal creates an instance of a struct.
Field values can be specified in any order by also providing corresponding keys.
For example,

```go
var p1 = person{name: "Mark", age: 57}
```

Struct fields can also be initialized by providing only values
in the order in which they are listed in the struct definition.
But this option can only be used within
the same package that defines the struct type.
It is best to only use this approach for structs with a small number of fields
because changes to the field order will break these initializations.
For example,

```go
var p2 = person{"Mark", 57}
```

Uninitialized fields are initialized to their zero value.

The dot operator is used to get and set fields within a `struct`.
For example:

```go
fmt.Println(p1.name) // Mark
p1.age++
fmt.Println(p1.age) // 58
```

The `fmt.Printf` function takes a format string that can contain "verbs".
The "%v" verb is useful during debugging for printing values of any type,
including structs. Only exported fields are output.
TODO: YOUR EXAMPLE CONTRADICTS THIS!
Formatting strings are documented at <https://golang.org/pkg/fmt/>.
For example:

```go
fmt.Printf("%v\n", p2) // just field values: {Mark 58}
fmt.Printf("%+v\n", p2) // including field names: {name:Mark age:58}
fmt.Printf("%#v\n", p2) // Go-syntax representation: main.person{name:"Mark", age:58}
```

There is no support for destructuring like in JavaScript
to extract field values from a `struct`.

Struct fields can be accessed from a struct pointer
without dereferencing the pointer. For example,

```go
personPtr := &p1
fmt.Println((*personPtr).name) // Mark
fmt.Println(personPtr.name) // same, Mark
```

If a `struct` field name is omitted, it is assumed to be the same as the type.
For example:

```go
package main

import (
  "fmt"
  "time"
)

func main() {
  type Age int

  type myType struct {
    Name       string // named field
    Age               // gets field name from the type above
    time.Month        // gets field name from a library type
  }

  myStruct := myType{Name: "Mark", Age: 7, Month: time.April}
  fmt.Printf("%#v\n", myStruct) // main.myType{Name:"Mark", Age:7, Month:4}
}
```

To embed a `struct` type within another,
precede the type name with a field name or
include just the type name to get a field with the same name.
The second option is referred to as an "anonymous field".
For example:

```go
type Address struct {
  Street string
  City   string
  State  string
  Zip    string
}

type Person struct {
  Name        string
  Address     // home
  WorkAddress Address
}

me := Person{
  Name: "Mark Volkmann",
  Address: address{
    Street: "123 Some Street",
    City:   "St. Charles",
    State:  "MO",
    Zip:    "63304", // comma is required here
  },
  WorkAddress: Address{
    Street: "123 Woodcrest Executive Drive",
    City:   "Creve Coeur",
    State:  "MO",
    Zip:    "63141", // another required comma
  },
}
```

When a nested struct is not given an explicit name,
its fields can be accessed using the struct name or omitting it.
For example,

```go
fmt.Println("home city is", me.address.city) // St. Charles
fmt.Println("home city is", me.city) // same
fmt.Println("work city is", me.workAddress.city) // Creve Coeur; cannot omit workAddress.
```

If the type of an anonymous field has methods,
those become methods of the outer struct type as well.
For example, if the `Address` type above had a `Print` method
that printed the address in the format of a mailing label,
that method could also be called on a `Person` object.

A struct cannot contain a field whose type is the same struct type,
but it can contain a field that is a pointer to the same struct type.
For example,

```go
type Node struct {
  value int
  next *Node
}
tail := Node{value: 20}
head := Node{value: 10, next: &tail}
fmt.Println(head.value) // 10
fmt.Println(head.next.value) // 20
```

Structs can be compared using the `==` and `!=` operators
if all the field values are comparable.
Such structs can be used a keys in maps.

When a struct is passed to a function, a copy is made and
changes the function makes to its fields are not visible to the caller.
For these reasons it is common to pass pointers to structs instead of structs.

### Functions

Go functions are defined with `func` keyword.
The syntax for named functions is:

```go
func functionName(param1 type1, param2 type2, ...) (returnTypes) {
  ...
}
```

Named functions must be declared at the package level,
not nested inside other functions.

Anonymous functions have the same syntax, but omit the name.
For example, `func(v int) int { return v * 2 }`.

Unlike named functions, anonymous functions
can be defined inside other functions.

Both named and anonymous functions are first-class values.
This means they can be stored in variables,
passed as arguments to other functions,
and returned from other functions.

When a function is assigned to variable,
it can be called using that variable.
For example, `fn := someFunction; fn()`.

If a variable with a function type is not assigned a value,
it defaults to nil.
If a call is made on a nil variable, a panic is triggered.

Function arguments are passed by value
so copies are made of arrays, slices, and structs.
To avoid creating copies of these and enable the function
to make changes that are visible to the caller,
pass and accept pointers.

Function parameters are local variables inside the function.

Functions cannot be overload based on their parameter types
in order to create different implementations.

When consecutive parameters have the same type,
the type can be omitted from all but the last.
For example, `func foo(p1 int, p2 int, p3 string, p4 string)`
is is equivalent to `func foo(p1, p2 int, p3, p4 string)`.

It is not possible to specify default values for function parameters
and they cannot be made optional.
However, functions can accept a variable number of arguments.
These are referred to as variadic functions.

To define a variadic function, precede the type
of the last named parameter with an ellipsis.
When the function is called, behind the scenes
an array is created to hold all the arguments
after the initial ones
and a slice over that array is passed
which becomes the value of the last parameter.
For example:

```go
package main

import (
  "fmt"
  "strings"
)

// The type "interface{}" means
// that any type can be used.
func log(args ...interface{}) {
  fmt.Println(args...)
}

// This accepts a person name followed by
// any number of color names.
func report(name string, colors ...string) {
  text := strings.Join(colors, " and ") + "."
  fmt.Println(name, "likes the colors", text)
}

func main() {
  log("red", 7, true) // red 7 true
  report("Mark", "yellow", "orange") // Mark likes yellow and orange
}
```

If the values to be passed to a variadic function
are already in a variable that holds a slice,
follow the variable name with an ellipsis.
If they are in an array, first create a slice over it.
For example, `values[:]...`.

Functions can return zero or more values.
When there are no return values, the list of return types is omitted.
When there is one return values, its type is provided,
but the parentheses around it are optional and typically omitted.
When there are multiple return value, the types
must be surrounded by parentheses and separated by commas.

When calling a function, all return values
must be captured in a variable.
The "blank identifier" (\_) can be
used to capture unneeded return values.

For example,

```go
// This returns an int and a float64.
func GetStats(numbers []int) (int, float64) {
  sum := 0
  for _, number := range numbers {
    sum += number
  }
  average := float64(sum) / float64(len(numbers))
  return sum, average
}

func main() {
  sum, avg := GetStats(someNumbers)
  // Do something with sum and avg.
}
```

A common use of returning multiple values from a function is to
return a result and a value that either describes an error or
is a boolean that indicates whether the function was successful.
Using a boolean is preferred when
there is only way the function can fail.

For example, the `ReadFile` function
in the `io/ioutil` standard library package
takes a file path and returns
a byte array and an error description.

```go
bytes, err := ioutil.ReadFile("haiku.txt")
if err != nil {
  log.Fatal(err)
}
// Do something with bytes.
```

For details on error handling,
see the "Error Handling" section later.

A function call can appear as the only argument
in another function call. The return values
become the actual arguments to the outer call.

Function return types can have associated names
that become local variables inside the function.
This enables "naked" (a.k.a. "bare") returns where
a `return` with no specified values will return
the values of variables with the given names.
For example:

```go
func mult(n int) (times2, times3 int) {
  times2 = n * 2
  times3 = n * 3
  //return times2 times3 // don't need to specify return values
  return
}

// In some other function
n2, n3 := mult(3) // n2 is 6 and n3 is 9
```

Unless the function is very short, using this feature is frowned upon
because the code is less readable than explicitly returning values.

Functions have a type that is defined by their signature.
This is based on the order and type of the parameters
and the order of the return types.
The function name, parameter names,
and any return value names
are not part of the signature.

Function types can be important when passing functions
or returning functions to/from another.

It is sometimes useful to define a type for a function signature
to avoid repeating a long definition.
For example,

```go
package main

import "fmt"

type CalculateFn func(float64, float64) float64

func product(a float64, b float64) float64 {
  return a * b
}

func process(m float64, n float64, fn CalculateFn) float64 {
  return fn(m, n)
}

func main() {
  fmt.Println("result =", process(2, 3, product)) // 6
}
```

Like in most programming languages, Go functions can be recursive.
But most languages use a fixed-size stack
that limits the depth of recursive calls.
Generally programs crash when they exceed this.

Go uses a variable-size stack that grows as needed.
This allows Go functions to support a higher recursive depth
than most languages without crashing.

The maximum stack size for 64-bit systems is 1GB by default.
This can be modified by calling the `SetMaxStack` function
in the `runtime/debug` standard library package.

Functions act as closures over all in-scope variables.
This allows nested, anonymous functions
to retain access to and modify variables
that are in the scope of their definition.

Typically the lifetime of a variable declared inside
a function is the duration of a call to that function.
However, the fact that functions are closures
creates an exception. For example,

```go
func closureDemo() func() {
  // The lifetime of this variable is the lifetime
  // of the function returned by this function.
  secret := "Don't tell!"
  return func () {
    fmt.Println(secret); // captures local variable secret
  }
}

func main() {
  fn := closureDemo();
  fn(); // Don't tell!
}
```

### Methods

Methods are functions that are invoked on a "receiver" value.
They can be associated with any named type, but not built-in types.
The receiver is an instance of this type.

Methods are particularly useful for types that implement interfaces.
Otherwise we can just write functions
that take a value of the type as an argument.

Just like with functions, methods whose name starts lowercase
can only be called by code in package where the method is defined.
To make them available in other packages,
their names must start uppercase.

It is not possible to create overloaded methods on a type
to create different implementations for different parameter types.
Methods are distinguished only by the receiver type and their name.

The syntax for defining a method is
`func (receiver-info) name(parameter-list) (return-types) { body }`.
`receiver-info` is a name followed by the instance type for the method.
Note that there are three pairs of parentheses.
If the method has only one return value,
the last pair of parentheses can be omitted.

In most programming languages that support methods,
the method body refers to the receiver
using a keyword like `this` or `self`.
In Go the method signature specifies the name
by which the receiver will be referenced.
In the example that follows, the name is `p`.

To call a method, specify the receiver, followed by a dot,
the method name, and the argument list.
For example,

```go
// Add a method to the type "pointer to a Person struct".
// Note how the receiver and its type appear
// in parentheses before the method name.
func (p *Person) Birthday() {
  p.age++
}

p := Person{name: "Mark", age: 57}
(&p).Birthday() // The method can be invoked on a pointer to a Person.
p.Birthday() // It can also be invoked on a Person.
fmt.Printf("%#v\n", p) // main.Person{name:"Mark", age:59}
```

In the previous example the receiver is a pointer to a struct.
This allows the method to modify the struct
and avoids making a copy of the struct when it is invoked.
When the receiver is a type value and not a pointer to a type value
the method receives a copy and cannot modify the original.

When a function has a parameter with a pointer type,
it must be passed a pointer.
However, when a method has a pointer receiver,
it can be invoked on a pointer to a value or a value.
When invoked on a value, it will automatically
pass a pointer to the value to the method.

When a type has multiple methods, the `golint` tool
wants all the receivers to have the same name.
However, it does not complain if
some receivers are a pointer and others are values.
TODO: IS THIS OKAY?

If an attempt is made to add a method to a built-in type
an error with the message "cannot define new methods on non-local type"
will be triggered. However,
methods can be added to built-in types if a type alias is created.

Here is an example of adding a method to a type alias for the `int` type.

```go
type Number int

func (receiver Number) Double() Number {
  return receiver * 2
}

n := Number(3) // or could use var n Number = 3
fmt.Println(n.Double()) // 6
```

It may seem that struct methods should be defined inside the struct.
However, the ability to define methods outside the type definition
is required in order to add methods to non-struct types.
So Go chooses to only support this same approach for all types.

### Arrays

Arrays hold an ordered collection of values,
a.k.a. elements, that all have the same type.

Values can be other arrays to create multidimensional arrays.

Arrays have a fixed length and the length is part of their type.

The syntax for declaring an array is `[length]type`.
The length must be compile-time expression.
Placing the square brackets before the type was inspired by Algol 68.
For example, `var rgb [3]int`.

An array can be created with an "array literal".
This uses curly braces to specify initial elements.
For example, `rgb := [5]int{100, 50, 234}`.
This creates an array with a length of five
where only the first three elements are explicitly initialized.
The remaining elements are initialized to their zero value.

To create an array whose length is
the same as the number of supplied initial values,
place an ellipsis inside the square brackets
instead of a length.
For example, `rgb := [...]int{100, 50, 234}`.
This creates an array with a length of three.

An array can be created by specifying values at specific indexes.
Values at unspecified indexes are given the zero value for the array element type.
For example, `names := [...]string{3: "Mark", 1: "Tami"}`
creates the array `["", "Tami", "", "Mark"]`.
The length is one more than the highest specified index.

If anything other than a single integer or ellipsis appears inside the
square brackets, a "slice" is created.
Slices are discussed in the next section.

Square brackets are also used to get and set
the value at a zero-based index.
To get the second element, `rgb[1]`.
To set the second element, `rgb[1] = 75`.
Attempting to get or set an element at an index beyond the end
triggers a panic.

To get the length of an array, `len(myArr)`.
For arrays, the capacity is the same as the length,
so `cap(myArr)` returns the same value.
We will see that this is not the case for slices.

One way to iterate over the elements of an array
is to use a C-style `for` loop.
For example,

```go
for i := 0; i < len(myArr); i++ {
  value := myArr[i]
  // Do something with value.
}
```

The `range` keyword can be also used to iterate over the elements,
and this is typically preferred. For example,

```go
for index, value := range myArr {
  // Do something with value, and possibly index.
}
```

If `index` is not needed, the "blank identifier" \_ can be used in its place.

```go
for _, value := range myArr {
  // Do something with value.
}
```

When an array is passed as an argument to a function,
a copy of the array is created.
Changes the function makes to the array elements
are not visible to the caller.
To avoid copying and allow the caller to see changes,
write functions to accept a pointer to an array rather than an array.

### Slices

Slices are a distinct type from arrays.
They are a view into an array with a variable length.

Functions that take a slice parameter cannot be passed an array.
Many functions prefer slices over arrays.
Unless having a fixed length is important,
use a slice instead of an array.

A slice is described by three components, a pointer to an array element,
a current length, and a current capacity.
The pointer can point to any element in the array.
The length is number of array elements currently seen by the slice.
The capacity is the number of array elements
from the pointer to the end of the array.
For example,

```go
arr := [...]string{"red", "orange", "yellow", "green", "blue", "purple"}
sl := arr[2:5]
```

The slice `sl` currently points to the element "yellow" in `arr`
because that is the element at index 2.
It has a length of 3 (5 - 2) and
can access the elements "yellow", "green", and "blue".
It has a capacity of 4 because there is one more element in the array,
"purple", that it cannot currently see.

A slice type is declared with nothing inside square brackets.
For example, `[]int` is a slice of int values
that is not yet associated with an array.

There are three ways to create a slice, using a "slice literal",
using the builtin `make` function, or basing on an existing array.

The most common way to create a slice is with a slice literal
which creates a slice and its underlying array.
These look like an array literals, but without a specified length.
`mySlice := []int{}` creates a slice with an empty underlying array
where the length and capacity are 0.
`mySlice := []int{2, 4, 6}` creates a slice where the
length and capacity are 3, and contains the provided initial values.

It is also possible, but not common, to specify values at specific indexes.
`mySlice := []int{2: 6, 1: 4, 0: 2}` is the same as the previous example.
`mySlice := []int{3: 7, 0: 2}` creates a slice where the length and capacity
are 4 which is one more than the highest specified index.

The `make` function provides another way
to create a slice and underlying array.
Rather than specifying initial values,
the length and capacity are specified.
This can avoid reallocating space if elements are appended later,
which is somewhat inefficient.
If it is anticipated that many elements will be appended later,
try to estimate the largest size needed
and use `make` to create the slice.
For example, `mySlice := make([]int, 5)`
creates an underlying array of size 5
and a slice with length 5 and capacity of 5.
`mySlice := make([]int, 0, 5)`
creates an underlying array of size 5 and
a slice with length 0 and capacity of 5.

The final way and least commonly used way to
create a slice is to base it on an existing array,
specifying the start (inclusive) and end (exclusive) indexes.
For example, `mySlice := myArr[start:end]`
If `start` is omitted, it defaults to 0.
If `end` is omitted, it defaults to the array length.
So `myArr[:]` creates a slice over the entire array.

Modifying elements of a slice modifies the underlying array.
Multiple slices on the same array see the same data.

The builtin `append` function takes a slice
and returns a new slice containing additional elements.
For example, `mySlice = append(mySlice, 8, 10)`
appends the values 8 and 10.
If the underlying array is too small to accommodate the new elements,
a larger array is automatically allocated
(doubling the current capacity after the length exceeds 4)
and the returned slice will refer to it.
It is not possible to append elements to arrays
which is one reason why slices are often preferred.

`len(mySlice)` returns the number of elements in the slice
which is its current length.
`cap(mySlice)` returns the number of elements in the underlying array
which is its current capacity.

Just like with arrays, square brackets are used to
get and set the value of a slice at a zero-based index.
If the index is greater than or equal to the slice capacity,
a panic will be triggered with the message
"runtime error: index out of range".

The same approaches for iterating over the elements of an array
can be used to iterate over the elements of a slice.

To change the view of a slice into its underlying array,
recreate it with different bounds
For example, `mySlice = mySlice[newStart:newEnd]`.
This creates a slice that begins at `newStart`
and ends just before `newEnd`.

Slice elements can be other slices to create multidimensional slices.
For example:

```go
ticTacToe := [][]string{
  []string{" ", " ", " "},
  []string{" ", " ", " "},
  []string{" ", " ", " "}}
  // If the last } is placed on a new line then a
  // comma is required at the end of the previous line.
}
ticTacToe[1][2] = "X"
```

To use all the elements in a slice as separate arguments to a function
follow the variable name holding the slice with an ellipsis.

```go
// This is a "variadic function, discussed more later.
// It takes any number of int arguments.
func sum(numbers ...int) int {
  result := 0
  for _, number := range numbers {
    result += number
  }
  return result
}

func main() {
  fmt.Println(sum(1, 2, 3)) // 6
  values := []int{1, 2, 3}
  fmt.Println(sum(values...)) // 6
}
```

Slices can contain values of any type.
Here is an example that uses a slice of structs:

```go
type Person struct {
  name string
  age  int8
}

func main() {
  // Note how we do not need to precede each struct with "Person".
  people := []Person{{"Mark", 57}, {"Jeremy", 31}}
  fmt.Printf("%+v\n", people) // [{name:Mark age:57} {name:Jeremy age:31}]
}
```

A slice can be used to implement a stack.

```go
package main

import "fmt"

// IntStack is a stack of int values.
type IntStack []int

func (s *IntStack) Push(value int) {
  *s = append(*s, value)
}

func (s *IntStack) Pop() int {
  stack := *s
  l := len(stack)
  top := stack[l-1]
  *s = stack[:l-1]
  return top
}

func main() {
  myStack := IntStack{1, 3, 5}
  fmt.Println(myStack.Pop())             // 5, now contains [1, 3]
  fmt.Println(myStack.Pop())             // 3, now contains [1]
  myStack.Push(7)                        // now contains [1, 7]
  myStack.Push(9)                        // now contains [1, 7, 9]
  fmt.Printf("myStack = %+v\n", myStack) // [1 7 9]
}
```

### Maps

A map is a collection of key/value pairs
that provides efficient lookup of values by their key.
The keys and values can have any type, but
in a given map all the keys have the same type
and all the values have the same type.

A map type looks like `map[keyType]valueType`.
For example, `var myMap map[string]int`.

A type alias can be created for this type which is
useful when it will be referred to in many places.
For example, `type PlayerScoreMap map[string]int`.

One way to create a map is with a "map literal"
which allows specifying initial key/value pairs.
For example,
`scoreMap := map[string]int{"Mark": 90, "Tami": 92}`.
or using the type alias above,
`scoreMap := PlayerScoreMap{"Mark": 90, "Tami": 92}`.

Another way to create a map is to use the builtin `make` function.
For example, `scoreMap := make(map[string]int)`
or `scoreMap := make(playerScoreMap)`.
TODO: Is scoreMap really a pointer?

To add a key/value pair, `myMap[key] = value`.

To get the value for a given key, `value := myMap[key]`.
If the key is not present,
the zero value for the value type is returned.

For example:

```go
type PlayerScoreMap map[string]int

scoreMap := PlayerScoreMap{"Mark": 90, "Tami": 92}
scoreMap["Amanda"] = 83
scoreMap["Jeremy"] = 95

myScore := scoreMap["Mark"]
fmt.Println("my score =", myScore) // 90
fmt.Printf("scoreMap = %+v\n", scoreMap) // map[Tami:92 Amanda:83 Jeremy:95 Mark:90]
```

To get the value for a given key and verify that the key was present,
as opposed to getting the zero value because it wasn't,
capture the second return value which is a `bool`. For example:

```go
value, found := myMap[key]
if found {
  // Do something with value.
}
```

or

```go
if value, found := myMap[key]; found {
  // Do something with value.
}
```

In maps where the values are numbers,
the `++`, `--`, and arithmetic assignment operators
can be used to modify values.
For example, `scoreMap["Mark"]++` and `scoreMap["Tami"] *= 2`.

To delete a key/value pair, `delete(myMap, key)`.

To iterate over the key/value pairs in a map,
`for key, value := range myMap { ... }`.
The order of iteration is not defined.

Maps support concurrent reads, but not concurrent writes
or a concurrent read and write.
If a map might be accessed concurrently from multiple goroutines,
protect against this by using channels or mutexes.
These will be described in a later article in the series on concurrency.

### Sets

Go does not have a builtin data structure for representing sets
which are unordered collections of unique values.
However, a `Map` that uses `bool` values or
empty structs for values can be used for this purpose.
Unlike `bool` values, empty structs do not take up memory.
They are written as `struct{}`.

The following simple package defines a set data structure for strings.

```go
package set

type empty struct{} // memory-efficient value for sets

// Strings is a set of strings.
type Strings map[string]empty

var present = empty{}

// Add adds a given value to the set.
func (set Strings) Add(value string) {
  set[value] = present
}

// Contains determines if a given value is in the set.
func (set Strings) Contains(value string) bool {
  _, ok := set[value]
  return ok
}

// Remove removes a given value from the set.
func (set Strings) Remove(value string) {
  delete(set, value)
}
```

Here's an example of using this "set" package.

```go
package main

import (
  "fmt"

  "github.com/mvolkmann/set"
)

func main() {
  colorSet := set.Strings{}
  colorSet.Add("red")
  colorSet.Add("yellow")
  colorSet.Add("blue")
  colorSet.Remove("yellow")

  colors := []string{"red", "yellow", "blue"}
  for _, color := range colors {
    if colorSet.Contains(color) {
      fmt.Println("have", color) // prints "red" and "blue"
    }
  }

  fmt.Printf("%+v\n", colorSet) // map[red:{} yellow:{}]
  fmt.Println(len(colorSet)) // 2
}
```

A recommended community library that supports many data structures
is "gods" at <https://github.com/emirpasic/gods>.
It supports several kinds of lists, sets, stacks, maps, and trees.
These collections can hold values of any type,
but using the values typically requires type assertions
(described later).

Here is an example of using the `gods.HashSet` type
to represent a set of `int` values.

```go
package main

import (
  "fmt"

  "github.com/emirpasic/gods/sets/hashset"
)

func main() {
  set := hashset.New()   // empty
  set.Add(1)             // 1
  set.Add(2, 2, 3, 4, 5) // 3, 1, 2, 4, 5 (random order, duplicates ignored)
  set.Remove(4)          // 5, 3, 2, 1
  set.Remove(2, 3)       // 1, 5

  fmt.Println("contains 1?", set.Contains(1))          // true
  fmt.Println("contains 1 and 5?", set.Contains(1, 5)) // true
  fmt.Println("contains 1 and 6?", set.Contains(1, 6)) // false

  values := set.Values()
  fmt.Println("values =", values)    // []int{5,1} (random order)
  fmt.Println("empty?", set.Empty()) // false
  fmt.Println("size =", set.Size())  // 2

  // Must use type assertions to operate on values.
  sum := 0
  for _, v := range values {
    sum += v.(int)
  }
  fmt.Println("sum =", sum)

  set.Clear()                        // empty
  fmt.Println("empty?", set.Empty()) // true
  fmt.Println("size =", set.Size())  // 0
}
```

### Deferred Functions

Inside a function, function calls preceded by `defer`
will have their arguments evaluated immediately,
but the function will not execute until the containing function exits.

All deferred calls are placed on a stack and
executed in the reverse order from which they are evaluated.

A deferred function can change the values returned
by a function by simply returning other values.

Deferred functions are typically used for resource cleanup
that must occur regardless of the code path taken in the function.
Examples include closing files, closing network connections,
unlocking mutexes, and logging function results/exits.

This is an alternative to the `try`/`finally` syntax
found in other languages.

Here is an example of using `defer` to
log how long it takes for a function to execute:

```go
package main

import (
  "fmt"
  "log"
  "time"
)

func startTimer(name string) func() {
  t := time.Now()
  return func() {
    delta := time.Now().Sub(t)
    log.Println(name, "took", delta)
  }
}

func doWork() int {
  sum := 0
  for i := 0; i < 100000000; i++ {
    sum += i
  }
  return sum
}

func main() {
  // This calls the function returned by startTimer
  // when the main function exits.
  defer startTimer("doWork")()
  fmt.Println(doWork())
}
```

### Interfaces

An interface defines a set of methods.
Any named type can implement an interface, even named primitive types.
Types do not state the interfaces they implement,
they only need to implement all the methods.

When a value is assigned to a variable or parameter with an interface type,
if its actual type does not implement all the interface methods,
an error is reported that identifies one of the missing methods.

Calling a method on a variable with an interface type
calls the method on the underlying type.
If a value has not be assigned to the variable,
calling a method on it results in an error.

An interface with no methods, referred to as the "empty interface",
matches every type. This can be given a name
such as "any" using `type any interface{}`.

The following code defines an interface and two types that implement it:

```go
package main
import "fmt"
import "math"

type Shape interface {
  area() float64
  name() string
}

type Rectangle struct {
  width, height float64
}
func (r Rectangle) area() float64 {
  return r.width * r.height
}
func (r Rectangle) name() string {
  return "rectangle"
}

type Circle struct {
  radius float64
}
func (c Circle) area() float64 {
  return math.Pi * c.radius * c.radius
}
func (c Circle) name() string {
  return "circle"
}
// Adding a method to the Circle type that is not in the Shape interface.
func (c Circle) diameter() float64 {
  return c.radius * 2
}

func printArea(g Shape) {
  fmt.Println("area =", g.Area())
}

func main() {
  r := Rectangle{width: 3, height: 4}
  c := Circle{radius: 5}
  var g Shape // Note that g is an interface type.
  //printArea(g) // panic: runtime error: invalid memory address or nil pointer dereference
  g = r
  printArea(g)
  g = c
  printArea(g)

  // Since the shape interface doesn't define the diameter method,
  // a type assertion is required to call it.
  fmt.Println("diameter =", g.(Circle).diameter())
}
```

A "type assertion" verifies that the value of
an interface variable refers to a specific type.
If it does, the same value is returned, but with the asserted type.
If it does not, a panic is triggered.

For example, consider `myShape := g.(Circle)`.
If `g` does refer to a `Circle` then the type of `myShape` is `Circle`.

Keep in mind that when running a program using `go run`,
if there are compile errors, the panic will not be
triggered since the code won't begin running.

A "type test" determines whether an interface variable
refers to a specific type.
It differs from a type assertion in that
an extra return value is captured.
For example, `myShape, ok := g.(Circle)`.
The variable `ok` will be set to `true` or `false`
to indicate whether `g` refers to a `Circle` object.
If it does not, no panic will be triggered.

Here is an example of a custom collection that
can hold values of any type. It is a basic linked list.
Note how type assertions are required to
use values that are obtained from the collection.

```go
package main

import "fmt"

// LinkedList implements a linked list with values of any type.
type LinkedList struct {
  head *node
}

type any interface{}

type node struct {
  value any
  next  *node
}

// clear removes all nodes.
func (listPtr *LinkedList) clear() {
  listPtr.head = nil
}

// isEmpty determines if the LinkedList is empty.
func (listPtr *LinkedList) isEmpty() bool {
  return listPtr.head == nil
}

// pop removes the first node and returns its value.
func (listPtr *LinkedList) pop() any {
  if listPtr.isEmpty() {
    return nil
  }
  node := listPtr.head
  listPtr.head = node.next
  return node.value
}

// push adds a node to the front.
func (listPtr *LinkedList) push(value any) {
  node := node{value, listPtr.head}
  listPtr.head = &node
}

// len returns the length of the LinkedList.
func (listPtr *LinkedList) len() int {
  len := 0
  node := listPtr.head
  for node != nil {
    len++
    node = node.next
  }
  return len
}

func main() {
  list := LinkedList{}
  list.push(1)
  list.push(3)
  list.clear()
  list.push(5)
  list.push(7)

  sum := 0
  for !list.isEmpty() {
    value := list.pop()
    fmt.Println("value =", value) // 5 and 7
    sum += value.(int)
  }
  fmt.Println("sum =", sum) // 12
}
```

The standard library packages define many interfaces.
For example, the `fmt` package defines the `Stringer` interface.
It contains one method named `String`.
TODO: Why does the name start uppercase? Required to expose?
Many other packages check whether values implement this interface
in order to convert values to strings.

Any type can choose to implement this interface
by defining the `String` method.
For example:

```go
type Person struct {
  Name string
  Age int8
}

// Note that the receiver is a Person struct, not a pointer to one.
// This is typical for methods that do not modify the receiver.
func (p Person) String() string {
  return fmt.Sprintf("%v is %v years old.", p.Name, p.Age)
}

me := Person{"Mark", 57}
fmt.Println(me) // Mark is 57 years old.
```

Interfaces can be nested to add the methods of one interface to another.
For example:

```go
package main

type Shape2d interface {
  area() float64
}

type Shape3d interface {
  Shape2d // Shape3d objects also support Shape2d methods
  volume() float64
}

type Box struct {
  d float64
  h float64
  w float64
}

// Implements Shape2d interface.
// Accepting a pointer so a copy is not made.
func (b *Box) area() float64 {
  return b.w * b.h
}

// Implements Shape3d interface.
func (b *Box) volume() float64 {
  return b.area() * b.d
}

func main() {
  myBox := Box{d: 2, h: 3, w: 4}
  fmt.Println("area =", myBox.area()) // 12
  fmt.Println("volume =", myBox.volume()) // 24
}
```

### Error Handling

Go does not support exceptions,
and thus no try/catch/finally keywords.
Instead functions that may encounter errors have
an additional return value of type `error`
that callers should check.
When there is no error, this return value is `nil`.

Go prefers this error handling approach
over using exceptions.
One reason is that it requires
handling errors as they occur
rather than grouping a happy path of statements
in a try block and handling errors
with catch blocks at the end.
Another reason is that exception handling typically
allows a program to terminate with a stack trace
when an unhandled error occurs.

The type `error` is a builtin interface
that defines a single method `Error`
which returns a string description of the error.

The standard library creates and exports
many instances of this interface.
It is also possible to define
custom implementations of the `error` interface
that hold additional data describing the error.

The `errors` package defines a `New` method
that can be used to create error instances from a string.
For example:

```go
package main
import (
  "errors"
  "fmt"
)

func divide(a, b float32) (float32, error) {
  if b == 0 {
    return 0, errors.New("divide by zero")
  }
  return a / b, nil // no error
}

func main() {
  q, err := divide(7, 0)
  if err != nil {
    log.Fatal(err)
  }
  fmt.Print(q)
}
```

When an error is returned, typically the other return values
are not be expected to be usable values.

Here is an example of defining a custom error type, `DivideByZero`,
that holds an error message and the numerator value.

```go
type DivideByZero struct {
  numerator float32
}

// This makes the DivideByZero type implement the error interface.
func (err DivideByZero) Error() string {
  return fmt.Sprintf("tried to divide %v by zero", err.numerator)
}

func divide2(a, b float32) (float32, error) {
  if b == 0 {
    return 0, DivideByZero{a}
  }
  return a / b, nil // no error
}
```

It is a convention in Go to handle error conditions before success.
This allows "mainline code" that follows to appear un-indented.
For example, instead of:

```go
result, err := someFunction()
if err == nil {
  // Do something with result.
} else {
  // Handle errors
}
```

the following is preferred:

```go
result, err := someFunction()
if err != nil {
  // Handle errors
  return
}
// Do something with result.
```

#### Panics

TODO: A panic is ...

It is possible to recover from a panic.
TODO: Add detail.
