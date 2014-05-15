# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'post_summary_to_hipchat'
set :repo_url, 'git@github.com/ayumi5/#{application}.git'

set :stage, :production
server 'craftworks.enspiral.info', roles: %w{web app db assets}, user: 'notifiers' 
# Default value for :scm is :git
set :scm, :git

task :production do
  set :user, "notifiers"
  set :domain, "craftworks.enspiral.info"
  set :branch, "master"
  set :deploy_to, "/home/notifiers/#{application}/"

  role :web, domain
  role :app, domain
  role :db, domain, :primary => true
end


namespace :deploy do
  task :start do ; end
  task :stop do ; end
end

