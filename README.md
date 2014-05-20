# rdf2json

[![Build Status](https://secure.travis-ci.org/joejimbo/rdf2json.png)](http://travis-ci.org/joejimbo/rdf2json)

Reads RDF N-Triple/N-Quads that are sorted by subject and
append a JSON/JSON-LD document per line in a designated
output file.

Usage: `rdf2json [options] --input filename.nt --output filename.json`

#### Required options

*  `-i`, `--input FILE`: Input file for the conversion; either RDF N-Triples or N-Quads.
*  `-o`, `--output FILE`: Output file to which JSON-LD/JSON is appended.

#### Options

*  `-m`, `--minimize`: Minimize JSON-LD to plain (semantically untyped) JSON.
*  `-n`, `--namespace [NAMESPACE]`: Alternative name for JSON-LD's "@id" key; replaces it; turns on `--minimize`
*  `-p`, `--prefix [PREFIX]`: Prefix that should be removed from keys; requires `--minimize`.
*  `-t`, `--triples`: Input file is in RDF N-Triples format.
*  `-q`, `--quads`: Input file is in RDF N-Quads format.

#### Common options

*  `-h`, `--help`: Show this message.

## Installation

```sh
gem install rdf2json
```

## Project home page

Information on the source tree, documentation, examples, issues and
how to contribute, see

  http://github.com/joejimbo/rdf2json

The BioRuby community is on IRC server: irc.freenode.org, channel: #bioruby.

## Biogems.info

This Biogem is published at (http://biogems.info/index.html#bio-rdf2json)

## Copyright

Copyright (c) 2014 Joachim Baran. See LICENSE.txt for further details.

