source ENV['GEM_SOURCE'] || "https://rubygems.org"

def location_for(place, fake_version = nil)
  if place =~ /^(git[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

group :test do
  gem 'rake',                                                       :require => false
  gem 'rspec-puppet',                                               :require => false, :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'puppet-lint',                                                :require => false, :git => 'https://github.com/rodjek/puppet-lint.git'
  gem 'metadata-json-lint',                                         :require => false
  gem 'rspec-puppet-facts',                                         :require => false
  gem 'rspec',                                                      :require => false
  gem 'puppet-blacksmith',                                          :require => false, :git => 'https://github.com/voxpupuli/puppet-blacksmith.git'
  gem 'voxpupuli-release',                                          :require => false, :git => 'https://github.com/voxpupuli/voxpupuli-release-gem.git'
  gem 'rubocop', '~> 0.38',                                         :require => false
  gem 'rspec-puppet-utils',                                         :require => false
  gem 'puppetlabs_spec_helper',                                     :require => false
  gem 'puppet-lint-absolute_classname-check',                       :require => false
  gem 'puppet-lint-leading_zero-check',                             :require => false
  gem 'puppet-lint-trailing_comma-check',                           :require => false
  gem 'puppet-lint-version_comparison-check',                       :require => false
  gem 'puppet-lint-classes_and_types_beginning_with_digits-check',  :require => false
  gem 'puppet-lint-unquoted_string-check',                          :require => false
  gem 'puppet-lint-variable_contains_upcase',                       :require => false
end

group :development do
  gem 'travis',       :require => false
  gem 'travis-lint',  :require => false
  gem 'guard-rake',   :require => false
end

group :system_tests do
  gem 'winrm'
  gem "beaker",
    :git => 'https://github.com/petems/beaker-windows.git',
    :ref => 'd42d1b83b8de9c8b76fb5a19c859a3e71eeab28a',
    :require => false
  gem "beaker-rspec",
    :git => 'https://github.com/petems/beaker-rspec-windows.git',
    :ref => 'd96cff5fc937efe1dca03c6ea3c236bf4c7337ab',
    :require => false
  gem 'beaker-puppet_install_helper',  :require => false
end



if facterversion = ENV['FACTER_GEM_VERSION']
gem 'facter', facterversion.to_s, :require => false, :groups => [:test]
else
gem 'facter', :require => false, :groups => [:test]
end

ENV['PUPPET_VERSION'].nil? ? puppetversion = '~> 3.0' : puppetversion = ENV['PUPPET_VERSION'].to_s
gem 'puppet', puppetversion, :require => false, :groups => [:test]

# vim:ft=ruby
