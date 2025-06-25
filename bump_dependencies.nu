#!/usr/bin/env

def "gh latest tag" [repo: string]: nothing -> string {
  http get $"https://api.github.com/repos/($repo)/releases/latest"
    | get tag_name
}

export def "main" [] {
  let plugin_repository = "nushell/nushell"
  let plugin_version = (try {
      http get https://crates.io/api/v1/crates/nu-plugin?include=keywords%2Ccategories%2Cdownloads%2Cdefault_version
        | get versions 
        | first 
        | get num
    } catch { 
      gh latest tag $plugin_repository
    })
  let toml = (open Cargo.toml)
  mut deps = ($toml | get dependencies)
  let fields = (
    $toml 
        | get dependencies 
        | columns | where ($it =~ "nu-.*") 
        | each {|i| }
    )
  for i in $fields {
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
  cargo build
}