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
