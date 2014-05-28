
require 'rdf'
require 'rdf/ntriples'
require 'rdf/nquads'
require 'json/ld'
require 'optparse'

# Module that contains a class for transforming RDF N-Triples/N-Quads into
# JSON/JSON-LD as well as a command line interface implementation for user
# interactions.
module RDF2JSON

# Command line interface; reads parameters, outputs help, or proceeds with the
# transformation of RDF N-Triples/N-Quads into JSON/JSON-LD.
def self.cli
  options = {}

  parser = OptionParser.new { |opts|
    opts.banner = 'Usage: rdf2json [options] --input filename.nt --output filename.json'

    opts.separator ''
    opts.separator 'Description: Reads RDF N-Triple/N-Quads that are sorted by subject and'
    opts.separator '             append a JSON/JSON-LD document per line in a designated'
    opts.separator '             output file.'
    opts.separator ''
    opts.separator 'Notes:'
    opts.separator '             Sorting on Mac OS X & Linux:'
    opts.separator '               sort -k 1,1 UNSORTED.EXT > SORTED.EXT'
    opts.separator ''
    opts.separator '             More information on the --minimize parameter:'
    opts.separator '               https://github.com/joejimbo/rdf2json'
    opts.separator ''
    opts.separator 'Required:'

    opts.on('-i', '--input FILE', 'Input file for the conversion; either RDF N-Triples or N-Quads.') { |file|
      options[:input] = file
    }
    opts.on('-o', '--output FILE', 'Output file to which JSON-LD/JSON is appended.') { |file|
      options[:output] = file
    }

    opts.separator ''
    opts.separator 'Options:'

    opts.on('-m', '--minimize', 'Minimize JSON-LD to plain (semantically untyped) JSON.') { |minimize|
      options[:minimize] = true
    }
    opts.on('-n', '--namespace [NAMESPACE]', 'Alternative name for JSON-LD\'s "@id" key; replaces it; turns on --minimize') { |namespace|
      options[:minimize] = true
      options[:namespace] = namespace
    }
    opts.on('-p', '--prefix [PREFIX]', 'Prefix that should be removed from keys; requires --minimize.') { |prefix|
      options[:prefix] = prefix
    }
    opts.on('-t', '--triples', 'Input file is in RDF N-Triples format.') { |triples|
      options[:ntriples] = true
    }
    opts.on('-q', '--quads', 'Input file is in RDF N-Quads format.') { |quads|
      options[:nquads] = true
    }

    opts.separator ''
    opts.separator 'Common options:'

    opts.on_tail('-h', '--help', 'Show this message.') { |help|
      puts opts
      exit
    }
  }

  begin
    parser.parse!
  rescue
    puts parser
    exit 1
  end

  unless options.has_key?(:input) and options.has_key?(:output) then
    puts 'Error: Requires --input and --output parameters.'
    puts ''
    puts parser
    exit 2
  end

  if options.has_key?(:ntriples) and options.has_key?(:nquads) then
    puts 'Error: both --triples and --quads parameters were used.'
    puts '       Only one of the parameters may be provided for explicitly'
    puts '       setting the input fileformat.'
    puts ''
    puts parser
    exit 3
  end

  extension = File.extname(options[:input])
  if options.has_key?(:ntriples) then
    input_format = :ntriples
  elsif options.has_key?(:nquads) then
    input_format = :nquads
  elsif extension == '.nt' then
    input_format = :ntriples
  elsif extension == '.nq' then
    input_format = :nquads
  else
    puts 'Error: Cannot determine input file format by filename extension.'
    puts '       Recognized fileformat extensions are .nt and .nq for N-Triples'
    puts '       and N-Quads respectively. Use --triples or --quads options to'
    puts '       explicitly set the input fileformat (ignores filename extension'
    puts '       when one of those options is given.'
    puts ''
    puts parser
    exit 4
  end

  output_format = :jsonld
  output_format = :json if options[:minimize]

  unless File.exist?(options[:input]) then
    puts 'Error: Input file (--input parameter) does not seem to exist.'
    puts ''
    puts parser
    exit 6
  end

  begin
    # Why instantiate a Converter instance here? Well, for implementing parallelization later:
    Converter.new(options[:input], options[:output], input_format, output_format, options[:namespace], options[:prefix]).convert
  rescue Interrupt
    # The user hit Ctrl-C, which is okay and does not need error reporting.
    exit 0
  end
end

# Class that takes an input file (RDF N-Triples/N-Quads) and appends JSON/JSON-LD to
# a possible pre-existing output file. A namespace and prefix can be given that handle
# `--namespace` and `--prefix` parameters in conjunction with the `--minimize` parameter.
class Converter

  # Initializes a new converter instance.
  #
  # +input_filename+:: path/filename of the input file in RDF N-Triples/N-Quads
  # +output_filename+:: path/filename of the output file to which JSON/JSON-LD is being appended
  # +input_format+:: format of the input file (:ntriples or :nquads)
  # +output_format+:: format of the output (:json or jsonld)
  # +namespace+:: a possible namespace for replacing "@id" keys (may be nil)
  # +prefix+:: a possible prefix for shortening keys (may be nil)
  def initialize(input_filename, output_filename, input_format, output_format, namespace, prefix)
    @input_file = File.open(input_filename, 'r')
    @output_file = File.open(output_filename, 'a')
    @input_format = input_format
    @output_format = output_format
    @namespace = namespace
    @prefix = prefix
  end

  # Convert the input file by appending the newly formatted data to the output file.
  #
  # At the end of the conversion a short statistic is output. It tells the number of
  # lines read from the input file, the number of errors in the N-Triples/N-Quads file,
  # the number of JSON/JSON-LD documents appended to the output file (equiv. to number
  # of lines appended).
  def convert
    no_of_lines = 0
    no_of_statements = 0
    read_errors = 0
    last_subject = nil
    subject_block = ''

    @input_file.each_line { |line|
      no_of_lines += 1
      line.chomp!

      subject = "#{line.sub(/>.*/, '')}>"

      if subject == last_subject then
        subject_block << line
      else
        stats = write_graph(subject_block)
        no_of_statements += stats[:no_of_statements]
        read_errors += stats[:read_errors]
        subject_block = ''
      end

      last_subject = subject
    }

    stats = write_graph(subject_block)
    no_of_statements += stats[:no_of_statements]
    read_errors += stats[:read_errors]

    puts "Total number of lines read                   : #{no_of_lines}"
    puts "Statement read errors (N-Quads or N-Triples) : #{read_errors}"
    puts "JSON/JSON-LD documents output                : #{no_of_statements}"
  end

  # Minimize a JSON-LD hash to JSON.
  #
  # +jsonld_hash+:: a JSON-LD hash that should be rewritten to plain JSON
  def minify(jsonld_hash)
    jsonld_hash.keys.each { |key|
      if key == '@type' then
        jsonld_hash.delete(key)
      elsif @prefix and key.match(@prefix) then
        shortened_key = key.sub(@prefix, '')
        jsonld_hash[shortened_key] = jsonld_hash.delete(key)
        key = shortened_key
      end

      if jsonld_hash[key].instance_of?(Array) then
        jsonld_hash[key].each_index { |index|
          if jsonld_hash[key][index].has_key?('@value') then
            jsonld_hash[key][index] = jsonld_hash[key][index]['@value']
          elsif jsonld_hash[key][index].has_key?('@id') then
            jsonld_hash[key][index] = jsonld_hash[key][index]['@id']
          end
        }
      elsif jsonld_hash[key].instance_of?(Hash) then
        minify(jsonld_hash[key])
      end
    }
  end

  # Takes a block of RDF statements that share the same subject and creates
  # a JSON/JSON-LD document from them, which is appended to the output file.
  #
  # +block+:: one or more lines that share the same subject in RDF N-Triples/N-Quads
  def write_graph(block)
    return { :read_errors => 0, :no_of_statements => 0 } unless block and not block.empty?

    # Virtuoso output error-handling:
    block.gsub!("\\'", "'")

    read_errors = 0
    no_of_statements = 0
    graph = RDF::Graph.new
    RDF::Reader.for(@input_format).new(block) { |reader|
      begin
        reader.each_statement { |statement|
          no_of_statements += 1
          graph.insert(statement)
        }
      rescue RDF::ReaderError
        read_errors += 1
      end
    }

    JSON::LD::API::fromRdf(graph) { |document|
      document.each{ |entity|
        # Parsed JSON-LD representation:
        entity = JSON.parse(entity.to_json)

        entity[@namespace] = entity.delete('@id') if @namespace
        minify(entity) if @output_format == :json

        @output_file.puts entity.to_json
      }
    }

    return { :read_errors => read_errors, :no_of_statements => no_of_statements }
  end

end

end
