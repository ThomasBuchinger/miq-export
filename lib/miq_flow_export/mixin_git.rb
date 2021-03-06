module MiqFlowExport
  module GitMixin

    def find_repo(path, dir)
      return nil unless File.directory?(dir)

      repo_name = File.basename(path, '.git')
      return nil unless File.directory?(File.join(dir, repo_name, '.git'))

      $logger.debug("Using existing Repository at #{File.join(dir, repo_name)}")
      Rugged::Repository.discover(File.join(dir, repo_name))
    end

    def clone_repo(url, dir, _cred: nil)
      return nil unless File.directory?(dir)

      repo_name = File.basename(url, '.git')
      $logger.debug("Clone Repository at #{url} to #{dir}/#{repo_name}")
      Rugged::Repository.clone_at(url, File.join(dir, repo_name))
    end

    def create_index(master, devel, strategy: 'recursive', prefer: nil, _ignore_space: 'yes', renames: 'no', **_)
      rename = renames == 'yes'

      favor = :normal if strategy == 'recursive' && prefer.nil?
      favor = :ours   if strategy == 'recursive' && prefer == :ours
      favor = :theirs if strategy == 'recursive' && prefer == :theirs
      if strategy != 'recursive' && prefer.nil?
        $logger.error('Only recursive strategies implemented. Aborting while I can')
        raise MiqFlowExport::Error, "Strategy #{strategy} not implmented"
      end

      $git_repo.merge_commits(master, devel, favor: favor, rename: rename)
    end

    def update_ref(heads: [], tags: [], target:)
      heads.each{ |head| $git_repo.references.update("refs/heads/#{head}", target) }
      tags.each{ |tag| $git_repo.references.update("refs/tags/#{tag}", target) }
    end

    def create_commit(index, parents, empty: false, message: 'AUTO export', author: 'ghost', mail: 'ghost@graveyard.org', time: Time.now, **_)
      user = { name: author, email: mail, time: time }
      tree = index.write_tree($git_repo)
      parents = [ parents ].flatten.map{|commit|  commit.oid}
      commit_opts = {
        message: message,
        author: user,
        committer: user,
        update_ref: 'HEAD',
        parents: parents,
        tree: tree
      }
      # create an empty commit
      return Rugged::Commit.create($git_repo, commit_opts) if tree.length != 0 || empty

      master.oid
    end
  end
end
