module MiqExport
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

  end
end
