# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# rc1 has been released, but don't want to risk updating the day of our release
gem 'hanami-utils', '2.0.0.beta1'

gem 'us_core_test_kit',
    git: 'https://github.com/inferno-framework/us-core-test-kit.git',
    branch: 'fi-2371-add-fine-grained-scopes-tests'

group :development, :test do
  gem 'rubocop', '~> 1.9'
  gem 'rubocop-rspec', require: false
  gem 'rubyXL'
  gem 'debug'
end
