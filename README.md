# Git Deploy for Crystal

Easily set up deploy scripts using githooks. 

## Installation

#### OSX Homebrew

`brew install elorest/crystal/git_deploy`

#### Everything Else

clone, cd and run make :)

## Usage

```sh
> git_deploy
command [OPTIONS] PATH

Arguments:
  PATH  ssh path. Example: deploy@example.com:/home/deploy/www/website

Options:
  -e, --environment  environment
                     (default: AMBER_ENV=production)
  -r, --remote       deployment remote for git. Default: production
                     (default: production)
```

#### Example:

`git_deploy -r production -e 'PORT=80 AMBER_ENV=production' deploy@example.com:/home/deploy/crystalweb`

## Contributing

1. Fork it ( https://github.com/elorest/git_deploy/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [elorest](https://github.com/elorest) Isaac Sloan - creator, maintainer
