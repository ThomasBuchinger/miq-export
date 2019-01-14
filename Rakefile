require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'miq_flow_export'
#Dir.glob('tasks/*.rake').each { |r| load r}

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new()

def get_config
  MiqFlowExport::Settings.set_defaults()
end

desc "Prepare Repository"
task :prep => [:clone] do
  config = get_config()
  MiqFlowExport.create_branch(config[:work_branch], config[:tag_name])
  MiqFlowExport.switch_branch(config[:work_branch])
end

desc "Merge and commit changes"
task :merge => [:clone] do
  config = get_config()
  MiqFlowExport.switch_branch(config[:release_branch])
  MiqFlowExport.merge(config[:release_branch], config[:work_branch], config)
end

desc 'Clone repository'
task :clone do
  config = get_config()
  MiqFlowExport.clone(config)
end

desc 'Remove temporary stuff'
task :remove => [:clone] do
  config = get_config()
  MiqFlowExport.switch_branch(config[:release_branch])
  $git_repo.branches.delete(config[:work_branch]) if $git_repo.branches.exists?(config[:work_branch])
end

desc 'Package ansible module'
task :ansible do
  ANSIBLE_MODULE = 'pkg/miq_flow_export.rb'
  files = [
    'lib/miq_export/version.rb',
    'lib/miq_export/mixin_git.rb',
    'lib/miq_export/settings.rb',
    'lib/miq_export/exporter.rb',
    'lib/miq_export/ansible.rb'
  ]
  sh "echo '#!/bin/env ruby' > #{ANSIBLE_MODULE}"
  puts "Copy files: #{files.join(', ')}"
  open(ANSIBLE_MODULE, 'a') do |out|
    files.each{ |input| out.write(File.new(input).read) }
  end
  chmod(0755, ANSIBLE_MODULE)
end
task :default => :spec
