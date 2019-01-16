module MiqFlowExport
  module GitMixin

    def find_repo(path, dir)
      return nil unless File.directory?(dir)
      
      repo_name = File.basename(path, '.git')
      return nil unless File.directory?(File.join(dir, repo_name, '.git'))

      $logger.debug("Using existing Repository at #{File.join(dir, repo_name)}")
      return Rugged::Repository.discover(File.join(dir, repo_name))
    end

    def clone_repo(url, dir, cred: nil)
      return nil unless File.directory?(dir)

      repo_name = File.basename(url, '.git')
      $logger.debug("Clone Repository at #{url} to #{dir}/#{repo_name}")
      return Rugged::Repository.clone_at(url, File.join(dir, repo_name))
    end

    def create_index(master, devel, strategy: 'recursive', prefer: nil, ignore_space: 'yes', renames: 'no', **_)
      rename = renames == 'yes' ? true : false

      favor = :normal if strategy == 'recursive' && prefer.nil?
      favor = :ours   if strategy == 'recursive' && prefer == :ours
      favor = :theirs if strategy == 'recursive' && prefer == :theis
      if strategy != 'recursive' && prefer.nil?
        $logger.error('Only recursive sraegies implemened. Aboring while I can')
        raise MiqFlowExport::Error, "Strategy #{strategy} not implmented"
      end

      return $git_repo.merge_commits(master, devel, favor: favor, rename: rename)
    end

    def update_ref(heads: [], tags: [], target:)
      heads.each{ |head| $git_repo.references.update("refs/heads/#{head}", target) }
      tags.each { |tag| $git_repo.references.update("refs/tags/#{tag}", target) }
    end
  
    def create_commit(index, master, devel, empty: false, message: 'AUTO export', author: 'ghost', mail: 'ghost@graveyard.org', time: Time.now, **_)
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
end
