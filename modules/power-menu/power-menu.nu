#!@nushell@

const actions = [lockscreen logout suspend hibernate reboot shutdown]

def action-text [action: string] {
  match $action {
    "lockscreen" => "lock screen"
    "logout" => "log out"
    "suspend" => "suspend"
    "hibernate" => "hibernate"
    "reboot" => "reboot"
    "shutdown" => "shut down"
  }
}

def action-icon [action: string] {
  match $action {
    "lockscreen" => "\u{f033e}"
    "logout" => "\u{f0343}"
    "suspend" => "\u{f04b2}"
    "hibernate" => "\u{f02ca}"
    "reboot" => "\u{f0709}"
    "shutdown" => "\u{f0425}"
  }
}

def message [action: string, --confirmation] {
  let text = if $confirmation {
    $"Yes, (action-text $action)"
  } else {
    action-text $action | str capitalize
  }

  $"\u{200e}<span font_size=\"medium\">(action-icon $action)</span> \u{2068}<span font_size=\"medium\">($text)</span>\u{2069}"
}

def validate-actions [option: string, selected: list<string>] {
  let invalid = $selected | where {|action| not ($action in $actions) }
  if not ($invalid | is-empty) {
    print --stderr $"Invalid choice in ($option): ($invalid | str join ', ')"
    exit 1
  }
}

def run-action [action: string] {
  match $action {
    "lockscreen" => {
      let session = $env.XDG_SESSION_ID?
      if $session == null {
        ^@loginctl@ lock-session
      } else {
        ^@loginctl@ lock-session $session
      }
    }
    "logout" => { ^@uwsm@ stop }
    "suspend" => { ^@systemctl@ suspend }
    "hibernate" => { ^@systemctl@ hibernate }
    "reboot" => { ^@systemctl@ reboot }
    "shutdown" => { ^@systemctl@ poweroff }
  }
}

def main [
  ...selection: string
  --choices: string = "lockscreen/logout/suspend/hibernate/shutdown/reboot"
  --confirm: string = "reboot/shutdown/logout"
  --choose: string
  --dry-run
] {
  let shown = $choices | split row "/"
  let confirmations = $confirm | split row "/"
  validate-actions "--choices" $shown
  validate-actions "--confirm" $confirmations

  if $choose != null {
    validate-actions "--choose" [$choose]
  }

  let selected = if not ($selection | is-empty) {
    $selection | str join " "
  } else if $choose != null {
    message $choose
  } else {
    null
  }

  print $"\u{0}no-custom\u{1f}true"
  print $"\u{0}markup-rows\u{1f}true"

  if $selected == null {
    print $"\u{0}prompt\u{1f}Power menu"
    for action in $shown {
      print $"(message $action)\u{0}icon\u{1f}(action-icon $action)"
    }
    return
  }

  let cancel = $"\u{200e}<span font_size=\"medium\">\u{f0156}</span> \u{2068}<span font_size=\"medium\">No, cancel</span>\u{2069}"
  if $selected == $cancel {
    return
  }

  for action in $shown {
    if $selected == (message $action) and $action in $confirmations {
      print $"\u{0}prompt\u{1f}Are you sure"
      print $"(message $action --confirmation)\u{0}icon\u{1f}(action-icon $action)"
      print $"($cancel)\u{0}icon\u{1f}\u{f0156}"
      return
    }

    if $selected == (message $action) or $selected == (message $action --confirmation) {
      if $dry_run {
        print --stderr $"Selected: ($action)"
      } else {
        run-action $action
      }
      return
    }
  }

  print --stderr $"Invalid selection: ($selected)"
  exit 1
}
