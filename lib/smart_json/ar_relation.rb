module SmartJSON::ARRelation
  def as_styled_smart_json param, definitions, loaded: true, default: true
    records = self
    unless loaded
      includes = klass.smart_json_includes_dependencies param, definitions
      records = records.includes(SmartJSON::Util.hash_to_includes_options includes)
    end
    records.map do |model|
      model.as_styled_smart_json param, definitions
    end
  end
  def as_smart_json *options
    as_smart_json_with_param nil, *options
  end
  def as_smart_json_with_param param, *options
    as_styled_smart_json param, [SmartJSON::Definition.new(klass, options)], loaded: false
  end
end
