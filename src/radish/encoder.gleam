import gleam/int
import gleam/set
import gleam/list
import gleam/float
import gleam/string
import gleam/bit_array
import radish/resp

pub fn encode(value: resp.Value) -> BitArray {
  encode_internal(value)
  |> bit_array.from_string
}

fn encode_internal(value: resp.Value) -> String {
  case value {
    resp.Nan -> nan()
    resp.Null -> null()
    resp.Infinity -> infinity()
    resp.Set(value) -> set(value)
    resp.Map(value) -> map(value)
    resp.Push(value) -> push(value)
    resp.Array(value) -> array(value)
    resp.Double(value) -> double(value)
    resp.Boolean(value) -> boolean(value)
    resp.Integer(value) -> integer(value)
    resp.BigNumber(value) -> big_number(value)
    resp.BulkError(value) -> bulk_error(value)
    resp.BulkString(value) -> bulk_string(value)
    resp.NegativeInifnity -> negative_infinity()
    resp.SimpleError(value) -> simple_error(value)
    resp.SimpleString(value) -> simple_string(value)
    resp.IntegerAsDouble(value) -> integer_as_double(value)
  }
}

fn null() {
  "_\r\n"
}

fn nan() {
  ",nan\r\n"
}

fn infinity() {
  ",inf\r\n"
}

fn negative_infinity() {
  ",-inf\r\n"
}

fn integer(value: Int) {
  ":" <> int.to_string(value) <> "\r\n"
}

fn boolean(value: Bool) {
  case value {
    True -> "#t\r\n"
    False -> "#f\r\n"
  }
}

fn simple_string(value: String) {
  "+" <> {
    value
    |> string.replace("\r", "")
    |> string.replace("\n", "")
  } <> "\r\n"
}

fn bulk_string(value: String) {
  "$" <> {
    value
    |> string.length
    |> int.to_string
  } <> "\r\n" <> value <> "\r\n"
}

fn simple_error(value: String) {
  "-" <> {
    value
    |> string.replace("\r", "")
    |> string.replace("\n", "")
  } <> "\r\n"
}

fn bulk_error(value: String) {
  "!" <> {
    value
    |> string.length
    |> int.to_string
  } <> "\r\n" <> value <> "\r\n"
}

fn big_number(value: String) {
  "(" <> value <> "\r\n"
}

fn double(value: Float) {
  "," <> float.to_string(value) <> "\r\n"
}

fn integer_as_double(value: Int) {
  "," <> int.to_string(value) <> "\r\n"
}

fn array(value: List(resp.Value)) {
  "*" <> {
    value
    |> list.length
    |> int.to_string
  } <> "\r\n" <> {
    list.map(value, fn(item) { encode_internal(item) })
    |> string.join("")
  }
}

fn map(value: List(#(resp.Value, resp.Value))) {
  "%" <> {
    value
    |> list.length
    |> int.to_string
  } <> "\r\n" <> {
    list.map(
      value,
      fn(item) { encode_internal(item.0) <> encode_internal(item.1) },
    )
    |> string.join("")
  }
}

fn push(value: List(resp.Value)) {
  ">" <> {
    value
    |> list.length
    |> int.to_string
  } <> "\r\n" <> {
    list.map(value, fn(item) { encode_internal(item) })
    |> string.join("")
  }
}

fn set(value: set.Set(resp.Value)) {
  let value = set.to_list(value)
  "~" <> {
    value
    |> list.length
    |> int.to_string
  } <> "\r\n" <> {
    list.map(value, fn(item) { encode_internal(item) })
    |> string.join("")
  }
}