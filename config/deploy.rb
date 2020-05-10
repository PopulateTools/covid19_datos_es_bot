require 'mina/bundler'
require 'mina/git'
require 'mina/rbenv'
require 'mina/deploy'

set :domain, 'populate01'
set :deploy_to, '/var/www/covid19_datos_es_bot'
set :repository, 'git@github.com:PopulateTools/covid19_datos_es_bot.git'
set :branch, 'master'
set :shared_paths, []

set :user, 'ubuntu'
set :port, '22'
set :forward_agent, true
set :shared_files, fetch(:shared_files, []).push('.rbenv-vars')
set :shared_dirs, fetch(:shared_dirs, []).push('vendor/bundle')

desc "Deploys the current version to the server."
task :deploy do
  deploy do
    invoke :'rbenv:load'
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'

    on :launch do
      command %{ps aux | grep 'bot.rb' | grep -v grep | awk '{print $2}' | xargs kill -9}
      command %{sleep 3; export PATH="$HOME/.rbenv/bin:$PATH" ; eval "$(rbenv init -)"; cd #{fetch(:current_path)}; nohup bundle exec ruby bot.rb &}
    end
  end
end
