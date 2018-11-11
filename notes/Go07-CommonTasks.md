## Common Tasks

## Command-Line Arguments

Command-line arguments are held in
a slice of strings stored in `os.Args`.

Index 0 holds the path to the executable.
When `go run` is used, an executable is created dynamically.

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
    // TODO: Should you use a different function that
    // TODO: writes to stderr and sets the status?
    log.Fatal("usage: greet {first-name} {last-name}")
  }

  firstName := args[0]
  lastName := args[1]
  fmt.Printf("Hello %s %s!\n", firstName, lastName)
}
```

To run this, enter `go run greet.go Mark Volkmann`.

To build an executable and run it,
enter `go build greet.go; ./greet Mark Volkmann`

## Flags

The `flags` package supports documenting and parsing
command-line flags for an application.
Each flag is described by a type, name,
default value, and documentation string.
The type can be any builtin primitive type
or a user-defined type (using `flag.Var`).

For example, here is a simple application
in a file named `flag-demo.go` that outputs a
range of integer values with a given string prefix.

```go
package main

import (
  "flag"
  "fmt"
)

// These pointers will be set after flag.Parse is called.
// There are flag functions for all the primitive data types.
var minPtr = flag.Int("min", 1, "minimum value")
var maxPtr = flag.Int("max", 10, "maximum value")
var prefixPtr = flag.String("prefix", "", "prefix")

func main() {
  flag.Parse(
  // TODO: If dereferencing prefixPtr was done in each
  // TODO: loop iteration, would Go optimize it out?
  prefix := *prefixPtr
  for i := *minPtr; i <= *maxPtr; i++ {
    fmt.Printf("%s%d\n", prefix, i)
  }
}
```

To build this, enter `go build`.

To get help on the flags,
enter `./flag-demo --help` which outputs:

```text
Usage of ./flags:
  -max int
        maximum value (default 10)
  -min int
        minimum value (default 1)
  -prefix string
        prefix
```

Flag names are preceded by a single dash,
followed by `=` or a space, and a value.

To run this, enter one of the following lines:

```text
./flag-demo -min 3 -max 5 -prefix foo
./flag-demo -min=3 -max=5 -prefix=foo
```

both of which output

```text
foo3
foo4
foo5
```

TODO: Discuss any type checking that is performed on the values.

## Readers

The `io` package defines the `Reader` interface
that has a single method `Read`.
This reads from an underlying data stream,
populates a byte slice, and
returns the number of bytes read or an error.
For example, the error is io.EOF
if the end of a stream is reached.

There are many implementations of this interface in the standard library,
including ones for reading from strings, files, and network connections.

To read from a string, see <https://tour.golang.org/methods/21>.

One way to read from a file is to use the package `io/ioutil`
which defines a `ReadFile` function.
This reads the entire file in one call.

For example:

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
  }

  fmt.Println(string(bytes))
}
```

When there is an attempt to read past the end of a stream,
an `io.EOF` error is returned.
Some ways of reading from a stream check for this
so the error is never generated.
For example, a "scanner" can be used to
read the lines in a file one at a time.

```go
package main

import (
  "bufio"
  "fmt"
  "log"
  "os"
)

func main() {
  // Get an os.File which implements the io.Reader interface
  // by having a Read method.
  file, err := os.Open("haiku.txt")
  if err != nil {
    log.Fatal(err)
  }
  defer file.Close()

  scanner := bufio.NewScanner(file) // takes an io.Reader
  for scanner.Scan() { // returns true if another line was read
    fmt.Println(count, scanner.Text())
  }

  // Check for any errors from the calls to Scan and Text.
  if err := scanner.Err(); err != nil {
    log.Fatal(err)
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

The package `io/ioutil` defines a `WriteFile` function
that writes all the data to a file in a single call.

For example:

```go
package main

import (
  "io/ioutil"
  "log"
)

func main() {
  // Convert a string to a byte slice.
  data := []byte("Line #1\nLine #2")
  mode := os.FileMode(0644) // TODO: Add comment?
  err := ioutil.WriteFile("new-file.txt", data, mode)
  if err != nil {
    log.Fatal(err)
  }
}
```

To write data a little at time,
use the `os.File` `Write` method.
For example:

```go
package main

import (
  "fmt"
  "log"
  "os"
)

func check(err error) {
  if err != nil {
    log.Fatal(err)
  }
}

func writeLine(file *os.File, text string) {
  bytes, err := file.Write([]byte(text + "\n"))
  check(err)
  fmt.Printf("wrote %v bytes\n", bytes)
}

func main() {
  // TODO: Why declare these variables? Just use :=?
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

## JSON

The `encoding/json` standard library package
supports marshalling and unmarshalling of JSON data.
Go arrays and slices are represented by JSON arrays.
Go structs and maps are represented by JSON objects.

The `encoding/xml` standard library package
provides similar functionality for XML.

To marshal data to JSON use the `json.Marshal` function.
This takes a Go value and returns a byte slice
that can be converted to a string with the `string` function.
Only exported struct fields are marshaled.
For example,

```go
import (
  "encoding/json"
  "fmt"
  "os"
)

type Person struct {
  FirstName string
  LastName string
  Age int
  height int
}

func main() {
  p := Person{FirstName: "Mark", LastName: "Volkmann", height: 74}
  json1, err := json.Marshal(p)
  if err != nil {
    log.Fatal(err)
  }
  fmt.Println(string(json1)) // {"FirstName":"Mark","LastName":"Volkmann","Age":0}
}
```

Some Go values cannot be marshaled to JSON. These include
maps with non-string keys, functions, and channels.
Pointers are marshaled as the values to which they point.
Cyclic data structures cannot be marshaled because
they cause `json.Marshal` to go into an infinite loop.

Here is an example of marshalling a slice of structs.

```go
people := []Person{
  Person{FirstName: "Mark", LastName: "Volkmann", Age: 57},
  Person{FirstName: "Tami", LastName: "Volkmann"},
}
json2, err := json.Marshal(people)
// skipping err check
fmt.Println(string(json2))
// [{"FirstName":"Mark","LastName":"Volkmann","Age":57},{"FirstName":"Tami","LastName":"Volkmann","Age":0}]
```

Each struct field definition can be followed by a "field tag"
which is a string containing metadata.
These provide information about how a field
should processed in a specific context.

A field tag with a "json" key specifies processing
that should be performed by the `encoding/json` package.
This includes specifying an alternate name for a field
to be used in the JSON representation, and an option to
omit the field if its value is the zero value for its type.
For example:

```go
type Person2 struct {
  FirstName string `json:"name"`
  LastName  string `json:"surname"`
  Age       int    `json:"age,omitempty"`
}

p2 := Person2{FirstName: "Mark", LastName: "Volkmann"}
json3, err := json.Marshal(p2)
// skipping err check
fmt.Println(string(json3)) // {"name":"Mark","surname":"Volkmann"}
```

To unmarshal data from JSON use the `json.Unmarshal` function.
The first argument is a byte slice representing a JSON string.
The second argument is a pointer to a
struct, map, slice, or array to be populated.
Only exported struct fields are populated.
For example,

```go
var p3 Person
err = json.Unmarshal(json1, &p3)
// skipping err check
fmt.Printf("%+v\n", p3) // {FirstName:Mark LastName:Volkmann Age:0}
```

Properties present in the JSON, but absent in a target struct are ignored.
This is determined by case-insensitive name matching.
It allows unmarshaling a selected subset of the JSON data.
For example,

```go
type PersonSubset struct {
  LastName string
}
var pSubset PersonSubset
err = json.Unmarshal(json1, &pSubset)
// skipping err check
fmt.Printf("%+v\n", pSubset) // {LastName:Volkmann}
```

A JSON object can be unmarshaled into a Go map.
When the JSON property values have a variety of types,
it is useful to use a map with string keys and values of type `interface{}`
which can hold any kind of value.
Unmarshaling from JSON types to Go types produce what would be expected
and include mapping JSON numbers to Go float64 values.

This approach can also be used to unmarshal a JSON array
of arbitrary JSON objects. For example,

```go
type MyMap map[string]interface{}
mySlice := []MyMap{}
err = json.Unmarshal(json2, &mySlice) // see value for json2 above
// skipping err check
fmt.Printf("myMap = %+v\n", mySlice)
// [map[FirstName:Mark LastName:Volkmann Age:57] map[Age:0 FirstName:Tami LastName:Volkmann]]
```

The `encoding/json` package also provides the ability to
encode and decode streams of JSON data one object at a time.
This allows creation of JSON that is larger than will fit in memory.
It also allows processing JSON data as it is decoded
rather than waiting until the entire stream is decoded.

## Text Templates

Go text templates support creating complex strings.
They provide a much more powerful alternative to the `fmt.Sprintf` function
which works fine for simple cases.

Text templates embed "actions" that are enclosed in double curly braces.
It's like a mini programming language for
creating multi-line strings that embedded data
obtained from a Go data structure.

Templates are supported by two standard library packages,
`text/template` and `html\template`.

Using templates is a multi-step process.

To create a template, call `template.New` which takes a template name
that can be used to embed the template inside other templates.
For example, `myTemplate := template.New("template name")`.

To add content to a template from a string, call the `Parse` method on it.
For example, `myTemplate, err := myTemplate.Parse(content)`.

To add content to a template from a file, call the `ParseFiles` method on it.
For example, `myTemplate, err := myTemplate.ParseFiles(filePath1, filePath2, ...)`.
Reading from more than one file supports
having templates that embed other templates.

The steps to create a template and add content can be combined.
For example,

```go
myTemplate, err := template.New("template name").Parse(content)
```

To avoid the need to check for errors and panic if there is one,
pass the result of calling `New` and `Parse` to `template.Must`.
For example,

```go
myTemplate := template.Must(template.New("template name").Parse(content))
```

To produce a string by applying a template
to data in a struct, a map, or
the result of a given function that takes no arguments.
call the `Execute` method on the template,
passing it a pointer to a `bytes.Buffer` and the data.
The result is written to the buffer.
For example,

```go
var buf bytes.Buffer // implements the io.Writer interface
err = myTemplate.Execute(&buf, data)
```

To write the result of applying a template to stdout,
pass `os.Stdout` in place of a `bytes.Buffer`.
For example, `err = myTemplate.Execute(os.Stdout, data)`.

The data structure passed to `execute`
can be accessed in the template using a dot (`.`).
Fields of structs and maps can be accessed by name after a dot.

If a function is passed to `execute`,
it can be called by using `call .` in an action.

For example, supposed the data is a struct with the following type definition.

```go
type Person struct {
  Name string
  Address struct {
    Street string
    City string
  }
}
```

To output the name, use `{{.Name}}`.
To output the city, use `{{.Address.City}}`.

Template actions can set variables,
conditionally include content, loop over data,
and indicate whether whitespace should be trimmed.

Variable names start with a dollar sign.
They are useful to capture the result of
a complex pipeline (described below)
so it can be reused without recalculating.
To set a variable, `{{$name := value}}`.
To output the value of a variable, use `{{$name}}`.

A pipeline is a sequence of one or more commands.
This is similar to shell script pipes.
It allows the results of functions and methods
to be used as the final argument in
a call to another function or method.

A command is simple value, function call, or method call.

Simple values include primitive values and variables.
They also include many expressions that begin with a dot (`.`)
which represents the value at the current cursor.
When the value at the cursor is a struct,
the dot can be followed by a field name.
When the value at the cursor is a map,
the dot can be followed by a key.
When the value at the cursor has methods,
the dot can be follow by the name of a method that has no parameters.

Chaining is supported by using multiple dots.

A function call is a function name followed by
a space-separated list of arguments
that are simple values.
This means that dot expressions can be used as arguments
in order to pass input data to functions.

A method call is similar a function call.
To call a method using the cursor value as the receiver,
begin with a dot, followed by a method name
and a space-separated list of arguments.
To call a method on an explicit receiver,
begin with the receiver, followed by a dot,
the method name, and the arguments.

To conditionally include content,

```go
{{if pipeline}}
  true-content
{{else}}
  false-content
{{end}}
```

To iterate over data in an array, slice, or channel,

```go
{{range pipeline}}
  content
{{end}}
```

To refer to the current iteration value inside the content,
use dot.

To iterate over data in a map,

```go
{{range $key $value := pipeline}}
  content
{{end}}
```

The variables `$key` and `$value` can have different names
and they can be accessed by actions inside the content.

It's tricky business trying to get the desired whitespace in the output.
Tools like gofmt may replace spaces in template content with tabs,
so trimming and the use of literal spaces is sometimes necessary.
This is one reason to read template content from a file
instead of embedding it in `.go` source files.

To trim preceding whitespace, begin an action with `{{-`.
To trim following whitespace, end an action with `-}}`.

Templates support a set of predefined functions
that can be called in actions.

Logical functions that can be used in templates
include `and`, `or`, and `not`.

Comparison functions that can be used in templates
include `eq`, `ne`, `lt`, `le`, `gt`, and `ge`.

Printing functions that can be used in templates
include `print`, `printf`, and `println`.

The `len` function returns the length of its argument.

The `call` function calls the function specified in its first argument,
passing the remaining arguments to it, and returns its result.
This is useful when a function name is specified in the data being processed.

The `html` function returns the escaped version of its
string argument that is suitable for HTML output.

The `urlquery` function returns the escaped version of its
string argument that is suitable for using in a URL query.

The `js` function returns the escaped version of its
string argument that is suitable for JavaScript code output.

The `index` function retrieves a value from a nested structure
composed of arrays, slices, and maps. For example,
suppose the data being processed is in a variable named `data`.
`index .foo 2 "bar" 3` in a template action is equivalent to
`data.foo[2]["bar"][3]` in Go code.

To call custom functions inside a template, they must be
registered with the template by calling the `Funcs` method.
This takes a `FuncMap` which is a map
where keys are string function names
and the values are matching functions.

Let's look a full example.
Given data describing a person including their
salary, favorite colors, points scored in a game,
and favorite athletes,
we want to produce output like the following:

```text
The favorite colors of Mark Volkmann are
  red
  yellow
  orange
The longest color name is yellow.

Salary doubled = 2468
Total Points = 34

Favorite Players
  basketball: Michael Jordan
  hockey: Wayne Gretzky
  tennis: Roger Federer
```

Here is a template for creating this output
from a file named `template.txt` that is in
the same directory as the Go code that follows:

```text
{{$longest := "foo"}}
The favorite colors of{{" "}}
{{- .FirstName}} {{.LastName}} are
{{- range .Colors}}
  {{- if gt (len .) (len $longest)}}
    {{- $longest = .}}
  {{- end}}
{{.}}
{{- end}}
The longest color name is {{$longest}}.

Salary doubled = {{double .Salary}}
Total Points = {{.PointsPerQuarter | sum}}

Favorite Players
{{range $sport, $player := .Players}}
  {{- "  "}}{{$sport}}: {{$player}}
{{end}}
```

In this example,
`{{double .Salary}}` is equivalent to `{{.Salary | double}}` and
`{{sum .PointsPerQuarter}}` is equivalent to `{{.PointsPerQuarter | sum}}`.

Here is Go code to use this template:

```go
package main

import (
  "fmt"
  "os"
  "text/template"
)

// Person describes a person.
type Person struct {
  FirstName        string
  LastName         string
  Salary           int
  PointsPerQuarter []int
  Colors           []string
  Players          map[string]string
}

func main() {
  person := Person{
    FirstName:        "Mark",
    LastName:         "Volkmann",
    Salary:           1234,
    PointsPerQuarter: []int{10, 0, 7, 17},
    Colors:           []string{"red", "yellow", "orange"},
    Players: map[string]string{
      "basketball": "Michael Jordan",
      "hockey":     "Wayne Gretzky",
      "tennis":     "Roger Federer",
    },
  }

  // These are functions we want to make available
  // for use inside the template.
  funcMap := template.FuncMap{
    "double": func(n int) int { return n * 2 },
    "sum": func(numbers []int) int {
      result := 0
      for _, n := range numbers {
        result += n
      }
      return result
    },
  }

  fileName := "template.txt"
  myTemplate := template.Must( // panics on errors
    template.
      New(fileName).
      Funcs(funcMap).
      ParseFiles(fileName))

  err = myTemplate.Execute(os.Stdout, person)
  if err != nil {
    fmt.Fprintln(os.Stderr, err)
  }
}
```

Using `html/template` package has the same API as the `text/template` package,
but adds escaping of strings to avoid injection attacks.

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

## Buffalo

Buffalo is a tool and a framework for building web applications using Go.

To install Buffalo, see the instructions at
<https://gobuffalo.io/en/docs/installation>.
To verify the installation, enter `buffalo`.
This should display help on using it.

On a Mac, Buffalo can be installed using Homebrew
by running the command `brew install gobuffalo/tap/buffalo`.

### Creating a Project

To create a new project, enter `buffalo new {project-name}`.
This downloads many files and create a directory structure
for the project. It will run for about two minutes.

Add the `--api` flag to the `new` command
to omit front-end code and create a project
that is focused on implementing REST services.

Add the `--skip-pop` flat to the `new` command
to omit code for connecting to a relational database.

### Databases

Buffalo uses the "pop" package to perform CRUD operations
on relational database tables. It also supports
schema migrations similar to Ruby's ActiveRecord.

Buffalo supports for databases. These are
PostgreSQL, MySQL, SQLite3, and CockroachDB.

The database configuration is specified in the file
`database.yml` which is the root project directory.
There are three sections in this file that describe
the "development", "test", and "production" environments.
By default it attempts to connect to a PostgreSQL database
named `{project-name}_{environment}` with
a username of "postgres" and a password of "postgres".

### Starting Server

Before starting the server for the first time
you must choose from these options:

1. create the database specified in `database.yml`
1. modify `database.yml` to refer to an existing database
1. comment out the following line in `actions/app.go`
   that wraps each request in a database transaction:\
    `app.Use(popmw.Transaction(models.DB))`

To start the application in development mode
cd to the new project directory and enter `buffalo dev`.
By default this starts a server that listens
for requests on port 3000.
It also watches files for changes and
automatically rebuilds and restarts the server.
It does not provide live reload of the browser out of the box,
but perhaps there is a way to get this.
See <https://github.com/gobuffalo/buffalo/issues/510>.

Browse `localhost:3000` to see the app.
To use a different port, say 1234,
enter `PORT=1234 buffalo dev`.
This should render the following:
![Buffalo default page](go-buffalo-default-page.png)

### Directory Structure

The directory structure created by `buffalo new`
is described below.

- project root
  - `database.yml` defines database configuration
  - `main.go` is the application starting point
  - `actions` directory defines the controller portion of MVC
    - `app.go` configures the application and URL routes
    - `render.go` configures the template engine
  - `assets` directory\
    This directory contains assets that will be compiled,
    compressed, and copied to the `public` directory.
    It can be removed for API-only projects.
    - `css` directory
    - `images` directory
    - `js` directory
  - `fixtures` directory
  - `grifts` directory contains tasks for grift which is a task scripting tool similar to Ruby's Rake.
  - `locales` directory holds language translation strings
  - `models` directory maps database tables to Go structs for ORM capabilities (see pop/soda); model portion of MVC
  - `node_modules` directory contains Node.js modules downloaded from npm
  - `public` directory contains generated asset files and should not be manually modified
    - `assets` directory
      - `images` directory
  - `templates` directory contains view templates; view portion of MVC
  - `tmp` directory holds temporary files generated during project rebuilds

### Environment Variables

The most important environment variables used by Buffalo are the following:

`GO_ENV` defines the environment in which the server should run.
It defaults to "development", but can also be set to "test" or "production".

`ADDR` defines the server address.
It defaults to an IP address for localhost.

`PORT` defines the port on which the server listens.
It defaults to 3000.

`HOST` is a combination of `ADDR` and `PORT`.
It defaults to "http://127.0.0.1:3000".

To get the value of any environment variable in a running Buffalo app,
import the `github.com/gobuffalo/envy` package and call `envy.Get`.
For example, `value := envy.Get("SOME_NAME", defaultValue)`.
To return an error if the environment variable is not set,\
`value, err := envy.Get("SOME_NAME")`

The `.env` file in the project root directory
can define environment variables.
These are loaded on server startup using `envy.Load`.
This file is ignored by Git (listed in `.gitignore`)
to avoid exposing sensitive information
such as passwords and secret keys.

### Routes

Buffalo uses the `github.com/gorilla/mux` package
to handle routing.

To add a new route,

- edit `actions/app.go`
- add a call to `app.{method}`
  - method is GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD, or ANY
  - each call specifies a URL pattern and a handler function
- implement the handler function
  - must match the type `buffalo.Handler`
    which is `func (buffalo.Context) error`

Here is a "hello world" route.

```go
func helloHandler(c buffalo.Context) error {
  return c.Render(200, r.String("Hello, World!"))
}

The variable `r` is a `render.Engine` pointer
defined in the file `render.go`.

// Inside App function ...
app.GET("/hello", helloHandler)
```

If a large number of routes is needed,
related groups can be defined in new `.go` files
that are imported by `app.go`.

To get a list of all the defined routes
and the names assigned to them,
enter `buffalo routes`.

### Query Parameters

Query parameters appear after a `?` in a URL and are
specified with `name=value` pairs separated by `&` characters.
For example, `http://localhost:3000/hello?name=Tami&relation=spouse`.

To obtain query parameters in a handler function,
call the Context method `Param`.
For example, `c.Param("name")`.

### Path Parameters

Path parameters appear in URLs after the primary path
and are separated by slashes.
For example, `http://localhost:3000/hello/yellow/3`.

Routes can specify their names by surrounding them with curly braces.
For example, `app.GET("/hello/{color}/{count}", helloHandler)`.

To obtain path parameters in a handler function,
use the same method as for getting query parameter values.
For example, `c.Param("color")`.

### Route Groups

Related groups of routes that have the same URL prefix
can be specified using by creating Group objects.
For example,

```go
    sportGroup := app.Group("/sport")
    // URL is /sport/football.
    sportGroup.GET("/football", func(c buffalo.Context) error {
      return c.Render(200, r.String("Tom Brady"))
    })
    // URL is /sport/hockey.
    sportGroup.GET("/hockey", func(c buffalo.Context) error {
      return c.Render(200, r.String("Wayne Gretzky"))
    })
    // URL is /sport/name where name is anything but football or hockey.
    sportGroup.GET("/{sport}", func(c buffalo.Context) error {
      sport := c.Param("sport")
      return c.Render(200, r.String("unsupported sport "+sport))
    })
```

### Resources

Resources define a kind of data that
supports CRUD operations on a database table.
Examples include employees, addresses, and cars.

To demonstrate this, we will create a PostgreSQL database
with a table named "todos".

On a Mac, PostgreSQL can be installed by first installing Homebrew
and then entering `brew install postgresql`.

To initialize PostgreSQL:

- sudo mkdir /usr/local/pgsql
- sudo mkdir /usr/local/pgsql/data
- sudo chown Mark /usr/local/pgsql
- sudo chown Mark /usr/local/pgsql/data
- initdb -D /usr/local/pgsql/data

To create a database named "buffalo",
enter `createdb buffalo_development`.

To create the todos_development table in the buffalo database,
create the file `setup.sql` containing the following:

```sql
drop table if exists todos;
create table todos (
  id serial primary key,
  text text,
  done bool
);
```

Execute this file by entering `psql -d buffalo_development -f setup.sql`.

Resources can support a set of methods defined in the `Resource` interface.
These include `List`, `Show`, `New`, `Create`, `Edit`, `Update`, and `Destroy`.

Buffalo can generate to the code to support a resource.
For example, to generate code for a "todos" resource,
enter `buffalo generate resource todos text done:bool`.
This creates the following files:

- `actions/todos.go`
- `actions/todos_test.go`
- `modules/todos.go`
- `modules/todos_test.go`
- `migrations/{date-timestamp}_create_todos.up.fizz`
- `migrations/{date-timestamp}_create_todos.down.fizz`

To skip generating migration files, add the `--skip-migration` flag.
To skip generating model files, add the `--skip-model` flag.

Note that there was a pluralization error in the file
`models/todo.go` where the type "todos" was misspelled as "todoes".
I had to manually fix those.

Also, if the following line in `app.go` was commented out,
restore it so database operations are performed in a transaction.

```go
app.Use(popmw.Transaction(models.DB))
```

Create a user in the database by entering
`createuser {username} --password`.
This will prompt for the user password.

Edit the file `database.yml` to correct the
database name, user name, and password
for the "development" environment.

To add a row to the todos table,

### Templates

Templates can specify HTML to be rendered
and can include actions that produce dynamic content.

Templates used to render HTML can obtain data from routes.
For example, if a route name is "helloPath", use `<%= helloPath() %>`.

For routes that require parameters,
they can be passed to the route function as a literal map.
For example, `<%= helloPath({color: "yellow", count: 3}) %>`.

## Calling other languages from Go

Function definitions with no body indicate that the
function is implemented in a different programming language.

The `cgo` tool allows Go code to call C code.
For more detail, see <https://golang.org/cmd/cgo/>.

To call Java code from Go, write C code that uses
the Java Native Interface (JNI) to call Java code.

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

## Compiling to JavaScript

GopherJS compiles Go code to JavaScript.
See <https://github.com/gopherjs/gopherjs>.
To try it online, browse
<https://gopherjs.github.io/playground/>.

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
