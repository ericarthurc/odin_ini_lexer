# Odin INI Parser

There is an example in the example folder that shows reading a file, parsing the file into a map, and returning it as a JSON string.

It turns this .ini file:

```ini
here:now
[food]
fun=sun
burger:"cheese"
'hello'=world
;comment here
[section]
#comment 2
foo=bar
```

into this JSON string (order is not guaranteed):

```json
{
  "global": { "here": "now" },
  "section": { "foo": "bar" },
  "food": { "fun": "sun", "burger": "cheese", "hello": "world" }
}
```

### Information:

This is a very simple INI parser that tokenizes a .ini file and parses it to a map returned as JSON.

This has no error handling and probably doesn't handle any edge cases.

It is written in a way to take your own allocator if you want, but the allocator based in will allocate the file data, the created map and the json string. The example folder shows passing in an arena allocator.

This was not meant to be used as a library or package, but was written somewhat in that way. No procedures are marked with private but this should be treated more for educational and studying purposes.

This was my first attempt at a lexer/parser with manual memory management and was used for studying these concepts in Odin.
