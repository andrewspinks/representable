require 'representable'
require 'representable/json'
require 'representable/xml'
require 'representable/yaml'
require 'minitest/autorun'
require 'test_xml/mini_test'
require 'mocha/setup'

class Album
  attr_accessor :songs, :best_song
  def initialize(songs=nil, best_song=nil)
    @songs      = songs
    @best_song  = best_song
  end

  def ==(other)
    songs == other.songs and best_song == other.best_song
  end
end

class Song
  attr_accessor :name, :track
  def initialize(name=nil, track=nil)
    @name   = name
    @track  = track
  end

  def ==(other)
    name == other.name and track == other.track
  end
end

module XmlHelper
  def xml(document)
    Nokogiri::XML(document).root
  end
end

module AssertJson
  module Assertions
    def assert_json(expected, actual, msg=nil)
      msg = message(msg, "") { diff expected, actual }
      assert(expected.split("").sort == actual.split("").sort, msg)
    end
  end
end

MiniTest::Spec.class_eval do
  include AssertJson::Assertions
  include XmlHelper

  def self.representer!(format=Representable::Hash, name=:representer, &block)
    fmt = format # we need that so the 2nd call to ::let (within a ::describe) remembers the right format.

    if fmt.is_a?(Hash)
      name   = fmt[:name] || :representer
      format = fmt[:module] || Representable::Hash
    end

    let(name) do
      mod = Module.new

      if fmt.is_a?(Hash)
        inject_representer(mod, fmt)
      end

      mod.module_eval do
        include format
        instance_exec(&block)
      end

      mod
    end

    def inject_representer(mod, options)
      return unless options[:inject]

      injected_name = options[:inject]
      injected = send(injected_name) # song_representer
      mod.singleton_class.instance_eval do
        define_method(injected_name) { injected }
      end
    end
  end

  module TestMethods
    def representer_for(modules=[Representable::Hash], &block)
      Module.new do
        extend TestMethods
        include *modules
        module_exec(&block)
      end
    end

    alias_method :representer!, :representer_for
  end
  include TestMethods
end
