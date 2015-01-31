Gem::Specification.new do |s|
  s.name        = 'smart_json'
  s.version     = '0.0.0'
  s.summary     = 'as_smart_json'
  s.author      = 'tompng'
  s.homepage    = 'https://github.com/tompng/smart_json'
  s.files       = `git ls-files lib`.split("\n")
  %w(activerecord json).each do |name|
    s.add_dependency name
  end
  %w(activesupport sqlite3 pry).each do |name|
    s.add_development_dependency name
  end
end
