# rdf2json

[![Gem Version](https://badge.fury.io/rb/rdf2json.svg)](http://badge.fury.io/rb/rdf2json)
[![Build Status](https://secure.travis-ci.org/joejimbo/rdf2json.png)](http://travis-ci.org/joejimbo/rdf2json)
[![Coverage Status](https://coveralls.io/repos/joejimbo/rdf2json/badge.png?branch=master)](https://coveralls.io/r/joejimbo/rdf2json?branch=master)

Reads RDF N-Triple/N-Quads that are sorted by subject and
append a JSON/JSON-LD document per line in a designated
output file.

Usage: `rdf2json [options] --input filename.nt --output filename.json`

#### Preliminaries

RDF N-Triples/N-Quads need to be sorted by subject, so that
it is possible to output JSON/JSON-LD documents on-the-fly,
without holding the entire input in memory or falling back to
time consuming file-pointer seek operations.

Both RDF formats can be sorted on Mac OS X and Linux using the
following shell command:

```sh
sort -k 1,1 UNSORTED.EXT > SORTED.EXT
```

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

*  `-s`, `--silent`: Do not output summary statistics.
*  `-v`, `--version`: Displays the version number of the software.
*  `-h`, `--help`: Show this message.

#### JSON output (`--minimize` option)

*  replaces "@id" keys with an alternative name if the `--namespace` option is present
*  keys that start with the prefix of `--prefix` are shortened (prefix is removed)
*  array contents are "lifted up", i.e. for each entry of the array:
   *  hashes with a "@value" key are replaced by the value of "@value", or else
   *  hashes with a "@id" key are replaced by the value of "@id", or else
   *  the array value is left unchanged
*  removes all "@type" key/value pairs

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

