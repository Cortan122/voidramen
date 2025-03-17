# docs for this file:
# config nu --doc | nu-highlight | less -R

$env.config.cursor_shape.emacs = "line"
$env.config.show_banner = false
$env.config.completions.quick = true
$env.config.shell_integration.osc133 = false
$env.config.shell_integration.osc7 = false
$env.config.shell_integration.osc8 = false

$env.config.hooks.command_not_found = {
  |cmd_name| (
    try {
      let pkgs = (pkgfile --binaries --verbose -- $cmd_name)
      if ($pkgs | is-empty) {
        return null
      }

      print -e (
        $"(ansi $env.config.color_config.shape_external)($cmd_name)(ansi reset) " +
        $"may be found in the following packages:\n($pkgs)"
      )
    }
  )
}

$env.config.keybindings ++= [
  {
    name: ctlr_backspace
    modifier: control
    keycode: char_h
    mode: [emacs, vi_insert, vi_normal]
    event: { edit: BackspaceWord }
  }
]
