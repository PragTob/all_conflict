require 'aruba/cucumber'
# require 'rspec/expectations'
require 'capybara/cucumber'


Capybara.app = Rack::Builder.new do
  use Rack::Static, urls: {"/" => "index.html"}, root: "."
  run Rack::Directory.new(".")
end.to_app
