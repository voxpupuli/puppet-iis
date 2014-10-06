source ENV['GEM_SOURCE'] || "https://rubygems.org"

ENV['RUBY_VERSION'] = `ruby -v`

group :development, :test do

  if ENV['RUBY_VERSION'] =~ /1.8/
    gem 'rest-client', '1.6.8'
    gem 'gssapi', '1.2.0'
    gem 'celluloid', '0.11.1'
  end

  if ENV['PUPPET_GEM_VERSION'] =~ /3.4/ && ENV['RUBY_VERSION'] !~ /1.8/
    gem 'puppet-doc-lint', :require => false
  end

  gem 'rake',                                                                    :require => false
  gem 'puppet-lint',                                                             :require => false
  gem 'rspec-puppet',
    :git => 'https://github.com/rodjek/rspec-puppet.git',
    :ref => '',
    :require => false
  gem 'puppet-syntax',                                                           :require => false
  gem 'puppetlabs_spec_helper',                                                  :require => false
  gem 'rspec',                                                                   :require => false
  gem 'beaker',                                                                  :require => false
  gem 'beaker-rspec',                                                            :require => false
  gem 'serverspec',                                                              :require => false
  gem 'specinfra',                                                               :require => false
  gem 'winrm',                                                                   :require => false
  gem 'travis',                                                                  :require => false
  gem 'travis-lint',                                                             :require => false
  gem 'vagrant-wrapper',                                                         :require => false
  gem 'puppet-blacksmith',                                                       :require => false
  gem 'guard-rake',                                                              :require => false
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, :require => false
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
