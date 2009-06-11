set :application, "crm-deploy"
set :deploy_to, "/home/deploy/public_html/#{application}"
set :user, "deploy"


set :scm, :git
set :repository, "git://github.com/deepu/fat_free_crm.git"
set :scm_username, "deepu"
set :branch, "master"
set :use_sudo, false
set :repository_cache, "git_cache"
set :deploy_via, :checkout
set :git_shallow_clone, 1
set :ssh_options, { :forward_agent => true }
default_run_options[:pty] = true


# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

# role :app, "206.251.76.234"
#role :app, "206.251.76.106"
# role :web, "your web-server here"

role :app, "8.12.160.242"

#role :db,  "your db-server here", :primary => true
namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
   run "mkdir #{deploy_to}/shared/log"
   run "touch #{deploy_to}/shared/log/production.log"
   run "touch #{current_path}/tmp/restart.txt"
  end
 
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end

