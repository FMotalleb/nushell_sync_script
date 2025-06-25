#!/usr/bin/env

def "gh latest tag" [repo: string]: nothing -> string {
  http get $"https://api.github.com/repos/($repo)/releases/latest"
    | get tag_name
}

export def "main" [] {
  let plugin_repository = "nushell/nushell"
  let plugin_version = (gh latest tag $plugin_repository)
  let toml = (open Cargo.toml)
  mut deps = ($toml | get dependencies)
  let fields = (
    $toml 
        | get dependencies 
        | columns | where ($it =~ "nu-.*") 
        | each {|i| }
    )
  for i in $fields {
    print ($deps | get $i)
    $deps = (
      $deps 
        | update $i (
          $deps | get $i | update version $plugin_version
        )
    )
  }
  $toml 
    | update package (
      $toml 
        | get package 
        | update version $plugin_version
    )
    | update dependencies $deps 
    | save Cargo.toml --force

  open nupm.nuon 
    | update version $plugin_version
    | save nupm.nuon --force
  cargo update
  git commit -am $"bump: nushell plugin/protocol to ($plugin_version)"
}