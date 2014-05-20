
require 'rdf'
require 'rdf/ntriples'
require 'rdf/nquads'
require 'json/ld'
require 'optparse'

module RDF2JSON

def self.cli
  options = {}

  parser = OptionParser.new { |opts|
    opts.banner = 'Usage: rdf2json [options] --input filename.nt --output filename.json'

    opts.separator ''
    opts.separator 'Description: Reads RDF N-Triple/N-Quads that are sorted by subject and'
    opts.separator '             append a JSON/JSON-LD document per line in a designated'
    opts.separator '             output file.'
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

class Converter

  def initialize(input_filename, output_filename, input_format, output_format, namespace, prefix)
    @input_file = File.open(input_filename, 'r')
    @output_file = File.open(output_filename, 'a')
    @input_format = input_format
    @output_format = output_format
    @namespace = namespace
    @prefix = prefix
  end

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

  def write_graph(block)
    return { :read_errors => 0, :no_of_statements => 0 } unless block and not block.empty?

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
