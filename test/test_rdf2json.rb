require 'helper'

require 'tempfile'

# Test the RDF N-Triples/N-Quads to JSON/JSON-LD conversion.
class TestRDF2JSON < Minitest::Test

    # RDF N-Triples test dataset:
    @@test_ntriples = <<-EOI
<s1> <http://test/p1> <o1> .
<s1> <p2> "l1" .
<s1> <p3> <o3> .
<s1> <p3> <o4> .
<s2> <http://test/p1> <o5> .
<s2> <p4> "l2" .
EOI

    # RDF N-Triples test dataset:
    @@test_nquads = <<-EOI
<s1> <http://test/p1> <o1> <g1> .
<s1> <p2> "l1" <g1> .
<s1> <p3> <o3> <g1> .
<s1> <p3> <o4> <g1> .
<s2> <http://test/p1> <o5> <g2> .
<s2> <p4> "l2" <g2> .
EOI

  # Creates a temporary file that holds either N-Triples or N-Quads.
  #
  # +format+:: whether N-Triples or N-Quads should be used (:ntriples, :nquads)
  def self.create_input(format)
    input = Tempfile.new('rdf2json-converter-input')
    if format == :ntriples then
      input.puts @@test_ntriples
    elsif format == :nquads then
      input.puts @@test_nquads
    else
      raise "Passed a constant to create_input that is not understood."
    end
    input.close

    return input
  end

  # Reads JSON/JSON-LD documents from a file; one document per line.
  #
  # +output+:: handle to the file that contains JSON/JSON-LD documents (one per line)
  def self.get_json(output)
    output.rewind

    return output.readlines
  end

  # Tests whether the reference and output arrays match.
  #
  # +reference+:: an array of reference objects
  # +output+:: an array containing the converter output objects
  def self.test(reference, output)
    output.length.must_equal(reference.length)
    reference.each_index { |index|
      output[index].must_equal(reference[index])
    }
  end

  # N-Triples to JSON/JSON-LD tests.
  describe 'N-Triple conversion' do
    before do
      @input = TestRDF2JSON.create_input(:ntriples)
      @output = Tempfile.new('rdf2json-converter-output')
    end

    after do
      @input.unlink
      @output.unlink
    end

    it 'input: N-Triples; output: JSON-LD' do
      converter = RDF2JSON::Converter.new(@input.path, @output.path, :ntriples, :jsonld, nil, nil)
      converter.convert
      
      json = TestRDF2JSON.get_json(@output)
      TestRDF2JSON.test([
                          '{"@id":"s1","http://test/p1":[{"@id":"o1"}],"p2":[{"@value":"l1"}],"p3":[{"@id":"o3"},{"@id":"o4"}]}' + "\n",
                          '{"@id":"s2","p4":[{"@value":"l2"}]}' + "\n"
                        ],
                        json)
    end

    it 'input: N-Triples; output: JSON (minified JSON-LD)' do
      converter = RDF2JSON::Converter.new(@input.path, @output.path, :ntriples, :json, nil, nil)
      converter.convert
      
      json = TestRDF2JSON.get_json(@output)
      TestRDF2JSON.test([
                          '{"@id":"s1","http://test/p1":["o1"],"p2":["l1"],"p3":["o3","o4"]}' + "\n",
                          '{"@id":"s2","p4":["l2"]}' + "\n"
                        ],
                        json)
    end

    it 'input: N-Triples; output: JSON (minified JSON-LD); namespace: primary_key' do
      converter = RDF2JSON::Converter.new(@input.path, @output.path, :ntriples, :json, 'primary_key', nil)
      converter.convert
      
      json = TestRDF2JSON.get_json(@output)
      TestRDF2JSON.test([
                          '{"http://test/p1":["o1"],"p2":["l1"],"p3":["o3","o4"],"primary_key":"s1"}' + "\n",
                          '{"p4":["l2"],"primary_key":"s2"}' + "\n"
                        ],
                        json)
    end

    it 'input: N-Triples; output: JSON (minified JSON-LD); prefix: http://test/' do
      converter = RDF2JSON::Converter.new(@input.path, @output.path, :ntriples, :json, nil, 'http://test/')
      converter.convert
      
      json = TestRDF2JSON.get_json(@output)
      TestRDF2JSON.test([
                          '{"@id":"s1","p2":["l1"],"p3":["o3","o4"],"p1":["o1"]}' + "\n",
                          '{"@id":"s2","p4":["l2"]}' + "\n"
                        ],
                        json)
    end

    it 'input: N-Triples; output: JSON (minified JSON-LD); namespace: primary_key, prefix: http://test/' do
      converter = RDF2JSON::Converter.new(@input.path, @output.path, :ntriples, :json, 'primary_key', 'http://test/')
      converter.convert
      
      json = TestRDF2JSON.get_json(@output)
      TestRDF2JSON.test([
                          '{"p2":["l1"],"p3":["o3","o4"],"primary_key":"s1","p1":["o1"]}' + "\n",
                          '{"p4":["l2"],"primary_key":"s2"}' + "\n"
                        ],
                        json)
    end

  end

  # N-Quads to JSON/JSON-LD tests; assumes that namespace and prefix handling are not affected
  # by the change of input format (hence, not tested again).
  describe 'N-Quads conversion' do
    before do
      @input = TestRDF2JSON.create_input(:nquads)
      @output = Tempfile.new('rdf2json-converter-output')
    end

    after do
      @input.unlink
      @output.unlink
    end

    it 'input: N-Quads; output: JSON-LD' do
      converter = RDF2JSON::Converter.new(@input.path, @output.path, :nquads, :jsonld, nil, nil)
      converter.convert
      
      json = TestRDF2JSON.get_json(@output)
      TestRDF2JSON.test([
                          '{"@id":"s1","http://test/p1":[{"@id":"o1"}],"p2":[{"@value":"l1"}],"p3":[{"@id":"o3"},{"@id":"o4"}]}' + "\n",
                          '{"@id":"s2","p4":[{"@value":"l2"}]}' + "\n"
                        ],
                        json)
    end

    it 'input: N-Quads; output: JSON (minified JSON-LD)' do
      converter = RDF2JSON::Converter.new(@input.path, @output.path, :nquads, :json, nil, nil)
      converter.convert
      
      json = TestRDF2JSON.get_json(@output)
      TestRDF2JSON.test([
                          '{"@id":"s1","http://test/p1":["o1"],"p2":["l1"],"p3":["o3","o4"]}' + "\n",
                          '{"@id":"s2","p4":["l2"]}' + "\n"
                        ],
                        json)
    end
  end
end
