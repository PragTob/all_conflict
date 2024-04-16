require 'method_source'

Then(/^I debug what the hell `all` is$/) do
  fun = method(:all)

  puts fun.source_location
  puts fun.source
end

Then(/^I want to check something with all$/) do
  expect([2, 4, 6]).to all be_even
end
