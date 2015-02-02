require 'active_record'
module SmartJSON
  require_relative 'smart_json/util'
  require_relative 'smart_json/definition'
  require_relative 'smart_json/ar_relation'
  require_relative 'smart_json/ar_base'
  require_relative 'smart_json/ar_base_class'
  ActiveRecord::Base.class_eval do
    include ARBase
  end
  ActiveRecord::Relation.class_eval do
    include ARRelation
  end
  ActiveRecord::Base.singleton_class.class_eval do
    attr_reader :smart_json_definitions
    include ARBaseClass
  end
end
