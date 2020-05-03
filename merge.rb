#!/usr/bin/env ruby

working_dir = File.expand_path('./..')
monorepo_dir = File.expand_path(__dir__)

Repo = Struct.new(:name, :url, :branch)
repos = [
  Repo.new('rspec',              'git@github.com:rspec/rspec.git'),
  Repo.new('rspec-core',         'git@github.com:rspec/rspec-core.git'),
  Repo.new('rspec-expectations', 'git@github.com:rspec/rspec-expectations.git'),
  Repo.new('rspec-mocks',        'git@github.com:rspec/rspec-mocks.git'),
  Repo.new('rspec-support',      'git@github.com:rspec/rspec-support.git')
]

# This is a tag for the base of the mono-repo
commit = "mono-repo-base"

# Merge sub repos into the mono repo while keeping the commit history.
# 1bf79d2bf is the initial commit of the mono-repo without the sub repos
# to prevent merge conflicts
%w[master].each do |branch|
  %x(
    cd #{monorepo_dir}
    git checkout #{commit}
    git checkout -b #{branch}
  )
  repos.each do |repo|
    repo.branch = branch
    # Check out the sub repo and move all files to a sub directory
    # with the same name as the repo.
    # Merge the sub repo into the mono repo while keeping history.
    %x(
      cd #{working_dir}
      rm -rf #{repo.name}
      git clone #{repo.url} #{repo.name}
      cd #{repo.name}
      mkdir #{repo.name}
      git fetch --tags
      git checkout -b #{repo.branch} origin/#{repo.branch}
      git mv -k * #{repo.name}
      git mv -k {.[!.]*,..?*} #{repo.name}
      git commit -m 'Moving #{repo.name} into its own subdirectory'
      cd #{monorepo_dir}
      git remote add #{repo.name} ../#{repo.name}
      git fetch #{repo.name}
      git merge --allow-unrelated-histories --ff #{repo.name}/#{repo.branch}
      git remote remove #{repo.name}
    )
    # rspec-expectations and rspec-mocks both moved License.txt to LICENSE.md.
    # Resolve this merge conflict by removing License.txt and adding the
    # LICENSE.md for both sub repos.
    %x(
      cd #{monorepo_dir}
      git rm --ignore-unmatch License.txt
      git add rspec-expectations/LICENSE.md
      git add rspec-mocks/LICENSE.md
      git commit -m 'Fix merge conflict'
    )
  end

  %x(
    mkdir script
    cd #{monorepo_dir}
    mkdir -p script
    cp rspec-core/script/functions.sh script
    cp rspec-core/script/predicate_functions.sh script
    cp rspec-core/script/travis_functions.sh script
    cp rspec-core/script/update_rubygems_and_install_bundler script
    cp rspec-core/.travis.yml .
    cp rspec-core/maintenance-branch .
    touch script/clone_all_rspec_repos
  )

  # create scripts for CI
  run_build = <<~RUN_BUILD
    #!/bin/bash
    set -e
    function run_build_for {
      if [ ! -f ./$1/$SPECS_HAVE_RUN_FILE ]; then # don't rerun specs that have already run
        if [ -d ./$1 ]; then
          echo "Running specs for $1"
          pushd ./$1
          bundle install --binstubs --standalone --without documentation --path ../bundle
          script/run_build
          popd
        else
          echo ""
          echo "WARNING: The ./$1 directory does not exist. Usually the"
          echo "travis build cds into that directory and run the specs to"
          echo "ensure the specs still pass with your latest changes, but"
          echo "we are going to skip that step."
          echo ""
        fi;
      fi;
    }
    run_build_for "rspec-core"
    run_build_for "rspec-expectations"
    run_build_for "rspec-mocks"
    run_build_for "rspec-support"
  RUN_BUILD
  File.write(File.join(monorepo_dir, 'script/run_build'), run_build)

  %x(
    chmod +x script/run_build
    git add script .travis.yml maintenance-branch
    git commit -m 'Add CI scripts'
  )
end
