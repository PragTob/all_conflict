require 'capybara/cucumber'
require 'aruba/cucumber'

Aruba::Api::Core.include(::Capybara::RSpecMatcherProxies)

Capybara.app = Rack::Builder.new do
  use Rack::Static, urls: {"/" => "index.html"}, root: "."
  run Rack::Directory.new(".")
end.to_app
