module SmartJSON::ARRelation
  def as_styled_smart_json definitions, loaded: true, default: true
    records = self
    unless loaded
      includes = klass.smart_json_includes definitions
      records = self.includes(SmartJSON::Util.hash_to_includes_options includes)
    end
    records.map do |model|
      model.as_styled_smart_json definitions, default: true
    end
  end
  def as_smart_json *options
    as_styled_smart_json [SmartJSON::Definition.new(klass, options)], loaded: false
  end
end
