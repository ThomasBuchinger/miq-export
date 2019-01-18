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

  def self.process_merge_opts(release, work, *opts)
    opts = {}
    opts[:master_name] = release
    opts[:devel_name] = work
    opts[:master_commit] = $git_repo.branches[release].target
    opts[:devel_commit] = $git_repo.branches[work].target

    prefer = args[:prefer] || 'export'
    favor_export = prefer == 'export'
    opts[:strategy] = 'recursive'
    opts[:release_favor] = favor_export ? :their : :ours
    opts[:conflict_favor] = favor_export ? :ours : :theirs

    fast_forward
    opts[:fast_forward] = fast_forward == 'yes'
    opts[:allow_empty] = !opts[:fast_forward]

    opts[:additional_tags] = args[:a]

    return opts
  end

  

  def self.merge(release, work, tag_name: '', additional_tags: [], prefer: 'export', fast_forward: 'no', **opts)
    $logger.info 'merge'
    #options  = precess_merge_options(release )
    master  = $git_repo.branches[release].target
    devel   = $git_repo.branches[work].target
    favor   = prefer == 'export' ? :theirs : :ours
    c_favor = prefer == 'export' ? :ours : :theirs
    empty   = !(fast_forward == 'yes') # logic reversal!

    # try o merge with default settings
    index = create_index(release, work, opts.merge(strategy: 'recursive', prefer: nil))

    if index.conflicts?
      $logger.error('Conflict occured while merging')
      
      c_branch = add_conflict_branch()
      c_index = create_index(release, work, opts.merge(strategy: 'recursive', prefer: :ours))

      $logger.warn('PRE: conflict commit')
      c_commit = create_commit(c_index, c_branch.target, opts)
      update_ref(heads: [c_branch.name], tags: [], target: c_commit)

      #master = $git_repo.branches[release].target
      index = create_index(release, work, opts.merge(strategy: 'recursive', prefer: :theirs))
    else
      $logger.info('Merged without conflict \o/')
    end

    # update master
      $logger.warn('PRE: master commit')
    commit = create_commit(index, [master, devel], opts.merge(empty: empty))
    $git_repo.checkout_head()
    update_ref(heads: [release, work], tags: additional_tags, target: commit)
    
  end

  def self.deal_with_conflict
  
  end

  def self.add_conflict_branch()
    create_branch('tmp_conflict', 'LAST_EXPORT')
  end
end
