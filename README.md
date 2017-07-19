# Yaml with Line Numbers

A lil library to allow you to access the source file's line numbers while playing with parsed yaml.

## But Why?

We're using this at Braintree to help docs writers find where issues are in yaml based content (see: [reference docs](https://developers.braintreepayments.com/reference/request/transaction/sale/ruby)). If a value doesn't line up with what it should, we want to be able to tell the writer "Hey, look at line N, you're missing a colon there". Psych allows this to happen when there is a parsing error, and we want that functionality to carry through all the way to content validation.

## But How?

The stratetgy is to subclass every class that yaml can be parsed into (there aren't that many if we ignore `YAML.dump` for objects) so that in addition to all its methods, we can also call, say, String.metadata["line"] to get the line number where that string was pulled from. Why pack it into metadata and not just do `String.line`? Well there's some more metadata that we like to store so that's the implementation I wrote! Maybe I'll change it later. Who knows.
