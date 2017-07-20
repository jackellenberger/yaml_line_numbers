# A patched psych parser to preserve line numbers, normally cleaved from the AST.
# Line numbers will be stored as integers in Object.metadata["line"]
# Applicable to Hashes (AST stems), Arrays (AST stems & leaves), and Strings (AST leaves)
# logic adapted from https://stackoverflow.com/questions/29462856/loading-yaml-with-line-number-for-each-key/29595013#29595013

require 'psych'

# Instead of monkey patching Psych wholesale, as suggested by the SO solution, we subclass the minumum number of necessary.
# LineNumberYamlParser wraps it all up nicely to not pollute the global namespace.
class LineNumberYamlParser

  # Use LineNumberYamlParser.load() instead of YAML.load() or Psych.laad_file()
  def load(path)
    # Create a LineNumberHandler, a subclass of Psych::TreeBuilder that
    # preserves the line attribute once parsing is complete
    handler = LineNumberHandler.new
    parser = Psych::Parser.new(handler)
    handler.parser = parser

    # Parse the given file
    res = parser.parse(File.open(path))
    # Now that we have Nodes that have line attributes and a way to serialize that
    # attribute into Hash metadata, call to_ruby to return the parsed hash
    handler.root.to_ruby(LineNumberToRuby).first
  end

  private # We only want these changes to be accessible to LineNumberYamlParser class users

  # Override the Psych Node object to allow r/w access to .line
  class Psych::Nodes::Node
    attr_accessor :line

    # We also want to be able to inject our own Visitor to nodes so that when
    # self.to_ruby is called on each node it uses our new LineNumberToRuby class.
    # When no visitor is specified, we use the Psych default.
    def to_ruby(visitor = Psych::Visitors::ToRuby)
      visitor.create.accept self
    end
  end
  class Psych::Nodes::Mapping
    attr_accessor :line
  end
  class Psych::Nodes::Sequence
    attr_accessor :line
  end

  # TreeBuilder is the default handler for the AST, we'll extend it to
  # make the parser accessible and replacable, and extend the scalar node
  # to inherit the line attribute from its AST mark
  class LineNumberHandler < Psych::TreeBuilder

    # The handler needs access to the parser in order to call mark
    attr_accessor :parser

    def start_document(version, tag_directives, implicit)
      mark = parser.mark
      s = super
      s.line = mark.line
      s
    end

    def scalar(value, anchor, tag, plain, quoted, style)
      mark = parser.mark
      s = super
      s.line = mark.line
      s
    end

    def start_mapping(anchor, tag, implicit, style)
      mark = parser.mark
      s = super
      s.line = mark.line
      s
    end

    def start_sequence(anchor, tag, implicit, style)
      mark = parser.mark
      s = super
      s.line = mark.line
      s
    end
  end

  # subclass Hash, String, and Array to allow metadata to be read and written
  class Hash < Hash
    attr_accessor :metadata
  end

  class String < String
    attr_accessor :metadata
  end

  class Array < Array
    attr_accessor :metadata
  end

  # ToRuby is the default Visitor declared by Psych. We want all of its functionality, plus
  # to save the line number Node attribute to our Ruby object's metadata attribute
  class LineNumberToRuby < Psych::Visitors::ToRuby

    def accept target
      s = super
      if s
	patched_s = Module.const_get("LineNumberYamlParser::#{s.class.to_s}").new(s)
	patched_s.merge!(s) if patched_s.is_a? Hash
	patched_s.metadata ||= {}
	patched_s.metadata["line"] =  target.line
      end
      patched_s
    end

    def revive_hash hash, o
      hash = LineNumberYamlParser::Hash.new if hash == {}
      o.children.each_slice(2) do |k,v|
        key = accept(k)
        val = accept(v)
        key.metadata["line"] += 1
        hash[key] = val
      end
      hash
    end
  end
end
