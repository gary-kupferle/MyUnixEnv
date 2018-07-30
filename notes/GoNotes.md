# Go Programming Language Notes

## Overview

- announced by Google in 2009
- originally designed to be a systems programming language
  - aims to be a better C
  - but most developers use C, C++, or Rust for that
- simplicity and performance are major goals
  so many features found in other programming languages
  are not present in Go
  - ex. generic types
- does not compete with scripting languages like
  JavaScript, Perl, Python, and Ruby
- currently the most common uses are for
  the server side of web application and dev ops tooling

## Characteristics

- high performance
- statically typed
- compiled
- provides type inference
- performs garbage collection
- supports asynchronous processing with lightweight threads via goroutines
- provides communication between goroutines using channels
- supports networking operations
- supports concurrency
- supports JSON marshalling and unmarshalling
- minimal support for object-oriented programming
  - through structs with methods
- no builtin support for functional programming
  - for example, no builtin map, filter, and reduce functions for arrays
  - hard to implement due to lack of generics
- supports composition, but not inheritance of types

## Reasons to use

- type safety
- performance
- network library

## Resources

- spec: <https://golang.org/ref/spec>
- tour: <https://tour.golang.org/>
- playground: <https://play.golang.org/>

## Installing

- browse <https://golang.org/dl/>
- download a platform-specific installer
- double-click to run it
- create a "go" directory in your home directory
  - GOPATH is set to this by default
  - to use another directory, set GOPATH to it

## Syntax Highlights

- semicolons are not required,
  but can be used to place multiple statements on the same line
- types follow parameters, separated by a space
- exported variables and struct members have names that start uppercase
- outside of functions, every line begins with a keyword
  - this explains why the `:=` operator is not allowed outside of functions

## Tooling

- `go` command has many sub-commands
- most commonly used commands

  - `go help [command|topic]`
    - outputs help
    - run with no argument to see a list of commands and topics
  - `go doc {pkg}`
    - outputs documentation for a given package
    - ex. `go doc json`
  - `go get {pkg1} {pkg2} ...`
    - downloads and installs packages and their dependencies
  - `go build {file-name}.go`
    - builds an executable that includes everything needed to run
    - Go tools do not need to be installed in order to execute the result
  - `go install {pkg-name}`
    - builds a package and installs it in the directory in GOBIN
  - `go run {file-name}.go`
    - runs a program without producing an executable
  - `go test`
    - runs all the tests in the current package?
  - `go generate`

    - creates or updates Go source files
    - TODO: learn more about this

## Code Formatting

- gofmt tool
  - uses tabs for indentation and spaces for alignment

## VS Code Go Extension

- may need to
  - set GOPATH environment variable and restart VS Code before installing this
  - run `go get -u github.com/mdempsky/gocode`
  - run `go get -u golang.org/x/lint/golint`
  - set GOPATH to ~/go
  - create a `bin` subdirectory
  - set GOBIN to $GOPATH/bin
  - add $GOBIN to PATH
- why isn't "format on save" working?
- for a description of how this extension can use GOPATH see
  <https://github.com/Microsoft/vscode-go/wiki/GOPATH-in-the-VS-Code-Go-extension>

## Standard Library Packages

- to see a list of them, browse <https://golang.org/pkg/>

## Community Packages

- to see a list of them with links to documentation,
  browse one of these
  - <https://godoc.org/>
  - <https://go-search.org/>
  - <https://github.com/golang/go/wiki/Projects>

## Getting Started

- initial file must contain
  - `package main`
  - `func main() { ... }`
- can run with
  - `go run file-name.go`
  - `go build file-name.go; ./file-name`

## Important Environment Variables

- GOARCH
  - target architecture to use when compiling
- GOBIN
  - where packages are installed
- GOOS
  - target operating system when compiling
- GOPATH
  - where source files are located
- GOROOT
  - what Go tools are installed

## Comments

- same a C
- `//` for single-line comments
- `/* ... */` for multi-line comments

## Variables

- mutable unless defined with `const`
- block-scoped
- names must start with a letter and
  can contain letters, digits, and underscores
- local to their package unless name starts uppercase
- can define a variable without initializing
  - `var x int`
  - it's an error if the variable has already been defined
- can define a variable with initial value
  - `var x = 3`
- can do both, but that is redundant
  - `var x int = 3`
- `var` can be used inside or outside of a function
- can define multiple variables with one `var`

  ```go
  var (
    alpha = 1
    beta = 2
  )
  ```

- can assign a value to an already defined variable
  - `x = 4`
  - it's an error if the variable has not already been defined
- `:=` can only be used inside a function
  - defines and initializes a new variable
  - `x := 5` is shorthand for `var x = 5`
  - particularly useful for capturing function return values
    and creating multiple variables in a single line
- the variable "\_" is used to discard a function return value
- uninitialized variables are set to their "zero value"
  - false for bool
  - 0 for numbers
  - "" for strings
  - nil for pointers, slices, maps, functions, interfaces, and channels
  - TODO: What is the zero value for an array? An empty array?

## Constants

- defined with `const` keyword
- must be initialized
- ex. const BLACKJACK = 21

## Operators

- arithmetic: `+`, `-`, `\*`, `/`, `%` (mod)
- arithmetic assignment: `+=`, `-=`, `\*=`, `/=`, `%=`
- increment: `++`
- decrement: `--`
- assignment: `=` (existing variable), `:=` (new variable)
- comparison: `==`, `!=`, `<`, `<=`, `>`, `>=`
- logical: `&&` (and), `||` (or), `!` (not)
- bitwise: `&`, `|`, `^`, `&^` (bit clear)
- bitwise assignment: `&=`, `|=`, `^=`, `&^=`
- bit shift: `<<`, `>>`
- bit shift assignment: `<<=`, `>>=`
- channel direction: `<-`
- variadic parameter: `...paramName`
- slice spread: `sliceName...`
- pointer creation: `&varName`
- pointer dereference: `\*pointerName`
- block delimiters: `{ }`
- expression grouping: `( )`
- function calling: `fnName(args)`
- create array: `[elements]`
- struct member reference: `structName.memberName`
- statement separator: `;`
- array element separator: `,`
- define label: `someLabel:` (see `goto` keyword)

## Keywords

- `break` - breaks out of a `for` loop, `select`, or `switch`
- `case` - used in a `select` or `switch`
- `chan` - channel type
- `const` - declares a constant
- `continue` - advances to the next iteration of a for loop
- `default` - the default case in a `select` or `switch`
- `defer` - defers execution of a given function until the containing function exits
  - TODO: When is this useful? Why not move the call to the end of the function?
- `else` - part of an `if`
- `fallthrough` - used as last statement in a `case` to execute code in next `case`
- `for` - only loop syntax; C-style (init, condition, and post) or just condition
- `func` - defines a named or anonymous function
- `go` - precedes a function call to execute it asynchronously as a goroutine
- `goto` - jumps to a given label (see `:` operator)
- `if` - for conditional logic; also see `else`
- `import` - imports all the exports in given package(s); can't import a subset
  - will get an error if no symbols from an import are used
- `interface` - defines a set of methods
  - defines a type where all implementing structs are compatible
  - structs do not state the interfaces they implement,
    they just implement all the methods
- `map` - type for a collection of key/value pairs where the keys and values can be any type
- `package` - specifies the package to which the current source file belongs
- `range` - used in a `for` loop to iterate over a string, array, slice, map, or receiving channel
- `return` - terminates the containing function and returns zero or more values
- `select` - chooses from a set of channel send or receive operations; see "Select" section
- `struct` -
- `switch` - similar to other languages; see "Switch" section
- `type` -
- `var` -

## Pointers

- hold the address of a variable or `nil
- to get the address of a variable
  - myPtr = &myVar
- to get the value at a pointer
  - myValue = \*myPtr
- to modify the value at a pointer
  - \*myPtr = newValue

## Output

- supported by the "fmt" package

```go
import "fmt"
fmt.Println(expression)
```

## If Statement

- parentheses are not required around the condition being tested
- ex.

  ```go
  if x > 7 {
  } else {
  }
  ```

## Switch Statement

- similar to other languages
- can switch on expressions of any type
- case values can be literal values or expressions
- case blocks do not fall through by default so `break` is not needed
- can use `fallthrough` to get this
- ex.

  ```go
  switch name {
    case "Mark":
      // handle Mark
    case "Tami":
      // handle Tami
    default:
      // handle all other names
  }
  ```

- omit expression after `switch` to run the first `case` block that evaluates to true

  - ex.

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

- to switch on the type of an expression

  ```go
  switch value := expression.(type) {
    case int, float:
      // handle int or float
    case string:
      // handle string
    default:
      // handle all other types
  }
  ```

## For Statement

- the only looping statement
- can use `break` and `continue` inside
- syntax is `for init; cond; post { ... }`
- ex.

  ```go
  for i: 0; i < 10; i++ {
    ...
  }
  ```

- init and post are optional

  - so a while loop in other languages looks like this in go

  ```go
  for ; i < 10; {
    ...
  }
  ```

  - or drop the semicolons because when only one part is present it is assumed to be the condition

  ```go
  for i < 10 {
    ...
  }
  ```

  - omit the condition for an endless loop

  ```go
  for {
    ...
  }
  ```

## Strings

- immutable sequences of bytes representing UTF-8 characters
- literal values are delimited with double quotes or back-ticks (to include newlines)
- to declare and initialize, `name := "Mark"`
- to retrieve a character, `char := name[index]`
- it iterate over, `for _, char := range name { ... }`
- can concatenate with the `+` and `+=` operators
- the `string` type has no methods; use functions in the `strings` package

## Structs

## Arrays

- indexes are zero-based
- have a fixed length
- declare with `[length]type`
  - ex. `var rgb [3]int`
  - placing the square brackets BEFORE the type comes from Algol 68
- can initialize with values in curly braces
  - ex. `rgb := [3]int{100, 50, 234}`
- can get the value at an index
  - ex. `fmt.Println(rgb[1])`
- can change the value at an index
  - ex. `rgb[1] = 75`
- get length with `len(myArr)`
- array elements can be arrays
- to iterate over the elements in an array

  ```go
  for index, value := range myArr {
    ...
  }
  ```

## Slices

- a view into an array with a variable length
- create by specifying the start (inclusive) and end (exclusive) indexes of an array
  - ex. `mySlice = myArr[start:end]`
  - if `start` is omitted, it defaults to 0
  - if `end` is omitted, it defaults to the array length
  - so `myArr[:]` creates a slice over the entire array
- modifying elements of a slice modifies the underlying array
- multiple slices on the same array see the same data
- a slice literal creates a slice and an underlying array
  - ex. `mySlice = []int{2, 4, 6}`
- `len(mySlice)` returns the number of elements it contains (length)
- `cap(mySlice)` returns the number of elements in the underlying array (capacity)
- to extend a slice, recreated it with different bounds
  - ex. `mySlice = mySlice[newStart:newEnd]`
- the zero value is nil
- `make` function
  - can create a "dynamically-sized array"
  - ex. `mySlice := make([]int, 5)`
    - creates an underlying array of size 5
      and a slice of length 5 and capacity of 5
  - ex. `mySlice := make([]int, 0, 5)`
    - creates an underlying array of size 5
      and a slice of length 0 and capacity of 5
  - to expand the size of the slice
    `mySlice = mySlice[newStart:newEnd]`
- slice elements can be slices
- to append new elements to a slice
  - this is where it really gets dynamic!
  - `mySlice = append(mySlice, 8, 10)`
  - appends the values 8 and 10
  - if the underlying array is too small,
    a larger array is automatically allocated
    and the returned slice will refer to it
    - since this can be inefficient, try to
      estimate the largest size needed at the start
- to use all the elements in a slice as separate arguments to a function
  follow the variable name holding the slice with an ellipsis

## Maps

- collections of key/value pairs where keys and values can be any type
- to declare, `map[keyType]valueType`
  - ex. `var myMap map[string]int`
- to declare and initialize,
  `var myMap = map[keyType]valueType{k1: v1, k2: v2, ...}`
  or
  `myMap := map[keyType]valueType{k1: v1, k2: v2, ...}`
- to add a key/value pair, `myMap[key] = value`
- to get the value for a given key, `myMap[key]`
- to delete a key/value pair, `delete(myMap, key)`
- to iterate over, `for key, value := range myMap { ... }`

## Goroutines

- a lightweight thread of execution
- to create one, proceed any function call with `go`
- without using `go` the call is synchronous
- with using `go` the call is asynchronous

## Channels

- pipes that connect concurrent goroutines
- can send values to them and receive values from them
- to create a channel, `myChannel := make(chan type)`
  where type is a real type like `string`
- to send a value to a channel, `myChannel <- value`
  - by default, blocks until the channel retrieves it (unbuffered)
- to retrieve a value from a channel, `value := <-channel`
  - by default, blocks until the channel sends it (unbuffered)
- channel direction

  - the type `chan` can send and receive values
  - to only allow sending, use `chan<-`
  - to only allow receiving, use `<-chan`

- buffered channels
  - accept a limited number of values with a corresponding receiver
  - to create, add size as second argument to make
    - ex. `myChannel := make(chan string, 5)`
  - there is probably no way to create a buffered channel with no size limit
- can use channels for synchronizing goroutine execution

  - to wait for a value to be sent to a channel, `<-myChannel`
  - to wait for a goroutine to complete, do something like this

  ```go
  import "time"

  func myAsync(done chan<- bool) { // can send, but not receive
    // Do some asynchronous thing.
    time.Sleep(time.Second * 3)
    // When it completes, do this:
    done <- true
  }

  done := make(chan bool, 1)
  go myAsync(done)
  <-done
  ```

## Select

- can wait on multiple channels
- blocks until one of the channels is ready
- chooses randomly if multiple channels are ready
- `default` block, if present, is run if no channels are ready
- when using `break` in a `select` `case` that is inside a `for` loop,
  to jump out of the loop add a label before the loop and break to it

  - alternatively use `return` to exit the containing function

  - ex.

    ```go
    c1 := make(chan string)
    c2 := make(chan string)

    go func() {
      time.Sleep(1 * time.Second)
      c1 <- "one"
    }()
    go func() {
      time.Sleep(2 * time.Second)
      c2 <- "two"
    }()

    for i := 0; i < 2; i++ {
      select {
      case msg1 := <-c1:
        fmt.Println("received", msg1)
      case msg2 := <-c2:
        fmt.Println("received", msg2)
      }
    }
    ```

## Functions

- defined with `func` keyword
- arguments are passed by value
- to avoid creating copies of structs, arrays, and slices,
  pass pointers

```go
func myFunctionName(args) return-type {
  ...
}
```

- anonymous functions have the same syntax, but omit the name

  - ex. `func(v int) int { return v * 2 }`

- variadic functions
  - accept a variable number of arguments
  - precede last argument type with an ellipsis
  - ex.
    ```go
    func log(args ...any) {
      fmt.Println(args)
    }
    ```
- spreading a slice
  - to pass all the elements in a slice as separate arguments
    follow the argument with an ellipsis
  - ex. `log(mySlice...)`

## Interfaces

- an interface defines a set of methods and a type
- all structs that implement all the methods are compatible
- structs do not state the interfaces they implement,
  they just implement all the methods
- ex.

  ```go
  package main
  import "fmt"
  import "math"

  type geometry interface {
    area() float64
  }

  type rect struct {
    width, height float64
  }
  func (r rect) area() float64 {
    return r.width * r.height
  }

  type circle struct {
    radius float64
  }
  func (c circle) area() float64 {
    return math.Pi * c.radius * c.radius
  }

  func main() {
    r := rect{width: 3, height: 4}
    c := circle{radius: 5}
    fmt.Println(r.area())
    fmt.Println(c.area())
  }
  ```

- `interface{}` can be used to represent any type

## Builtin Constants

- listed as being in a package named "builtin" for documentation purposes,
  but no such package actually exists
- boolean literals `true` and `false`
- `iota` - an untyped int whose value is zero
  - TODO: when is this typically used?

## Builtin Variables

- listed as being in a package named "builtin" for documentation purposes,
  but no such package actually exists
- `nil` - the zero value for a pointer, channel, func, interface, map, or slice

## Documentation Types

- these types appear in documentation, but are not real types
- `Type` - represents a specific type for a given function invocation
- `Type1` - like `Type`, but for a different type than it
- `ComplexType` - represents a complex64 or complex128
- `FloatType` - represents a float32 or float64
- `IntegerType` - represents any int type

## Builtin Types

- float32 float64
- complex64 complex128
- string
  - literal values are surrounded by " or `
  - "" strings cannot contain newlines and can contain escape sequences like \n
  - '' strings can contain newline characters
  - indexed from zero
  - to get the 3rd character, `str[2]`
- the size of int, uint, and uintptr are usually

  - 32 bits on 32-bit systems
  - 64 bits on 64-bit systems

- `bool` - values are the builtin constants `true` and `false`
  - can use with the operators &&, ||, and !
- `byte` - alias for uint8
- `complex64` and `complex128` - complex numbers
- `float32` and `float64` floating-point numbers
- `int`, `int8`, `int16`, `int32`, `int64` - signed integers
  - `int` is at least 32 bits
- `uint`, `uint16`, `uint32`, `uint64` - unsigned integers
  - `uint` is at least 32 bits
- `uintptr` - holds any kind of pointer
- `rune` - alias for int32; used for unicode characters
  that range in size from 1 to 4 bytes
  - literal values are surrounded by '
- `string` - a sequence of 8-bit bytes, not unicode characters

## Builtin Functions

- these are listed as being in a package named "builtin"
  for documentation purposes, but no such package actually exists

### for complex numbers

- `complex` - constructs a complex value from two floating-point values
- `imag(c ComplexType) FloatType` - returns the imaginary part of a complex number
- `real` - returns the real part of a complex number

### for output

- `print(args ...Type)` - writes to stderr;
  useful for debugging; may be dropped from language
- `println(args ...Type)` - like `print` but adds newline

### for data structures

- `append(slice []Type, elems ...Type) []Type` -
  appends elements to the end of a slice and returns the updated slice
- `cap(v Type) int` - returns the capacity of v
- `copy(dst, src []Type) int` - copies elements from a source slice
  to a destination slice and returns the number off elements copied
- `delete(m map[Type]Type1, key Type)` - deletes the element at a key from a map
- `len(v Type) int` - returns the length of v where v is a string, array, slice, or map?
- `make(t Type, size ...IntegerType) Type` -
  allocates and initializes a slice, map, or chan;
  if Type is Slice, pass the length, and optional capacity;
  if Type is Map, optionally specify number of key/value pairs for which to allocate space
- `new(Type) *Type` - allocates memory for a given type and returns pointer to it

### for channels

- `close(c chan<-)` - closes a channel after the last sent value is received
- `make(Channel, [buffer-capacity])` - unbuffered if buffer-capacity is omitted

### for error handling

- `panic(v interface{})` - stops normal execution of the current goroutine;
  cascades upward through call stack;
  terminates program and reports an error condition;
  can be controlled by the `recover` function
  - similar to `throw` in other languages
- `recover` - call inside a deferred function to
  stop the panic sequence and restore normal execution
  - similar to `catch` in other languages
- `error` - type that represents an error condition
  - has value `nil` when there is no error

## Not Functional

- Go doesn't support functional programming out of the box
- can simulate some features like this

  ```go
  type intToIntFn = func(int) int

  func mapOverInts(arr []int, fn intToIntFn) []int {
    result := make([]int, len(arr))
    for i, v := range(arr) {
      result[i] = fn(v)
    }
    return result
  }

  rgb := [3]int{100, 50, 234}
  double := func(v int) int { return v * 2 }
  log(mapOverInts(rgb[:], double))
  ```

## Packages

## Concurrency
