require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'miq_export'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new()

def get_config
  MiqExport::Settings.set_defaults()
end

desc "Prepare Repository"
task :prep => [:clone] do
  config = get_config()
  MiqExport.create_branch(config[:work_branch], config[:tag_name])
  MiqExport.switch_branch(config[:work_branch])
end

desc "Merge and commit changes"
task :merge => [:clone] do
  config = get_config()
  MiqExport.switch_branch(config[:release_branch])
  MiqExport.merge(config[:release_branch], config[:work_branch], config)
end

desc 'Clone repository'
task :clone do
  config = get_config()
  MiqExport.clone(config)
end

desc 'Remove temporary stuff'
task :remove => [:clone] do
  config = get_config()
  MiqExport.switch_branch(config[:release_branch])
  $git_repo.branches.delete(config[:work_branch]) if $git_repo.branches.exists?(config[:work_branch])
end

task :default => :spec
