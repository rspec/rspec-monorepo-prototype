# RSpec MonoRepo Prototype

This is based off the rfc proposal, work done by @xshay https://github.com/rspec/rspec-core/issues/2509
and @p8 in https://github.com/rspec/rspec/pull/48

# Usage

**Important** This script will execute `rm` against rspec sibling repos, e.g. `rspec/mono` will delete `rspec/rspec-core`

**ENSURE YOU RUN THIS IN AN OTHERWISE EMPTY PARENT REPO**

Also note that this script is history destroying for this repo. PRs containing RSpec commits are not possible as far as I can see.

1) Checkout this repo into an empty dir e.g.

```shell
mkdir -p ~/code/rspec-prototype/mono
cd ~/code/rspec-prototype/mono
git clone https://github.com/rspec/rspec-monorepo-prototype.git .
```

2) Ensure you have a base tag with `git tag -f "mono_repo_base"`

3) Run `ruby merge.rb`
