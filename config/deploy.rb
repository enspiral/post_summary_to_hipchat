# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'post_summary_to_hipchat'
set :repo_url, 'git@github.com/enspiral/fetch(application).git'
set :scm, :git

task :production do
  set :user, "notifiers"
  set :domain, "craftworks.enspiral.info"
  set :branch, "master"
  set :deploy_to, "/home/notifiers/fetch(application)/"

  role :web, fetch(:domain)
  role :app, fetch(:domain)
  role :db, fetch(:domain), :primary => true
end


namespace :deploy do
  task :start do ; end
  task :stop do ; end
end

