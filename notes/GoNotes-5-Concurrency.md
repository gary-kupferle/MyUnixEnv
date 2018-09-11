## Concurrency

Concurrency in Go is primarily supported by four features,
see Goroutines, Channels, the `select` statement, and Mutexes.

### Goroutines

The name "goroutine" is a play on "coroutine" which is described
in Wikipedia at <https://en.wikipedia.org/wiki/Coroutine>.
A goroutine is a lightweight thread of execution
managed by the Go runtime that runs a specific function call.
Each goroutine consumes about 2K of memory compared to 1MB for a Java thread.
They use more memory only when needed.

Goroutines start up faster than threads.
They not mapped one-to-one with threads, but are multiplexed across them.

A goroutine runs until its function exits or the application terminates.

The `main` function of an application runs in a goroutine,
so there is always at least one.

To create a new goroutine, proceed any function call,
named or anonymous, with `go`.
Arguments to the function are evaluated in the current goroutine.
The function is executed asynchronously inside the new goroutine
when it is scheduled to run in a thread.
When a function is called without using `go` the call is synchronous.

To get the number of currently running goroutines,
call `runtime.NumGoRoutine()`.

To get the number of CPUs in the computer, call `runtime.NumCPU()`.
This may be useful to decide at runtime how many goroutines to start.

Goroutines share memory, so access should be synchronized
either by using channels or mutexes.

Often when writing code that demonstrates goroutines
it is useful to pause their execution for a given duration
to simulate a long-running process.
The standard library package `time` can be used to do this.
`time.Sleep(duration)` pauses the current goroutine for the given duration
where duration is in nanoseconds (1 nanosecond = 1,000,000 milliseconds).

### Channels

Channels are "pipes" that allow concurrent goroutines to communicate.
Values can be sent to a channel and be received from them.

To create a channel, use the builtin `make` function.
For example, `myChannel := make(chan string)` creates a channel
for sending and receiving strings. Non-primitive types
such as structs, slices, and maps can also be used.

Channels that are created without specifying a size are "unbuffered".
Later we will see how to make them buffered.

To send a value to a channel, `myChannel <- value`.
If the channel is unbuffered, this blocks
until another goroutine receives the value.

To receive a value from a channel, `value := <-channel`.
If the channel is unbuffered, this blocks
until another goroutine sends a value to the channel.

A channel can be closed by passing it to the `close` function.
Only "sending" goroutines that are the only goroutine
that sends to a channel should close it.

When reading from a channel, a second return value
indicates whether the channel is still open.
For example, `data, open = <-myChannel`.
See <https://go101.org/article/channel-closing.html>
for details and more options.

Once a channel has been closed, a panic will be triggered
if there is an attempt to send to it or close it again.
Attempts to receive data from a closed channel will get the zero value,
but it is recommended to check whether the channel is closed
since it is not possible to distinguish between getting a zero value
because the channel is closed versus getting a zero value
that was actually sent to the channel.

Receivers can determine if a channel is closed
by capturing a second return value that is a boolean
indicating whether the channel is open.
For example,

```go
package main

import "fmt"

func getNumbers(start int, c chan<- int) {
  for n := start; n < 10; n += 2 {
    c <- n
  }
  close(c)
}

func main() {
  c1 := make(chan int)
  c2 := make(chan int)

  go getNumbers(1, c1) // odd numbers
  go getNumbers(2, c2) // even numbers

  n := 0
  moreEvens, moreOdds := true, true

  for {
    select {
    case n, moreOdds = <-c1:
      if moreOdds {
        fmt.Println(n, moreOdds)
      }
    case n, moreEvens = <-c2:
      if moreEvens {
        fmt.Println(n, moreEvens)
      }
    }
    if !moreEvens && !moreOdds {
      break
    }
  }
}
```

Attempts to send data to or retrieve data from a nil channel
will block forever.

### Channel Direction

The type `chan` can be used to both send and receive values.
When a channel is passed to a function,
the argument type can state that the function
will only write to or read from the channel.
To only write, use `chan<- type`.
To only read, use `<-chan type`.
Functions that accept a read-only or write-only channel
can be passed a read/write channel.
But functions that accept a read/write channel
cannot be passed a read-only or write-only channel.

For example,

```go
package main

import "fmt"

func writer(c chan<- int) { // only writes
  c <- 2
  c <- 7
}

func reader(c <-chan int) { // only reads
  n := <-c
  fmt.Println("got", n)
  n = <-c
  fmt.Println("got", n)
}

func main() {
  c := make(chan int) // works buffered or not
  go writer(c) // runs in a new goroutine
  reader(c) // runs in current goroutine
}
```

### Buffered Channels

Buffered channels allow multiple values to be
sent to or received from a channel without blocking.

To create a buffered channel, pass a size
as the second argument to the `make` function.
For example, `myChannel := make(chan string, 5)`
creates a channel that can hold up to 5 unread strings.
There is no builtin way to create a buffered channel
with an unlimited capacity.

Sending to a buffered channel only blocks if the channel is full.
Receiving from a buffered channel only blocks if the channel is empty.

A `for` loop can be used to iterate over the values in a channel
that is closed after the last value is sent to it.
For example,

```go
package main

import "fmt"

func getWords(c chan string) {
  c <- "alpha"
  c <- "beta"
  c <- "gamma"
  close(c)
}

func main() {
  c := make(chan string)
  go getWords(c)
  // This loop terminates when the channel is closed
  // without explicitly checking for that.
  for word := range c {
    fmt.Println(word)
  }
}
```

It is sometimes useful to use use a non-data channel
to synchronize goroutine execution.
This is particularly the case when
a receiving goroutine receives data from multiple channels
and one or more of them is able to determine
when the receiving goroutine should stop
trying to receive data from any of them.

Here is a simple example that demonstrates this approach
with only a single sending goroutine:

```go
import "time"

func myAsync(done chan<- bool) { // can send, but not receive
  // Do some asynchronous thing.
  time.Sleep(time.Second * 3)
  // When it completes, signal to the goroutine that started this one.
  done <- true
}

done := make(chan bool, 1)
go myAsync(done)
<-done // Waits for myAsync to single that it is finished.
```

### `select` statement

The `select` statement attempts to receive data
from one of a number of channels.
It is frequent used inside a `for` loop
so multiple values from each channel can be read.

If multiple channels are ready, one is chosen randomly and read.

If none of the channels are ready, there are two possibilities.
If a `default` block is present, that code will run.
If no `default` block is present, the `select` blocks
until one of the channels is ready.

When using `break` in a `select` `case` that is inside a `for` loop,
to jump out of the loop add a label before the loop and `break` to it.
Alternatively use `return` to exit the containing function.

For example,

```go
package main

import (
  "fmt"
  "time"
)

func finite() {
  c1 := make(chan string)
  c2 := make(chan string)

  go func() {
    time.Sleep(1 * time.Second)
    c1 <- "one"
  }() // calling the function
  go func() {
    time.Sleep(2 * time.Second)
    c2 <- "two"
  }() // calling the function

  for i := 0; i < 2; i++ { // only expecting one message from each channel
    select {
    case msg1 := <-c1:
      fmt.Println("received", msg1)
    case msg2 := <-c2:
      fmt.Println("received", msg2)
    }
  }
}

func numbers(c chan int, start int, delta int, sleep int) {
  n := start
  for {
    time.Sleep(time.Duration(sleep) * time.Second)
    c <- n
    n += delta
  }
}

func infinite() {
  c1 := make(chan int)
  c2 := make(chan int)
  go numbers(c1, 1, 2, 1)
  go numbers(c2, 2, 2, 2)

loop:
  for { // expecting an infinite number of messages from each channel
    select {
    case n := <-c1:
      if n > 10 {
        break loop
      }
      fmt.Println("received", n)
    case n := <-c2:
      if n > 10 {
        break loop
      }
      fmt.Println("received", n)
    }
  }
}

func main() {
  finite()
  infinite() // doesn't start until finite finishes
}
```

### Mutexes

The `sync` package defines the `Mutex` and `WaitGroup` structs.
Using a `Mutex` is one way to prevent concurrent access
to shared data from multiple goroutines.

To create a mutex, declare a variable of type `sync.Mutex`.
For example, `var myMutex sync.Mutex`.
Often mutexes are held in the field of a struct
that requires exclusive access.

To lock a mutex, `myMutex.Lock`.

To unlock a mutex, `myMutex.Unlock`.

A `WaitGroup` can be used to wait for multiple goroutines to complete.
To create a WaitGroup, declare a variable of type `sync.WaitGroup`.
For example, `var wg sync.WaitGroup`.

To increment the number of items in a WaitGroup, `wg.Add(n)`.
Call this repeatedly to add more if necessary.

To mark a `WaitGroup` item as done, `wg.Done()`.

To wait for all items in a WaitGroup to be done, `wg.Wait()`.
For example,

```go
package main

import (
  "fmt"
  "math/rand"
  "sync"
  "time"
)

var mutex sync.Mutex
var slice = make([]string, 0)
var wg sync.WaitGroup

func addString(s string) {
  mutex.Lock() // prevent concurrent access to the slice

  // Generate a random duration from zero to 500 milliseconds.
  duration := time.Duration(rand.Int63n(500)) * time.Millisecond
  fmt.Println("duration =", duration)
  time.Sleep(duration)

  slice = append(slice, s)
  fmt.Println("appended", s)

  mutex.Unlock() // finished using slice
}

// This adds a string to the slice a given number of times.
func addStrings(s string, count int) {
  for n := 0; n < count; n++ {
    addString(s)
  }
  wg.Done() // mark this goroutine as done
}

func main() {
  wg.Add(2) // we will create two new goroutines
  go addStrings("X", 5) // starts first goroutine
  go addStrings("O", 3) // starts second goroutine
  wg.Wait() // wait for the two goroutines to be done
  fmt.Printf("%v\n", slice)
}
```

## Builtin Constants

Constants provided by Go are listed as being in a
package named "builtin" for documentation purposes,
but no such package actually exists.
These include the boolean literals `true` and `false`,
and `iota`.

`iota` is not actually a constant.
It is a global counter that is set to zero
at the beginning of every `const` definition,
which is the only place it can be used.
The value of `iota` is incremented by one after each line in the
`const` definition, except for blank lines and comment lines.
It is typically used to define enumerated values.
The last expression involving `iota` is repeated for subsequent
constant values, but using an incremented value of `iota`.
For example:

```go
const (
  red   = iota // 0
  green        // 1
  blue         // 2
)

const (
  apple  = 9        // iota = 0
  banana = 8        // iota = 1
  cherry = iota + 3 // iota = 2, value = 2 + 3 = 5
  date              // iota = 3, value = 3 + 6 = 6
)

const (
  north = iota + 1 // iota = 0, value = 0 + 1 = 1
  south            // iota = 1, value = 1 + 1 = 2
  east             // iota = 2, value = 2 + 1 = 3
  west             // iota = 3, value = 3 + 1 = 4
)

const (
  t1 = iota * 3 // iota = 0, value = 0 * 3 = 0
  t2            // iota = 1, value = 1 * 3 = 3
  t3            // iota = 2, value = 2 * 3 = 6
)

const (
  _        = iota             // iota = 0, ignore first value
  kb int64 = 1 << (10 * iota) // iota = 1, value = 1 shifted left 10 places
  mb                          // iota = 2, value = 1 shifted left 20 places
  gb                          // iota = 3, value = 1 shifted left 30 places
  tb                          // iota = 4, value = 1 shifted left 40 places
)
```

## Builtin Variables

Variables provided by Go are listed as being in a
package named "builtin" for documentation purposes,
but no such package actually exists.
There is only one, `nil`, which is the zero value for a
pointer, channel, func, interface, map, or slice.
For example,
the current value of all the variables below is nil.

```go
var ptr *string         // pointer
var c chan string       // channel
type stringToString func(string) string
var f stringToString    // function
var i error             // interface
var m map[string]string // map
var s []string          // slice
```

## Builtin Types

Go defines the following builtin types.

- `bool`\
  The only values are the builtin constants `true` and `false`.
  These can use with the operators `&&`, `||`, and `!`.
- `byte`\
  This is an alias for the type `uint8`.
- `complex64` and `complex128`\
   These are used to represent complex numbers
  with a specified number of bits.
- `float32` and `float64`\
  These are used to represent floating-point numbers
  with a specified number of bits.
- `int`, `int8`, `int16`, `int32`, `int64`:
  These are used to represent signed integers
  with a specified number of bits.
  The type `int` is at least 32 bits,
  32 bits on 32-bit systems and
  64 bits on 64-bit systems.
- `uint`, `uint16`, `uint32`, `uint64`\
  These are used to represent unsigned integers
  with a specified number of bits.
  The type `uint` is at least 32 bits.
- `uintptr`\
  This type holds any kind of pointer.
- `rune`\
  This is an alias for int32.
  It is used for unicode characters
  that range in size from 1 to 4 bytes.
  Literal values of this type are surrounded by single quotes.
- `string`\
  This is a sequence of 8-bit bytes, not unicode characters.
  Literal values are surrounded by double quotes or backticks.
  Double quoted strings cannot contain newlines
  and can contain escape sequences like `\n`.
  Backtick strings can contain newline characters.
  Both are indexed from zero.
  For example, to get the 3rd character use `str[2]`.

## Documentation Types

Despite Go not currently supporting generic types,
the following "type" names that are not real types
appear in the Go documentation.

- `Type` - represents a specific type for a given function invocation
- `Type1` - like `Type`, but for a different type
- `ComplexType` - represents a complex64 or complex128
- `FloatType` - represents a float32 or float64
- `IntegerType` - represents any int type

## Builtin Functions

Functions provided by Go are listed as being in a
package named "builtin" for documentation purposes,
but no such package actually exists.

### for complex numbers

- `complex` - constructs a complex value from two floating-point values
- `imag(c ComplexType) FloatType` - returns the imaginary part of a complex number
- `real` - returns the real part of a complex number

### for output

- `print(args ...Type)` - writes to stderr;
  useful for debugging; may be dropped from language
- `println(args ...Type)` - like `print` but adds newline
- see `fmt` package to write to stdout

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

## Type Conversions

No type conversions are performed implicitly.
Builtin types can be used as conversion functions.
For example, `f := float32(i)` converts an `int` to a `float32`
and `i := int(f)` converts an `float32` to an `int`,
truncating the fractional part.

An error will be triggered if the conversion cannot be performed.
For example, attempting to convert a string to an int is an error,
even if the string contains a valid number.

To convert the string representation of a number to a number,
use the `strconv` package.  For example,

```go
s := "19"
n, err := strconv.ParseInt(s, 10, 32) // base 10, bitsize 32
```

When a value is held in an interface type,
including the "any" type `interface{}`,
a type assertion can be used to convert it to a non-interface type.
For example, `var f = value.(float32)` converts
a value with an interface type to a `float32`.
This only works if the value actually has a type of `float32`.

## Packages

All Go code resides in some package.

All source files must start with a `package` statement
that includes a package name.
The package name must match the name of the directory that holds the file,
unless the package name is "main".

The `main` function is the starting point of all Go applications
and must defined in a source that starts with `package main`.
This is the only package that does not need to match the name of its directory.

The source files that define the package
can have any file name that ends in `.go`.

For example, if the file `foo.go` is in a directory named `bar`,
the first non-comment line in the file should be `package bar`.

Changing a package name requires renaming the directory
and modifying the `package` statement in all the files.
It seems Go missed an opportunity to
infer the package name from the directory name.

Packages used within an application or other package are not required
to have unique names, but their import paths must be unique.
For example, the import paths `alpha/one` and `beta/one` can coexist
even though the package name for both is `one`.
However, to use both in the same source file,
one of them will need to be given an alias (described later).

Packages contributed by the community (not in the standard library)
must be installed, typically using `go get package-url`.
The `go get` command installs packages under `$GOPATH/src`
regardless of the directory from which it is run.
For example, `go get github.com/julienschmidt/httprouter`
installs the package in `$GOPATH/src/github.com/julienschmidt/httprouter`.
Using the package URL avoids path conflicts.

To import the package, include an `import` statement with a
string that is the package URL without the <https://> prefix.
For example, `import "github.com/julienschmidt/httprouter"`.

Refer to the names it exports by preceding them with `httprouter.`.
For example, `httprouter.ResponseWriter`.
There is not a way to add the exported names to the current namespace
to avoid using the `pkgName.` prefix.

An `import` imports all the exported symbols in a given package.
It is not possible to import just a subset of the exported symbols.

It is recommended that your own packages reside in directories that
reflect their eventual URL should they be publish in the future.
For example, if I created a package named `mypkg`
it should be in the directory `src/github.com/mvolkmann/mypkg`.
Other packages could import this with
`import "github.com/mvolkmann/mypkg"`
and refer to the names it exports with a prefix of `mypkg.`

The `import` keyword imports all exported symbols
(names that start uppercase) from given packages.
To import one package, `import "pkgName"`.
To import multiple packages, `import ("pkgName1" "pkgName2" ...)`.

Unused imports are treated as errors
and some editors automatically remove them.

The strings specified after `import` are slash-separate names.
For standard library packages these can be a single name
like `"strings"` or a name like `"math/rand"`.
For community packages these are URLs without the `https://` prefix.

An alias for a package name can be defined with `import alias "pkgName"`.
Note that the alias name is not surrounded by quotes, but the package name is.
When an alias is defined, exported names in the package are referenced with
`alias.ExportedName`.

Circular imports where an import triggers the import of the current package
are treated as errors.

## Error Handling

Go does not support exceptions.
Instead functions that may encounter errors have an
additional return value of type `error` that callers must check.
The type `error` is an interface that defines a single method `Error`
that returns a string description of the error.
The standard library creates and exports many instances.
It is also possible to define custom implementations of the
`error` interface that hold additional data describing the error.

The `errors` package defines a `New` method
that can be used to create error instances from a string.
For example,

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
  // A common idiom for error checking using
  // the optional assignment of an "if"
  if q, err = divide(7, 0); err == nil {
    fmt.Print(q)
  } else {}
    fmt.Println(err) // prints error message
  }
}
```

Here is an example of defining a custom error type, `DivideByZero`,
that holds an error message and the numerator value.

```go
type DivideByZero struct {
  numerator float32
}

func (err DivideByZero) Error() string {
  return fmt.Sprintf("tried to divide %v by zero", err.numerator)
}

func divide2(a, b float32) (float32, error) {
  if b == 0 {
    return 0, DivideByZero{a}
  }
  return a / b, nil
}
```

## Logging

The standard library `log` package provides methods that
help with writing error messages to stderr.

`log.Fatal(message)` outputs a line containing the date, time, and message,
and exits with a status code of 1.

`log.Panic(message)` outputs a line containing the date, time, and message,
followed by a line containing "panic:" and the message again,
followed by a stack trace,
and exits with a status code of 2.

To write messages that include a file name and line number,
write a function like the following and call it from other functions.

```go
func logValue(name string, value interface{}) {
  // Passing 1 causes it to get the information
  // from one level higher in the call stack.
  _, file, line, ok := runtime.Caller(1)
  if ok {
    fmt.Printf("%s:%d %s=%v\n", file, line, name, value)
  } else {
    fmt.Printf("%s=%v\n", name, value)
  }
}
```

## Tests

Tests should be implemented in files whose name ends with `_test.go`.
These files should import the "testing" package from the standard library.

It is recommended to put tests a package whose name
starts with the name of the package being tested
and ends with "_test".  Doing this requires the test
to call the functions being tested in the same way
as real code because the package being tested must be imported
and the functions must be called using the package name.

Write test functions whose names begin with `Test`.
These functions take one argument, `t \*testing.T`.

If a test assertion fails, call
`t.Error(message)` or `t.Errorf(formatString, values)`.
Another option is to call `t.Fail()`, but that fails with no message.

To log a message in a test, call `t.Log(message)`.

Here is an example of Go code to be tested
in the file `src/github.com/mvolkmann/statistics/sum.go`.

```go
package statistics

func Sum(numbers []float64) float64 {
  sum := 0
  for _, number := range numbers {
    sum += number
  }
  return sum
}
```

Here is an example of a test for the "statistics" package
in the file `src/statistics_test.go`.

```go
package statistics_test

import (
  "fmt"
  "testing"

  "github.com/mvolkmann/statistics"
)

func TestSum(t *testing.T) {
  nums := []float64{1, 2, 3}
  sum := statistics.Sum(nums)
  if (sum != 6) {
    t.Error("expected sum to be 6")
  }
}
```

To run tests, enter `go test` in the directory of the tests.

"Examples" are another way to write test functions.
It is recommended to place these tests
in a file named `example_test.go`.
Example function names begin with `Example`,
followed by the name of the function or type being tested.
When testing a method, end the function name with
the type name followed by an underscore and the method name.
Example functions end with the comment `// Output:`
followed by comment lines containing the expected output.

Here is an example of an example that can be added
in the file `src/statistics_test.go`.

```go
  func ExampleSum() {
    nums := []float64{1, 2, 3}
    fmt.Println("sum is", Sum(nums))
    // Output:
    // sum is 6
  }
```

Examples are more than just another way to write tests.
The "godoc" tool incorporates them into its output.
There are two modes for using this tool, command-line and web server.

For command-line usage, enter `godoc pkg-name [symbol-names]`.
For example, to get documentation on all exported symbols
in the `strings` package, enter `godoc strings`.
To get documentation for only the `Contains` and `Join` functions,
enter `godoc strings Contains Join`.
To include example code in the output (if provided), add the `-ex` option

For web server usage, enter `godoc -http=:port`.
For example, enter `godoc -http=:1234` and browse `localhost:1234`.
This will provide a locally running version of all the standard Go help,
including help on all standard library packages,
community packages that have been installed,
all local packages you have created.

For packages with example tests, an "Example" link
will be rendered.  When clicked, example code is displayed.

![Example screenshot](/images/statistics-sum-example.png)

To enable running example code from the godoc web UI,
include the `-play` option.  This will cause example code
to be rendered in a playground that includes a "Run" button.
TODO: Why does this only work for standard library packages?
TODO: It doesn't work for github.com/mvolkmann/statistics/Sum.

To index all the code so it is searchable using the
"Search" input in the web UI, include the `-index` option.
This takes quite a while to build the index,
so your code will not be searchable for several minutes.

Also see "benchmark" tests which are only run when the `-bench` flag is used.
TODO: Add more detail on these!

## Not Functional

Go doesn't support some aspects of functional programming out of the box.
While go supports first-class functions that can be stored in variables,
passed to functions, and returned from functions,
it does not support concise function definitions (like arrow functions in other languages)
or generics for writing functions that work with multiple types.

Writing generic collection functions such as
`map`, `filter`, and `reduce` is somewhat difficult in Go.
It's easy to write type-specific versions of these.
For example,

```go
func mapOverInts(slice []int, fn func(int) int) []int {
  result := make([]int, len(slice))
  for i, v := range slice {
    result[i] = fn(v)
  }
  return result
}

func main() {
  values := []int{1, 2, 4}
  double := func(v int) int { return v * 2 }
  doubled := mapOverInts(values, double) // [2 4 8]
  fmt.Println(doubled)
}
```

Versions of these functions that work with slices of any value types
can be written using the standard library `reflect` package
along with the "any" type `interface{}`.
This is a kind of substitute for generics.
However, the downside is that type errors become
runtime errors instead of compile-time errors.

Here is an example of how `map`, `filter`, and `reduce`
can be written using the "any" type.

```go
package functional

import (
  "log"
  "reflect"
)

// AssertFunc asserts that a given value is a func and
// the parameter and return types are the expected types.
func AssertFunc(fn interface{}, in []reflect.Type, out []reflect.Type) {
  assertKind(fn, reflect.Func)

  fnType := reflect.TypeOf(fn)

  actualNumIn := fnType.NumIn()
  expectedNumIn := len(in)
  if actualNumIn != expectedNumIn {
    log.Fatalf("expected func with %d parameters but had %d\n", expectedNumIn, actualNumIn)
  }

  actualNumOut := fnType.NumOut()
  expectedNumOut := len(out)
  if actualNumOut != expectedNumOut {
    log.Fatalf("expected func with %d return types but had %d\n", expectedNumOut, actualNumOut)
  }

  for i := 0; i < expectedNumIn; i++ {
    expectedType := in[i]
    actualType := fnType.In(i)
    if actualType != expectedType {
      panicF("expected parameter %d to have type %s but was %s\n", i+1, expectedType, actualType)
    }
  }

  for i := 0; i < expectedNumOut; i++ {
    expectedType := out[i]
    actualType := fnType.Out(i)
    if actualType != expectedType {
      panicF("expected result type %d to have type %s but was %s\n", i+1, expectedType, actualType)
    }
  }
}

// AssertKind asserts the kind of a given value.
func AssertKind(value interface{}, kind reflect.Kind) {
  valueKind := reflect.TypeOf(value).Kind()
  if valueKind != kind {
    panicF("expected kind %s but got %s\n", kind, valueKind)
  }
}

// AssertType asserts the type of a given value.
// Note that this does not currently detect mismatched struct types.
// It just verifies that some kind of struct is received if one is required.
//TODO: Define an assertStruct function that verifies all the struct fields!
func AssertType(value interface{}, typ reflect.Type) {
  valueType := reflect.TypeOf(value)
  if valueType != typ {
    panicF("expected type %s but got %s\n", typ, valueType)
  }
}

func Filter(slice interface{}, predicate interface{}) interface{} {
  AssertKind(slice, reflect.Slice)
  sliceType := reflect.TypeOf(slice)
  elementType := sliceType.Elem()
  AssertFunc(predicate, []reflect.Type{elementType}, []reflect.Type{boolType})

  // Create result slice with same type as first argument.
  result := reflect.New(sliceType).Elem()

  predicateValue := reflect.ValueOf(predicate)
  sliceValue := reflect.ValueOf(slice)

  // Can "range" be used here?
  for i := 0; i < sliceValue.Len(); i++ {
    element := sliceValue.Index(i).Interface()
    elementValue := reflect.ValueOf(element)

    in := make([]reflect.Value, 1)
    in[0] = elementValue
    out := predicateValue.Call(in)

    if out[0].Bool() {
      result = reflect.Append(result, elementValue)
    }
  }

  return result.Interface()
}

// Map creates a new slice from the elements in an existing slice where
// the new elements are the results of calling fn on each existing element.
func Map(slice interface{}, fn interface{}) interface{} {
  AssertKind(slice, reflect.Slice)
  sliceType := reflect.TypeOf(slice)
  elementType := sliceType.Elem()
  AssertFunc(fn, []reflect.Type{elementType}, []reflect.Type{elementType})

  // Create result slice with same type as first argument.
  result := reflect.New(sliceType).Elem()

  fnValue := reflect.ValueOf(fn)
  sliceValue := reflect.ValueOf(slice)

  // Can "range" be used here?
  for i := 0; i < sliceValue.Len(); i++ {
    element := sliceValue.Index(i).Interface()
    elementValue := reflect.ValueOf(element)

    in := make([]reflect.Value, 1)
    in[0] = elementValue
    out := fnValue.Call(in)
    result = reflect.Append(result, out[0])
  }

  return result.Interface()
}

// Reduce reduces the elements in a slice to a single value.
func Reduce(slice interface{}, fn interface{}, initial interface{}) interface{} {
  AssertKind(slice, reflect.Slice)

  initialType := reflect.TypeOf(initial)

  sliceType := reflect.TypeOf(slice)
  elementType := sliceType.Elem()
  AssertFunc(fn, []reflect.Type{initialType, elementType}, []reflect.Type{elementType})

  // Create result slice with same type as first argument.
  result := reflect.ValueOf(initial)

  fnValue := reflect.ValueOf(fn)
  sliceValue := reflect.ValueOf(slice)

  for i := 0; i < sliceValue.Len(); i++ {
    element := sliceValue.Index(i).Interface()
    elementValue := reflect.ValueOf(element)

    in := make([]reflect.Value, 2)
    in[0] = result
    in[1] = elementValue
    out := fnValue.Call(in)
    result = out[0]
  }

  return result.Interface()
}
```

## Memory Allocation

The Go specification does not indicate the situations under which
stack memory or heap memory are used.
The primary Go implementation makes some choices based on the fact that
allocating on the stack is generally faster than allocation on the heap.
The builtin `new` function always allocates on the heap.

## Command-Line Arguments

Command-line arguments are held in a slice stored in `os.Args`.
Index 0 holds the path to the executable.
An executable is created dynamically when "go run" is used.
Index 1 holds the first command-line-argument.
Often `os.Args[1:]` is used to obtain a slice
that only contains the command-line arguments.

For example, suppose the file `greet.go` contains the following:

```go
package main

import (
  "fmt"
  "os"
)

func main() {
  // Get a slice containing only the command-line arguments.
  args := os.Args[1:]

  // If the required number of arguments are not present ...
  if len(args) != 2 {
    fmt.Println("usage: greet {first-name} {last-name}")
    os.Exit(1)
  }

  firstName := args[0]
  lastName := args[1]
  fmt.Printf("Hello %s %s!\n", firstName, lastName)
}
```

To run this, enter `go run greet.go Mark Volkmann`.

To build an executable and run it,
enter `go build greet.go; ./greet Mark Volkmann`

## Readers

The `io` package defines the `Reader` interface
that has a single method `Read`.
This populates a byte slice and returns the number of bytes read
or an error (io.EOF if end of stream is reached).

There are many implementations of this interface in the standard library,
including ones for reading from strings, files, and network connections.

To read from a string, see <https://tour.golang.org/methods/21>.

To read from a file, use the package `io/ioutil`
which defines a `ReadFile` function.

For example,

```go
package main

import (
  "fmt"
  "io/ioutil"
  "log"
)

func main() {
  // Read entire file into a newly created byte array.
  bytes, err := ioutil.ReadFile("haiku.txt")
  if err != nil {
    log.Fatal(err)
  } else {
    fmt.Println(string(bytes))
  }
}
```

## Writers

The `io` package defines the `Writer` interface
that has a single method `Write`.
This writes a byte slice to an underlying data stream
and returns the number of bytes written or an error.
There are many implementations in the standard library
including ones for writing to strings, files, and network connections.

To write to a string, see TODO.

The package `io/ioutil` defines a `WriteFile` function.
Here is an example of code that writes to a file.

```go
package main

import (
  "io/ioutil"
  "log"
)

func main() {
  data := []byte("Line #1\nLine #2")
  mode := os.FileMode(0644)
  err := ioutil.WriteFile("new-file.txt", data, mode)
  if err != nil {
    log.Fatal(err)
  }
}
```

To write data a little at time,

```go
package main

import (
  "fmt"
  "log"
  "os"
)

func check(e error) {
  if e != nil {
    log.Fatal(e)
  }
}

func writeLine(file *os.File, text string) {
  bytes, err := file.Write([]byte(text + "\n"))
  check(err)
  fmt.Printf("wrote %v bytes\n", bytes)
}

func main() {
  var (
    file *os.File
    err error
  )

  file, err = os.Create("out-file.txt")
  check(err)
  defer file.Close()

  writeLine(file, "Line #1")
  writeLine(file, "Line #2")
}
```

## Reflection

The standard library package `reflect` provides run-time reflection
for determining the type of a value and manipulating it in a type-safe way.

To get the type of an expression, `typ := reflect.TypeOf(expression)`.
This returns a `Type` object that has many methods.

The `Type` method `Name` returns the type as a string.
The `Type` method `Kind` returns the type as an
enumerated value of type `reflect.Kind`.  For example,

```go
package main

import (
  "fmt"
  "reflect"
)

type any interface{}

func whatAmI(value any) {
  kind := reflect.TypeOf(value).Kind()
  switch kind {
  case reflect.Array:
    fmt.Println("I am an array.")
  case reflect.Slice:
    fmt.Println("I am a slice.")
  default:
    fmt.Println("I am something else.")
  }
}

func main() {
  s := []int{1, 2, 3}
  whatAmI(s)

  a := [3]int{1, 2, 3}
  whatAmI(a)

  i := 1
  whatAmI(i)
}
```

The `Type` method `PkgPath` returns the import path for the type.
The `Type` method `Implements` returns a boolean indicating
whether the type implements a given interface type.

For function types, it is possible to iterate
over its parameters and return types.
The `Type` method `NumIn` returns the number of parameters in the function.
The `Type` method `In` returns a `Type` object
describing the parameter at a given index.
The `Type` method `NumOut` returns the number of return types in the function.
The `Type` method `Out` returns a `Type` object
describing the return type at a given index.

For struct types, it is possible to iterate over its fields.
The `Type` method `NumField` returns the number of fields in the struct.
The `Type` method `FieldByIndex` returns a `StructField` object
describing the field at a given index.

For interface types, it is possible to iterate over its methods.
The `Type` method `NumMethod` returns the number of methods in the interface.
The `Type` method `Method` returns a `Method` object
describing the method at a given index.

For map types, it is possible to obtain the key and value types.
The `Type` method `Key` returns a `Type` object describing the key type.
The `Type` method `Elem` returns a `Type` object describing the value type.
This method can also be used to get the element type of an
`Array`, `Chan`, pointer, or `Slice`.

For array and slice types ...
To get a `Value` for a slice, `reflect.Value(slice)`.
To get the length, `value.Len()`
To get the element at index i, `value.Index(i)`.

There is much more to reflection in Go!

## JSON

The `encoding/json` standard library package
supports marshalling and unmarshalling of JSON.

To marshal data to JSON use the `json.Marshal` function.
For example,

```go
import "encoding/json"

// Note that the field names must start uppercase
// so the json package can access them.
type person struct {
  Name string
  Age number
}
p := person{Name: "Mark", Age: 57}
jsonData, err := json.Marshal(person)
// Check `err` to verify that this was successful.
// jsonData will have the type []byte.
// To get a string from it, use string(jsonData).
```

To unmarshal data from JSON use the `json.Unmarshal` function.
For example,

```go
var p person
err := json.Unmarshal(jsonData, @p)
// Check `err` to verify that this was successful.
```

## HTTP Servers

HTTP servers can be implemented using the standard library package `net/http`.
There are also many community packages that make this easier and add many features.
A popular example is the `httprouter` package at <https://github.com/julienschmidt/httprouter>.

The following sections provide examples of implementing an HTTP REST server
using `net\http` and `httprouter`.

### REST Server Using Standard Library

The net/http package in the standard library can be used to implement REST services.
Here is an example of a simple HTTP server in a file named `main.go`.
To run it, enter `go run main.go` and browse localhost:1234.

```go
package main

import (
  "fmt"
  "net/http"
)

type myHandler struct{}

func (handler myHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  fmt.Fprint(w, "Hello, World!")
}

func main() {
  var handler myHandler
  http.ListenAndServe("localhost:1234", handler)
}
```

The `net/http` package can also be used to
send an HTTP request and receive the HTTP response.
For example, here is an application that uses an iTunes REST service
to get a list of albums by a given artist.
For more details on this service, see
<https://affiliate.itunes.apple.com/resources/documentation/itunes-store-web-service-search-api/#lookup>.

```go
package main

import (
  "encoding/json"
  "fmt"
  "io/ioutil"
  "log"
  "net/http"
  "os"
  "sort"
  "strings"
  "time"
)

// Album describes a single album.
// This will be used by json.Unmarshall which
// requires all the fields to be exported (uppercase).
// It matches JSON property names to these case-insensitive.
type Album struct {
  ArtistID         int
  CollectionID     int
  ArtistName       string
  CollectionName   string
  ReleaseDate      string
  PrimaryGenreName string
}

// Albums describes a collection of albums.
// This will also be used by json.Unmarshall.
type Albums struct {
  ResultCount int
  Results     []Album
}

func check(err error) {
  if err != nil {
    log.Fatal(err)
  }
}

func main() {
  // An artist name must be supplied as a command-line argument.
  if len(os.Args) < 2 {
    log.Fatal("usage: albums {artist}")
  }

  // Form the artist name from all the command-line arguments.
  artist := strings.Join(os.Args[1:], " ")
  urlPrefix := "https://itunes.apple.com/search?term="
  getURL := urlPrefix + strings.Replace(artist, " ", "+", -1) + "&entity=album"

  // Get all the albums by the artist.
  resp, err := http.Get(getURL)
  check(err)
  defer resp.Body.Close()

  // Read the entire response body into a slice of bytes.
  body, err := ioutil.ReadAll(resp.Body)
  check(err)
  //fmt.Println("body =", string(body))

  // Parse the bytes as JSON.
  // Using json.Unmarshall is preferred over json.NewDecoder
  // for JSON in HTTP response bodies.  JSON properties that
  // don't match a field in the struct being populated are ignored.
  var albums Albums
  err = json.Unmarshal(body, &albums)
  check(err)
  //fmt.Printf("albums = %+v\n", albums)

  // Sort albums by release date.
  results := albums.Results
  sort.Slice(results, func(i, j int) bool {
    return results[i].ReleaseDate < results[j].ReleaseDate
  })

  fmt.Println("Albums by " + artist)
  for _, album := range albums.Results {
    t, err := time.Parse(time.RFC3339, album.ReleaseDate)
    check(err)
    fmt.Printf("%s - %d/%d/%d\n", album.CollectionName, t.Month(), t.Day(), t.Year())
  }
}
```

### REST Server Using httprouter

```go
package main

import (
  "encoding/json"
  "fmt"
  "log"
  "net/http"

  "github.com/julienschmidt/httprouter"
)

type any interface{}

func getImageURL(res http.ResponseWriter, _ *http.Request, params httprouter.Params) {
  imageURL := "http://some-domain/some-image.jpg"
  sendText(res, imageURL)
}

func hello(res http.ResponseWriter, _ *http.Request, params httprouter.Params) {
  fmt.Fprintf(res, "hello, %s!\n", params.ByName("name"))
}

// Can"t just omit the unused parameters.
func index(res http.ResponseWriter, _ *http.Request, _ httprouter.Params) {
  fmt.Fprint(res, "Welcome!\n")
}

func notFound(res http.ResponseWriter, _ *http.Request) {
  fmt.Fprintf(res, "Sorry, I could not find that.")
}

func postFindPerson(res http.ResponseWriter, _ *http.Request, params httprouter.Params) {
  type person struct {
    Name string
    Age number
  }
  output := person{Name: "Mark", Age: 57}
  sendJSON(res, output)
}

func sendJSON(res http.ResponseWriter, obj any) {
  jsonData, err := json.Marshal(obj)
  if err != nil {
    msg := fmt.Sprintf("error marshaling %+v to JSON", obj)
    http.Error(res, msg, http.StatusBadRequest)
  } else {
    res.Header().Set("Content-Type", "application/json")
    res.Write(jsonData)
  }
}

func sendText(res http.ResponseWriter, text string) {
  res.Write([]byte(text))
}

func main() {
  router := httprouter.New()

  router.GET("/", index)
  router.GET("/hello/:name", hello)
  router.GET("/image/:id", getImageUrl)
  router.POST("/person", postFindPerson)

  // To get the file foo.html in the public directory,
  // browse localhost:8080/public/foo.html.
  router.ServeFiles("/public/*filepath", http.Dir("public"))
  router.NotFound = http.HandlerFunc(notFound)

  log.Fatal(http.ListenAndServe(":8080", router))
}
```

## go-watcher

The go-watcher application starts another application in the current directory
watches all the `.go` files in and below current directory,
and restarts the app when any are modified.
It is ideal for working on servers such as HTTP servers.

`GOPATH` must be set to point to the directory
containing the `src` directory of the app.
To use this,
cd to the directory that contains the `.go` file containing
the application `main` function and enter `watcher`.
(This works in bash, but not in the Fish shell.)

It is also possible to specify command-line arguments
to be passed to the app.

For more information, see <https://github.com/canthefason/go-watcher>.

## SQL Databases

The standard library package `database/sql` defines
interfaces that are implemented by database-specific drivers.
This allows many databases to be accessed using the same API.

Database drivers can be installed using `go get`.
For MySQL, `go get github.com/go-sql-driver/mysql`.
For PostgreSQL, `go get github.com/lib/pq`
For other databases, see <https://github.com/golang/go/wiki/SQLDrivers>.

For more detail on accessing databases from Go,
see <http://go-database-sql.org/>.

Here is an example of an application that uses a MySQL database.
It selects the `name` column for all rows in the `hero` table
and writes them to stdout.

```go
package main

import (
  "database/sql"
  "fmt"
  "log"

  _ "github.com/go-sql-driver/mysql" // anonymous import
)

func check(err error) {
  if err != nil {
    log.Fatal(err)
  }
}

func main() {
  db, err := sql.Open("mysql",
    "root:root@tcp(127.0.0.1:3306)/tour_of_heroes")
  check(err)
  defer db.Close()

  rows, err := db.Query("select name from hero")
  check(err)
  defer rows.Close()

  var name string
  for rows.Next() {
    err := rows.Scan(&name)
    check(err)
    fmt.Println(name)
  }
  err = rows.Err()
  check(err)
}
```

## Calling other languages from Go

The `cgo` tool allows Go code to call C code.
For more detail, see <https://golang.org/cmd/cgo/>.

If needed, the C code can use the Java Native Interface (JNI)
to call Java code.

## Calling Go from other languages

The `gobind` tool generates language bindings
for calling Go functions from Java and Objective-C.

Go code can be built with the `-buildmode=c-shared` flag
to create a C shared library (in a shared object binary file)
that can be used by C, Java, Node, Python, and Ruby code.

For more detail see
<https://medium.com/learning-the-go-programming-language/calling-go-functions-from-other-languages-4c7d8bcc69bf>.

## Executing Shell Commands

Go can execute shell commands using the standard library package `os/exec`.
Note that this may not work in Windows
and does not work in "The Go Playground".

Executing a shell command in this way
does not create a system shell
and does not expand glob patterns.
To get this functionality,
use a command that starts a shell like `bash`.

The `Command` function takes a command name and arguments
and returns a struct describing the command.
This struct has many methods including:

- `Output`\
  runs a command, waits for it to complete, and returns a byte array
  containing everything the command writes to stdout
- `CombinedOutput`\
  runs a command, waits for it complete, and returns a byte array
  containing everything the command writes to stdout and stderr
- `Run`\
  runs a command, waits for it to complete,
  but doesn't capture what it writes to stdout or stderr
- `Start`\
  method runs a command, but doesn't wait for it to complete,
  and doesn't capture what it writes to stdout or stderr;
  use the methods `StdinPipe`, `StdoutPipe`, and `StderrPipe` with this
- `Wait`\
  wait for a command that was started with the `Start` method to complete

For example,

```go
package main

import (
  "fmt"
  "log"
  "os/exec"
)

func main() {
  date, err := exec.Command("date").Output()
  if err != nil {
    log.Fatal(err)
  }
  fmt.Printf("date = %s\n", date) // date = Fri Aug  3 13:32:22 CDT 2018
}
```

## Internet of Things (IOT) Support

The community package GOBOT at <https://gobot.io/>
supports many platforms including
Arduino, Beaglebone, Intel Edison, MQTT, Pebble, and Raspberry Pi.

## Popular Go Packages

- **Bolt** <https://github.com/boltdb/bolt>\
  "An embedded key/value database for Go."

- **Buffalo** web framework <https://gobuffalo.io/en>`
  "Buffalo is a Go web development eco-system.
  Designed to make the life of a Go web developer easier.

  Buffalo starts by generating a web project for you that
  already has everything from front-end (JavaScript, SCSS, etc...)
  to back-end (database, routing, etc...) already hooked up
  and ready to run. From there it provides easy APIs to
  build your web application quickly in Go."

- **CockroachDB** <https://www.cockroachlabs.com>`
  "the open source, cloud-native SQL database"

- **Kubernetes** <https://kubernetes.io/>\
  "an open-source system for automating deployment, scaling,
  and management of containerized applications"

- **mongo-go-driver** <https://github.com/mongodb/mongo-go-driver>`
  "MongoDB Driver for Go"

- **Testify** testing library <https://github.com/stretchr/testify>\
  "A toolkit with common assertions and mocks
  that plays nicely with the standard library"

## GopherJS

GopherJS compiles Go code to JavaScript.
See <https://github.com/gopherjs/gopherjs>.
To try it online, browse
<https://gopherjs.github.io/playground/>.

## Missing Features

Currently the primary missing features in Go include:

- package version management

  An experimental approach based on vgo is included in Go 1.11.
  Feedback is being gathered now and
  perhaps this will be finalized in Go 1.12.

- generics

  Generic types are needed for truly functional programming
  so generic functions like `map`, `filter`, and `reduce`
  can be implemented.
  Generics are on the road map for Go 2.0.

- immutable data types

  Immutable data types are needed to provide
  guarantees that prevent accidental data mutations.
  This has come to be an expected feature
  in functional programming languages.

- concise function definitions

  Go lacks support for function shorthand syntax like arrow functions.
  These are especially useful for simple callback functions
  that are passed to other functions.
  Arrow functions have come to be an expected feature
  in functional programming languages.

## Annoyances

There are several features or lack of features in Go
that I find somewhat annoying. These include:

- tabs

  The `gofmt` code formatting tool uses tabs for indentation.
  This makes it difficult to print code with reasonable indentation
  because printers use eight spaces for tabs.

- no single-line `if` statements

  Simple statements like `if temperature > 100 return`
  must be written in a way that takes up three lines.

  ```go
  if temperature > 100 {
    return
  }
  ```

- no ternary operator

  Rather than writing a line like
  `color := temperature > 100 ? "red" : "blue"`
  we must write something like the following:

  ```go
  var color
  if temperature > 100 {
    color = "red"
  } else {
    color = "blue"
  }
  ```

  One reason the ternary operator is not supported
  is that it is easily abused.  In languages that support
  the ternary operator it is not uncommon to see
  deeply nested uses that are difficult to understand.
  However, `gofmt` could format nested ternaries
  in a way that is easy to read.

- no destructuring

  Go does not support destructuring of arrays, slices, or structs.

  Consider the following JavaScript code that uses array destructuring.

  ```js
  const colors = ['red', 'green', 'blue'];
  const [color1, color3] = colors;
  ```

  In Go must be written like:

  ```go
  colors := []string{"red", "green", "blue"}
  color1 := colors[0]
  color3 := colors[2]
  ```

  Consider the following JavaScript code that uses object destructuring.

  ```js
  const address = {
    street: '123 Some Street',
    city: 'Somewhere',
    state: 'MO',
    zip: 63304
  };
  const [city, zip] = address;
  ```

  In Go must be written like:

  ```go
  address := Address{ // assumes an Address type
    street: '123 Some Street',
    city: 'Somewhere',
    state: 'MO',
    zip: 63304
  };
  city := address.city // repeats the name
  zip := address.zip // repeats the name
  ```

- no generic types (described in the "Not Functional" section)

- `golint` uppercase acronyms

  Many programming languages use a convention where acronyms in
  variable and function names have only the first letter capitalized.
  For example, a name containing "is", "JSON", "or", and "XML"
  would be written as `isJsonOrXml`.

  The `golint` tool wants all acronyms it recognizes to be all uppercase.
  So this name would be `isJSONOrXML`.
  This is especially bad when there are consecutive acronyms in a name.

  The `golint` tool recognizes almost 40 acronyms.
  For a list of them, search for `commonInitialisms` at
  <https://github.com/golang/lint/blob/master/lint.go>.

- `GOPATH` environment variable

  This must be changed when switching between projects
  unless the module support introduced in Go 1.11 is used.

- comma required after last struct field

  In struct values, a comma is required after the last field
  if the closing brace is on a new line. For example,

  ```go
  address := Address{
    street: "123 Some Street",
    city:   "Somewhere",
    state:  "MO",
    zip:    "63304", // note the comma here
  },
  ```

## Modules

Lack of support for package versioning was a major issue in Go
before version 1.11.  The leading contenders were
vgo from Russ Cox at <https://github.com/golang/go/wiki/vgo>
and dep from Sam Boyer at <https://golang.github.io/dep/>.

Go 1.11 includes experimental support for "modules" that is mostly based on vgo.
This eliminates the need to have code under GOPATH
and adds support for dependency versioning.

A module is defined by a directory referred to as "module root"
that contains a `go.mod` file and a set of source files.
While `go.mod` can be created and updated manually,
there is no need to do either.

The easiest way to create `go.mod` for a new module
is to cd to its module root and run `go mod init {module-name}`
where module-name is the import path other modules will use to import this one.
Typically this is a GitHub path such as `github.com/mvolkmann/mymodule`,
but can be a simple name for modules that will not be published.

After running `go mod init github.com/mvolkmann/mymodule`,
the content of `go.mod` will be:

```go
module github.com/mvolkmann/mymodule
```

The easiest way to add dependencies to `go.mod` is to
create source files that contain `import` statements
for the dependencies and run a `go` command
such as `go build`, `go test`, `go list`, or `go vet`.
These trigger a lookup of all the dependencies.
The results are used to update `go.mod`.

### Semantic Versioning

Go modules prefer the use of semantic versioning where version numbers
have three parts referred to as major, minor, and patch.
For example, "1.2.3" represents a major version of 1,
a minor version of 2, and a patch version of 3.
The patch number is incremented when backward-compatible bug fixes are made.
The minor number is incremented when backward-compatible new features are added.
The major number is increment when incompatible changes are made.

### Simple Example

Create a new directory anywhere (except under GOPATH)
with any name and cd to the directory.
Enter `go mod init mymodule`.
Note that a GitHub path is not specified because
we are not planning to share this module with others.

Create the file `main.go` with the following content:

```go
package main

import (
  "fmt"

  "github.com/ttacon/chalk"
)

func main() {
  fmt.Printf("%s%s%s\n", chalk.Magenta, "So pretty!", chalk.Reset)
}
```

The code above imports a single community package
that is not yet listed in `go.mod`.
To build this application and update `go.mod` with dependency information,
enter `go build`.  This creates the executable file `mymodule`.
It also adds the following to `go.mod`:

```go
require github.com/ttacon/chalk v0.0.0-20160626202418-22c06c80ed31
```

The version string that follows the dependency path will be explained later.

Running `go build` also creates the file `go.sum`
which stores checksum information for all dependencies.
See the section "Checksum" below.

### Module code layout

There is no requirement to have a `src` directory in the module root.
For simple modules, all the source files can be in the module root directory
along with the `go.mod` file.
For modules defined by a large set of source files,
the files can be organized in subdirectories as desired,
typically to indicate sets of related files.

### Dependency Source Code

The source files for dependencies are not stored in
the module root directories of modules that use them.
Instead they are stored in `$GOPATH/pkg/mod`.
This allows multiple modules to share them.

Multiple versions of each dependency can be stored here.
This allows the modules that depend on them to use different versions.

### Explicit Installs

It is also possible to install dependencies with `go get`.
This updates `go.mod`, but adds the comment `// indirect`
after the path for the new dependency.
This indicates that no code in the current module
has been seen yet that uses the dependency.

These "indirect" comments are removed
after uses of the dependencies are added to source files
in the module and a command such as `go build` is run.
Since such commands add dependencies to `go.mod` on their own
and they will be run eventually,
it is not necessary to use `go get` to install dependencies.

The primary reason to use `go get` with modules
is to specify a specific version to be installed.
Alternatively once some version is installed,
perhaps by running `go build`,
the version to use can be modified by editing `go.mod`
and running the command again.

Changing the version of a direct dependency can
change the versions of its dependencies that are used.
This is desirable since a specific version of a direct dependency
may only work with specific versions of its dependencies.

### Releasing New Module Versions

Major versions of 0 or 1 are considered unstable.
Major versions that are 2 or higher are considered stable.

To release a new unstable version of a module to GitHub
it is only necessary to push changes and
add a tag following the pattern "v{major}.{minor}.{patch}".

To add a tag from the GitHub web UI,
click the "releases" tab,
press the "Draft a new release" button,
enter the tag name,
optionally enter a title and description,
check "This is a pre-release" if not considered stable,
and press the "Publish release" button.

To add a tag from the command-line,
enter `git tag {tag-name}`
and `git push origin {tag-name}`.

To release a new stable version of a module (major version 2 or higher),
modify the module name in `go.mod` to end with the major version.
For example `module github.com/mvolkmann/mymodule/v2`.
Then push and tag this change along with other changes.

In other modules that wish to use this module,
unstable versions can be imported without specifying the major version.
For example, `import github.com/mvolkmann/mymodule`.
The latest version that is less than v2 will be used.

To use a stable version, add the major version to import paths
in all source files that import it.
For example `import github.com/mvolkmann/mymodule/v2`.
Note that only the major version is specified,
not the minor or patch version.
This is referred to as "semantic import versioning".
Presumably there will be tooling to automate this in the future.

Since each version is stored separately, it is possible to use
multiple major versions of a dependency in the same application.

### Using Module Versions

The actual versions of dependencies that are used
is determined based on what is found in `go.mod`.
There are several ways to specify a version, called "module queries".
To add a module query to a require path,
add a space and one of the following after the path.

Module Query Type    | Example    | Notes
-------------------- | ---------- | -------------------------
fully-specified      | v1.2.3     |
major version prefix | v1         | latest starting with v1
minor version prefix | v1.2       | latest starting with v1.2
version comparison   | >=v1.2.3   | can also use >, <, and <=
latest               | latest     |
commit hash          | A1B2C3D    |
tag                  | my-tag     |
branch name          | my-branch  |

In all cases but using a fully-specified version,
running a command such as `go build` finds a matching version
and updates `go.mod` with the result.
This means that each time a new dependency version is desired,
`go.mod` must be updated.
Specifying a version like "v2" will not automatically get the
latest version that starts with "v2" every time `go build` is run
since "v2" will be replaced by an actual version.

Sam Boyer is the lead maintainer of Dep, a dependency management tool for Go.
He feels that this feature of Go modules loses information
about the minimum versions that were deemed compatible.
Further, he feels this makes it hard to resolve diamond-shaped
dependencies where multiple modules needed by an app
depend on different minor versions of some other module.
See his talk "We need to talk about Go modules" at
<https://www.youtube.com/watch?v=7GGr3S41gjM&feature=youtu.be&t=14m55s>.

No automatic version updates are ever performed.
This means that checking `go.mod` files into a version control repository
provides a way to produce repeatable builds.

"Version comparison" gets the nearest version to what is requested,
not the latest version that matches.  For example, if the query is ">=1.2.3"
and the existing versions include 1.2.2, 1.2.3, and 1.2.4,
this will use version 1.2.3.

### Pseudo Versions

For dependencies that do not currently use semantic versioning,
an alternate way to determine whether
one version is later than another is needed.
Pseudo versions provide this.

Pseudo versions are strings that have three parts.
The first is a version in the form "v{major}.{minor}.{something}".
The second is the commit time in UTC.
The third is the first 12 characters of the commit hash.
These parts are separated by dashes.

The "something" in the first part is a bit complicated.
Fortunately it's not necessary to think about this
because pseudo version strings are automatically generated
when dependencies that lack semantic versioning tags are installed.

### Other `go.mod` Directives

Besides the `module` and `require` directives,
`go.mod` files can also contain
`exclude` and `replace` directives.
`exclude` directives specify versions of dependencies that cannot be used.
`replace` directives specify versions of dependencies
that should be replaced by another version.
These can be specified to avoid using versions that have
known bugs or security issues.

### Tidying `go.mod` Files

Over time the list of dependencies in a `go.mod` file can become out of date.
It might be missing some required dependencies or
list dependencies (or versions of them) that are no longer used.
The command `go mod tidy` adds missing dependencies
and removes unused dependencies from `go.mod`.

Of course many other commands such as `go build`
take care of adding missing dependencies,
so the primary purpose of `go mod tidy`
is to remove unused dependencies.

### Checksums

Go modules use checksums to verify that the downloaded code
for their dependencies have not been modified.
The checksum for each dependency is stored in the file `go.sum`.
The command `go mod verify` reports all directories that hold
downloaded module code and contain files that have been modified.

### Proxies

It is possible to configure a proxy server that hosts Go modules
so they are installed from there instead of
connecting to public source control repositories.
One reason to do this is to restrict access
to only modules that have been vetted.

A Go proxy server is a web server that
responds to GET requests for module URLs.
To use one, set the `GOPROXY` environment variable
to point to the server.

For more information, enter `go help goproxy`.

### Transition to Module Support

In Go 1.11 it is possible to use both the old GOPATH approach
to dependencies and the new module approach.
The environment variable `GO111MODULE` specifies whether
one or both of these approaches should be allowed.
When set to "off", only GOPATH can be used.
When set to "on", only modules can be used.
When set to "auto" or not set, either can be used
and the choice is based on whether commands are run from a directory
that contains a `go.mod` file or a descendant of such a directory.

If you have existing code that relies on GOPATH and
you want to try module support in some new or existing packages,
not setting `GO111MODULE` is a good option.

## Summary

TODO: Write this.

## Resources

There are many Go resources on the web,
but these are some of the most important,
listed roughly in the order they should be visited.

- "A Tour of Go": <https://tour.golang.org/>
  - built on "The Go Playground"
  - can use on web or download and run locally
  - when used on web
    - uploads code to golang.org servers and displays result
    - uses latest stable version of Go
- "The Go Playground": <https://play.golang.org/>
  - can enter and test code online
  - can share code with others, but not sure how long they are retained
- "The Go Play Space" at <https://goplay.space/>
  - a better alternative to "The Go Playground"
  - provides syntax highlighting, configurable indentation,
    use of Fira Code font, auto-indenting, help on double-click,
    ability to highlight lines (useful when sharing snippets),
    and more
- "How to Write Go Code": <https://golang.org/doc/code.html>
  - free, online resource
  - "demonstrates the development of a simple Go package and introduces the go tool"
- "Effective Go": <https://golang.org/doc/effective_go.html>
  - free, online "book"
- "The Go Programming Language Specification": <https://golang.org/ref/spec>
- golang.org articles: <https://golang.org/doc/#articles>
  - a curated list of articles about Go
- GoDoc: <https://godoc.org>
  - "hosts documentation for Go packages on Bitbucket, GitHub,
    Launchpad and Google Project Hosting"
  - can search for packages by import path or keyword and see their documentation
- Awesome Go: <https://awesome-go.com>
  - "A curated list of awesome Go frameworks, libraries and software"
- Go Walkthrough: <https://medium.com/go-walkthrough>
  - "A series of walkthroughs to help you understand the Go standard library better"
  - seems to have stopped after seven, with the last in September 2016
- Gophers Slack channel: <https://invite.slack.golangbridge.org/>
- #go-nuts channel on the Freenode IRC server
  - for real-time help
- Go Nuts mailing list: <https://groups.google.com/forum/#!forum/golang-nuts>
  - official mailing list
- golang-announce mailing list:
  <https://groups.google.com/forum/#!forum/golang-announce>
  - subscribe to receive emails about major events in Go such as new releases
- "Go Time" podcast: <https://changelog.com/gotime>
- Golang Weekly: <https://golangweekly.com/>
  - "a weekly newsletter about the Go programming language"
- GopherCon 2015: Robert Griesemer - The Evolution of Go:
  <https://www.youtube.com/watch?v=0ReKdcpNyQg>
