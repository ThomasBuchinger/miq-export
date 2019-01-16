json_arguments = '<<INCLUDE_ANSIBLE_MODULE_JSON_ARGS>>'
require 'json'

def generate_ansible_output(changed: true, skipped: false, msg:'', **opts)
  JSON.dump({changed: changed, skipped: skipped, msg: msg}.merge(opts))
end

def clone(config)
  MiqFlowExport.clone(config)
  {changed: true, msg: "Cloned #{config[:git_repo]}" }
end
def prep(config)
  clone(config)
  MiqFlowExport.create_branch(config[:work_branch], config[:tag_name])
  MiqFlowExport.switch_branch(config[:work_branch])
  {changed: true, msg: "Created branch #{config[:work_branch]}" }
end
def merge(config)
  clone(config)
  MiqFlowExport.switch_branch(config[:release_branch])
  MiqFlowExport.merge(config[:release_branch], config[:work_branch], config)
  {changed: true, msg: "Merged #{config[:work_branch]} into #{config[:release_branch]}" }
end
def remove(config)
  clone(config)
  MiqFlowExport.switch_branch(config[:release_branch])
  $git_repo.branches.delete(config[:work_branch]) if $git_repo.branches.exists?(config[:work_branch])
  $git_repo.branches.delete(config[:conflict_branch]) if $git_repo.branches.exists?(config[:conflict_branch])
  {changed: true, msg: "removed #{config[:work_branch]}" }
end

begin
  args = JSON.parse(json_arguments)
  settings = MiqFlowExport::Settings.set_defaults()
  settings = MiqFlowExport::Settings.update_settings(settings, args)

  puts "Methods: #{self.methods}"
  puts "Action: #{settings}"

  re = self.send(settings[:action].to_sym, settings)
  puts generate_ansible_output(re)
rescue JSON::ParserError => err
  STDERR.puts('Invalid JSON arguments')
rescue MiqFlowExport::Error => err
  puts generate_ansible_output(changed: false, msg: err.to_s, failed: true)
rescue NoMethodError => err
  puts generate_ansible_output(changed: false, msg: 'Invalid action. Must be: clone, prep, merge or remove', failed: true)
end
