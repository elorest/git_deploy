require "cli"
require "tempfile"
require "colorize"

module GitDeploy
  class Command < ::Cli::Command
    @filename = "./tmp/#{Time.now.epoch_ms}_console.cr"

    class Options
      arg "path", desc: "ssh path. Example: deploy@example.com:/home/deploy/www/website", required: true
      string ["-r", "--remote"], desc: "deployment remote for git. Default: production", default: "production"
      string ["-e", "--environment"], desc: "environment", default: "AMBER_ENV=production"
    end

    class Help
      caption "# It runs Crystal code within the application scope"
    end

    def run
      puts "Make sure that you have setup a non-root user on the server and added your public key to authorized_keys."
      `git remote add #{options.remote} "#{args.path}"`
      host, path = args.path.split(":")
      `ssh #{host} -t 'bash -c "mkdir -p #{path} && cd #{path} && git init && git config receive.denyCurrentBranch ignore"'`
      app_file = Dir.glob("src/*.cr").first
      app_binary = app_file.split("/").last.sub(".cr", "")
      githook = Tempfile.open("post-receive") do |file|
        file.print <<-GITHOOK
        #!/bin/bash
        set -e

        #{args.environment.split(" ").map{|e| "export #{e}"}.join("\n")}

        if [ "$GIT_DIR" = "." ]; then
          # The script has been called as a hook; chdir to the working copy
          cd ..
          unset GIT_DIR
        fi

        # try to obtain the usual system PATH
        if [ -f /etc/profile ]; then
          PATH=$(source /etc/profile; echo $PATH)
          export PATH
        fi

        # get the current branch
        head="$(git symbolic-ref HEAD)"

        # read the STDIN to detect if this push changed the current branch
        while read oldrev newrev refname
        do
          [ "$refname" = "$head" ] && break
        done

        # abort if there's no update, or in case the branch is deleted
        if [ -z "${newrev//0}" ]; then
          exit
        fi

        # check out the latest code into the working copy
        umask 002
        git reset --hard

        logfile=log/deploy.log

        if [ -z "${oldrev//0}" ]; then
          # this is the first push; this branch was just created
          mkdir -p log tmp bin
          chmod 0775 log tmp bin
          touch $logfile
          chmod 0664 $logfile

          # init submodules
          git submodule update --recursive --init 2>&1 | tee -a $logfile
        else
          # log timestamp
          echo ==== $(date) ==== >> $logfile

          ################################################################################
          ####  BEGIN: Amberframework specific Code                                  #####
          ################################################################################

          shards install

          if [ -f bin/amber ]; then
            echo "amber already installed"
          else
            crystal build lib/amber/src/amber/cli.cr -o bin/amber
          fi

          echo "migrating..."
          ./bin/amber db create migrate || true
          echo "building application in release mode"
          crystal build #{app_file} --release --no-debug -o bin/#{app_binary}
          old_pid=`cat tmp/#{app_binary}.pid`
          echo "Killing old process..."
          kill -9 $old_pid || true # Move after start line if PORT_REUSE is on.
          echo "Starting application..."
          nohup ./bin/#{app_binary} >> log/production.log 2>&1 & 
          echo $! > tmp/#{app_binary}.pid

          ################################################################################
          ####  END: Amberframework specific Code                                    #####
          ################################################################################
        fi
        GITHOOK
      end 

      system("vim #{githook.path}")
      
      `scp #{githook.path} #{args.path}/.git/hooks/post-receive`
      `ssh #{host} -t 'chmod u+x #{path}/.git/hooks/post-receive'`
    end
  end
end
