def resolve-revision [revision: string] {
  do { jj --ignore-working-copy log --no-graph --template commit_id --revisions $revision }
  | complete
  | if $in.exit_code == 0 { $in.stdout }
}

def resolve-revision-in [--remote: any, symbol: string] {
  [(if $remote != null { $"($symbol)@($remote)" }) $symbol]
  | compact
  | where {|candidate| resolve-revision $candidate | is-not-empty }
  | get --optional 0
}

# Open a forge URL locally, cloning the repository to ~/Projects by default.
def main [
  --at: path = ~/Projects
  url: string
] {
  let span = (metadata $url).span
  let url = $url | url parse

  let target = match ($url.path | split row "/" | where { is-not-empty }) {
    [$owner, $repository] => {
      owner: $owner,
      repository: $repository,
      revision: "@",
      file: "."
    }
    [$owner, $repository, _, $revision, ..$file] => {
      owner: $owner
      repository: $repository
      revision: $'"($revision)"'
      file: ($file | path join | default "." --empty)
    }
    _ => {
      error make {
        msg: "not a repository url"
        label: {
          text: "expected <owner>/<repository>"
          span: $span
        }
      }
    }
  }
  | insert line ($url.fragment | parse --regex 'L(?<line>\d+)' | get --optional line.0)

  let repository_url = {
    scheme: $url.scheme
    host: $url.host
    path: $"/($target.owner)/($target.repository)"
  }
  | url join

  do --env {
    let destination = $at | path join $target.repository
    if not ($destination | path exists) {
      jj git clone $repository_url $destination
    }
    cd $destination
  }

  let remote = do {
    let existing = jj git remote list
    | lines
    | parse "{name} {url}"
    | where {|remote| $remote.url | str replace --regex '\.git$' "" | str ends-with $"($target.owner)/($target.repository)" }
    | get --optional name.0

    if $existing != null {
      return $existing
    }

    jj git remote add $target.owner $repository_url
    $target.owner
  }

  let symbol = do {
    let symbol = resolve-revision-in --remote $remote $target.revision
    if $symbol != null {
      return $symbol
    }

    jj git fetch --remote $remote
    let symbol = resolve-revision-in --remote $remote $target.revision
    if $symbol == null {
      error make {
        msg: $"unknown revision: ($target.revision)"
        label: {
          text: "from here"
          span: $span
        }
      }
    }
    $symbol
  }

  if (resolve-revision $"($symbol) & @ | ($symbol) & @-" | is-empty) {
    jj new $symbol
  }

  exec $env.EDITOR (match $target.line {
    null => $target.file
    $line => $"($target.file):($line)"
  })
}
