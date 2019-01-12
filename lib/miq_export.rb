require 'time'
require 'rugged'
require 'logger'
require 'miq_export/version'
require 'miq_export/settings'
require 'miq_export/mixin_git'

module MiqExport
  extend GitMixin

  Error = Class.new(StandardError)
  $logger = Logger.new(STDOUT)

  # Clones or finds the configured git repository
  def self.clone(git_repo: nil, export_dir: nil, **_)
    repo = find_repo(git_repo, export_dir)
    if repo.nil?
      repo = clone_repo(git_repo, export_dir)
    end
    raise Error, "No git repository found: #{git_repo} in #{export_dir}" if repo.nil?
    
    $logger.info("Using Repository at: #{repo.workdir}")
    $git_repo = repo
  end

  def self.create_branch(branch_name, base_name, force: false)
    raise Error, "Branch #{branch_name} exists! possible a dirty repository?" if !force && $git_repo.branches.exists?(branch_name)

    raise Error, "Tag #{base_name} not found!" if $git_repo.tags[base_name].nil?
    
    $logger.debug("Create branch: #{branch_name}")
    $git_repo.branches.create(branch_name, base_name, force: force)
  end

  def self.switch_branch(branch_name)
    raise Error, "Invalid Refspec: #{branch_name}" if $git_repo.ref_names(branch_name).nil?

    $logger.debug("Checkout: #{branch_name}")
    $git_repo.checkout(branch_name)
  end

  def self.merge(release, work, tag_name: , additional_tags: [], prefer: 'export', fast_forward: 'no', **opts)
    $logger.info 'merge'
    master = $git_repo.branches[release].target
    devel  = $git_repo.branches[work].target
    favor  = prefer == 'export' ? :theirs : :ours
    empty  = fast_forward == 'yes' ? false : true # logic reversal! 

    # try o merge with default settings
    index = create_index(release, work, opts.merge(strategy: 'recursive', prefer: nil))

    if index.conflicts?
      $logger.error('Conflict occured while merging')
    else
      $logger.info('Merged without conflict \o/')
      commit = create_commit(index, master, devel, opts.merge(empty: empty))

      update_ref(heads: [release, work], tags: [tag_name].concat(additional_tags), target: commit)
    end
  end

  def self.create_index(master, devel, strategy: 'recursive', prefer: nil, ignore_space: 'yes', renames: 'no', **_)
    rename = renames == 'yes' ? true : false

    favor = :normal if strategy == 'recursive' && prefer.nil?
    favor = :ours   if strategy == 'recursive' && prefer == :ours
    favor = :theirs if strategy == 'recursive' && prefer == :theis
    if strategy != 'recursive' && prefer.nil?
      $logger.error('Only recursive sraegies implemened. Aboring while I can')
      raise MiqExpor::Error, "Strategy #{strategy} not implmented"
    end

    return $git_repo.merge_commits(master, devel, favor: favor, rename: rename)
  end

  def self.update_ref(heads: [], tags: [], target:)
    heads.each{ |head| $git_repo.references.update("refs/heads/#{head}", target) }
    tags.each { |tag| $git_repo.references.update("refs/tags/#{tag}", target) }
  end
  
  def self.create_commit(index, master, devel, empty: false, message: 'AUTO export', author: 'ghost', mail: 'ghost@graveyard.org', time: Time.now, **_)
    user = { name: author, email: mail, time: time }
    tree   = index.write_tree($git_repo)
    commit_opts = {
      message: message,
      author: user,
      committer: user,
      update_ref: 'HEAD',
      parents: [ master.oid, devel.oid ],
      tree: tree
    }
    # create an empty commit
    return Rugged::Commit.create($git_repo, commit_opts) if tree.length != 0 || empty

    return master.oid  
  end

end
