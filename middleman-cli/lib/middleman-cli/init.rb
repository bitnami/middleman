# CLI Module
module Middleman::Cli
  # A thor task for creating new projects
  class Init < Thor
    include Thor::Actions
    check_unknown_options!

    namespace :init

    desc 'init TARGET [options]', 'Create new project at TARGET'
    method_option 'template',
                  aliases: '-T',
                  default: 'middleman/middleman-templates-default#rename_config',
                  desc: 'Use a project template'

    # Do not run bundle install
    method_option 'skip-bundle',
                  type: :boolean,
                  aliases: '-B',
                  default: false,
                  desc: 'Skip bundle install'

    # The init task
    # @param [String] name
    def init(target='.')
      require 'tmpdir'

      repo_path, repo_branch = if shortname?(options[:template])
        require 'open-uri'
        require 'json'

        api = 'http://directory.middlemanapp.com/api'
        uri = ::URI.parse("#{api}/#{options[:template]}.json")

        begin
          data = ::JSON.parse(uri.read)
          data['links']['github']
          data['links']['github'].split('#')
        rescue ::OpenURI::HTTPError
          puts "Template `#{options[:template]}` not found in Middleman Directory."
          puts 'Did you mean to use a full `user/repo` path?'
          exit
        end
      else
        repo_name, repo_branch = options[:template].split('#')
        [repository_path(repo_name), repo_branch]
      end

      Dir.mktmpdir do |dir|
        cmd = repo_branch ? "clone -b #{repo_branch}" : "clone"

        run("git #{cmd} #{repo_path} #{dir}")

        source_paths << dir

        directory dir, target, exclude_pattern: /\.git\/|\.gitignore$/

        inside(target) do
          run('bundle install')
        end unless ENV['TEST'] || options[:'skip-bundle']
      end
    end

    protected

    def shortname?(repo)
      repo.split('/').length != 2
    end

    def repository_path(repo)
      "git://github.com/#{repo}.git"
    end
  end

  def self.exit_on_failure?
    true
  end

  # Map "i", "new" and "n" to "init"
  Base.map(
    'i' => 'init',
    'new' => 'init',
    'n' => 'init'
  )
end
