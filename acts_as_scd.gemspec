$:.push File.expand_path("../lib", __FILE__)

require "acts_as_scd/version"

Gem::Specification.new do |s|
  s.name        = "acts_as_scd"
  s.version     = ActsAsScd::VERSION
  s.authors     = ["Javier Goizueta", "Matteo Esche"]
  s.email       = ["jgoizueta@gmail.com", "webmaster@meinzeug.de"]
  s.homepage    = "https://github.com/meinzeugde/acts_as_scd"
  s.summary     = "Support for models that act as Slowly Changing Dimensions"
  s.description = "SCD models have identities and multiple time-limited iterations (revisions) per identity"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  # s.add_dependency "rails", "~> 4.1.1"
  # s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "rails", ">= 3.2.13"

  s.add_dependency 'modalsupport', "~> 0.9.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'mysql2', '~>0.3.17'
end
