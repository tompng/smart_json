module SmartJSON
  class << self
    def deep_merge hash, hash2
      if hash.respond_to?(:types) && hash2.respond_to?(:types)
        hash.types |= hash2.types
      end
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
      end.compact
    end
  end
end
 
module SmartJSON::ARBaseClass
  class Dependencies < Hash
    def types
      @types ||= []
    end
    def types= types
      @types = types
    end
  end
  def smart_json type, &block
    @smart_json_definitions ||= {}
    definition = smart_json_definitions[type] = {block: block}
    def definition.depend_on *options
      self[:dependency] = SmartJSON.options_to_hash options
    end
    definition
  end
  def smart_json_dependencies arguments
    options = Array.wrap arguments
    dependencies = Dependencies.new
    includes = {}
    options.select{|t|Symbol === t}.each do |type|
      next if reflections[type]
      definition = smart_json_definitions.try :[], type
      next if definition.nil?
      dependencies.types << type
      dependency = definition[:dependency]
      SmartJSON.deep_merge includes, dependency if dependency
    end
    options -= dependencies.types
    options.reject{|o|Hash===o}.each do |name|
      dependencies[name] ||= Dependencies.new
      includes[name] ||= {}
    end
    options.select{|o|Hash===o}.each do |hash|
      hash.each do |key, value|
        reflection = reflections[key]
        dep, inc = reflection.klass.smart_json_dependencies value
        SmartJSON.deep_merge (dependencies[key] ||= Dependencies.new), dep
        SmartJSON.deep_merge (includes[key] ||= {}), inc
      end
    end
    [dependencies, includes]
  end
 
  ActiveRecord::Base.extend self
  ActiveRecord::Base.singleton_class.send :attr_reader, :smart_json_definitions
end
module SmartJSON::ARBaseClass
  def as_typed_smart_json types
    definitions = types.map{|type|self.class.smart_json_definitions[type]}
    default = self.class.smart_json_definitions.try :[], :default
    definitions << default if default
    return as_json if definitions.blank?
    json = {}
    definitions.map{|definition|
      SmartJSON.deep_merge json, instance_exec(&definition[:block])
    }
    json
  end
  def as_loaded_smart_json dependencies
    json = as_typed_smart_json dependencies.types
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
    json = as_typed_smart_json dependencies.types
    dependencies.each{|key, value|
      json[key] = send(key).try :as_smart_json_from_dependencies, value, includes[key]
    }
    json
  end
  def as_smart_json *options
    dependencies, includes = self.class.smart_json_dependencies options
    as_smart_json_from_dependencies dependencies, includes
  end
  ActiveRecord::Base.include self
end
module SmartJSON::ARRelation
  def as_smart_json_from_dependencies dependencies, includes
    relations = includes(SmartJSON.hash_to_includes_options includes)
    relations.map{|model|
      model.as_loaded_smart_json dependencies
    }
  end
  def as_smart_json *options
    dependencies, includes = klass.smart_json_dependencies options
    as_smart_json_from_dependencies dependencies, includes
  end
  ActiveRecord::Relation.include self
end
