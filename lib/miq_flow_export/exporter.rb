# frozen_string_literals: true

require 'time'
require 'rugged'
require 'logger'

module MiqFlowExport
  extend GitMixin

  Error = Class.new(StandardError)
  $logger = Logger.new(STDOUT)

  # Clones or finds the configured git repository
  def self.clone(git_repo: nil, export_dir: nil, **_)
    repo = find_repo(git_repo, export_dir)
    repo = clone_repo(git_repo, export_dir) if repo.nil?

    raise Error, "No git repository found: #{git_repo} in #{export_dir}" if repo.nil?

    $logger.info("Using Repository at: #{repo.workdir}")
    $git_repo = repo
  end

  def self.create_branch(branch_name, base_name, force: false)
    branch_exists = $git_repo.branches.exists?(branch_name)
    raise Error, "Branch #{branch_name} exists! possible a dirty repository?" if !force && branch_exists

    raise Error, "Tag #{base_name} not found!" if $git_repo.tags[base_name].nil?

    $logger.debug("Create branch: #{branch_name}")
    $git_repo.branches.create(branch_name, base_name, force: force)
  end

  def self.switch_branch(branch_name)
    raise Error, "Invalid Refspec: #{branch_name}" if $git_repo.ref_names(branch_name).nil?

    $logger.debug("Checkout: #{branch_name}")
    $git_repo.checkout(branch_name)
  end

  def self.merge(release, work, _tag_name:, additional_tags: [], prefer: 'export', fast_forward: 'no', **opts)
    $logger.info 'merge'
    master = $git_repo.branches[release].target
    devel  = $git_repo.branches[work].target
    favor  = prefer == 'export' ? :theirs : :ours
    empty  = !(fast_forward == 'yes') # logic reversal!

    # try o merge with default settings
    index = create_index(release, work, opts.merge(strategy: 'recursive', prefer: nil))

    if index.conflicts?
      $logger.error('Conflict occured while merging')
    else
      $logger.info('Merged without conflict \o/')
      commit = create_commit(index, master, devel, opts.merge(empty: empty))
      $git_repo.checkout_head()
      update_ref(heads: [release, work], tags: additional_tags, target: commit)
    end
  end
end
