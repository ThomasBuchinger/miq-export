module MiqFlowExport
  module Settings
    def self.set_defaults(settings={})
      # Working stuff
      #
      # This tag is used to find/mark the last successful export
      settings[:tag_name]        = 'LAST_EXPORT'
      # Additional tags for a successful expor
      settings[:add_tags]        = []
      # Name of temporary branch the script uses while exporting
      settings[:work_branch]     = 'tmp_export'
      # conflict branch
      settings[:conflict_branch] = 'tmp_conflict'
      # commit message for the merge commit
      settings[:message] = "Automatic export #{Time.now.iso8601(0)}"
      settings[:author]  = 'ghost'
      settings[:mail]    = 'ghost@graveyard.rip' 

      # git stuff
      #
      # path or URL to the git repo
      settings[:git_repo] = 'https://github.com/ThomasBuchinger/automate-example'
      # local working dir
      settings[:export_dir] = '/root/export'
      # merge cahnges into relase_branch
      settings[:release_branch] = 'master'

      # merge options
      # @see https://git-scm.com/docs/git-merge
      #
      # prefer the exported od the release branch version in case of conflicts
      settings[:prefer] = 'export'
      # ignore whitespace changes
      settings[:ignore_space] = 'yes'
      # to not try to find renames (the yaml files are too smilar)
      settings[:renames] = 'no'
      # always create a commit, even empty ones
      settings[:fast_forward] = 'no'

      settings
    end

    def self.update_settings(settings={}, new_settings={})
      new_settings.each do |key, value|
        settings[key.to_sym] = value
      end
      settings
    end

  end
end
