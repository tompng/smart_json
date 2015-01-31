require_relative 'util'

module SmartJSON::ARRelation
  def as_smart_json_from_dependencies dependencies, includes
    relations = includes(SmartJSON::Util.hash_to_includes_options includes)
    relations.map do |model|
      model.as_loaded_smart_json dependencies
    end
  end
  def as_smart_json *options
    as_smart_json_from_dependencies *klass.smart_json_dependencies(options)
  end
end
