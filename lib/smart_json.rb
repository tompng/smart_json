module SmartJSON
  class << self
    def deep_merge hash, hash2
      hash2.each do |key, value|
        if hash[key] && Hash === value
          deep_merge hash[key], value
        else
          hash[key] = value
        end
      end
      hash
    end
    def options_to_hash options
      out = {}
      options.reject{|o|Hash===o}.each do |name|
        out[name] = {}
      end
      options.select{|o|Hash===o}.each do |hash|
        hash.each do |name, value|
          out[name] = options_to_hash [*value]
        end
      end
      out
    end
    def hash_to_includes_options hash
      hash.map do |key, value|
        if value.empty?
          key
        else
          {key => hash_to_includes_options(value)}
        end
      end
    end
  end
end
 
module SmartJSON::ARBaseClass
  class Dependencies < Hash
    def styles
      @styles ||= []
    end
    def styles= styles
      @styles = styles
    end
  end
  class Definition
    attr_reader :dependency
    def initialize klass, block, options
      @klass = klass
      @block = block
      @options = options
    end
    def require *options
      @dependency = SmartJSON.options_to_hash options
    end
    def serialize model
      if @options.present?
        base = model.as_smart_json_from_dependencies *@klass.smart_json_dependencies(@options)
      end
      if @block
        overrides = model.instance_exec &@block
      else
        overrides = {}
      end
      if base
        SmartJSON.deep_merge base, overrides
      else
        overrides
      end
    end
    def dependency
      return @dependency unless @options.present?
      dependencies, includes = @klass.smart_json_dependencies @options
      if @dependency
        SmartJSON.deep_merge @dependency.dup, includes
      else
        includes
      end
    end
  end
  def smart_json style, *options, &block
    @smart_json_definitions ||= {}
    smart_json_definitions[style] = Definition.new self, block, options
  end
  def smart_json_dependencies arguments
    options = Array.wrap arguments
    dependencies = Dependencies.new
    includes = {}
    options.select{|t|Symbol === t}.each do |style|
      next if reflections[style]
      definition = smart_json_definitions.try :[], style
      next if definition.nil?
      dependencies.styles << style
      dependency = definition.dependency
      SmartJSON.deep_merge includes, dependency if dependency
    end
    options -= dependencies.styles
    options.reject{|o|Hash===o}.each do |name|
      dependencies[name] ||= Dependencies.new
      includes[name] ||= {}
    end
    options.select{|o|Hash===o}.each do |hash|
      hash.each do |key, value|
        reflection = reflections[key]
        dep, inc = reflection.klass.smart_json_dependencies value
        depkey = dependencies[key] ||= Dependencies.new
        SmartJSON.deep_merge depkey, dep
        depkey.styles |= dep.styles
        SmartJSON.deep_merge (includes[key] ||= {}), inc
      end
    end
    [dependencies, includes]
  end
  ActiveRecord::Base.extend self
  ActiveRecord::Base.singleton_class.send :attr_reader, :smart_json_definitions
end

module SmartJSON::ARBaseClass
  def as_styled_smart_json styles
    definitions = styles.map{|style|self.class.smart_json_definitions[style]}
    default = self.class.smart_json_definitions.try :[], :default
    definitions.unshift default if default
    return as_json if definitions.blank?
    json = {}
    definitions.each do |definition|
      SmartJSON.deep_merge json, definition.serialize(self)
    end
    json
  end
  def as_loaded_smart_json dependencies
    json = as_styled_smart_json dependencies.styles
    dependencies.each do |key, value|
      child = self.send(key)
      if ActiveRecord::Relation === child
        json[key] = child.try(:map){|c|c.as_loaded_smart_json value}
      else
        json[key] = child.try :as_loaded_smart_json, value
      end
    end
    json
  end
  def as_smart_json_from_dependencies dependencies, includes
    json = as_styled_smart_json dependencies.styles
    dependencies.each do |key, value|
      json[key] = send(key).try :as_smart_json_from_dependencies, value, includes[key]
    end
    json
  end
  def as_smart_json *options
    as_smart_json_from_dependencies *self.class.smart_json_dependencies(options)
  end
  ActiveRecord::Base.include self
  class << ActiveRecord::Base
    def as_smart_json *options
      all.as_smart_json *options
    end
  end
end

module SmartJSON::ARRelation
  def as_smart_json_from_dependencies dependencies, includes
    relations = includes(SmartJSON.hash_to_includes_options includes)
    relations.map do |model|
      model.as_loaded_smart_json dependencies
    end
  end
  def as_smart_json *options
    as_smart_json_from_dependencies *klass.smart_json_dependencies(options)
  end
  ActiveRecord::Relation.include self
end
