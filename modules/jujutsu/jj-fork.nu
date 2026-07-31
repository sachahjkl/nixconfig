def remote-names [] {
  jj git remote list | lines | parse "{name} {url}" | get name
}

if "upstream" not-in (remote-names) {
  jj git remote rename origin upstream
}

if "origin" not-in (remote-names) {
  gh repo fork --remote --remote-name origin
}

# The global default intentionally fetches only origin; forks need both sides.
jj git fetch --remote origin --remote upstream
jj bookmark track (jj config get 'revset-aliases."trunk()"' | split row "@" | first)
