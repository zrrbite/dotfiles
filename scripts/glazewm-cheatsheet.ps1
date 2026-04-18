Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "GlazeWM Keybinds"
$form.Size = New-Object System.Drawing.Size(520, 720)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2E3440")
$form.TopMost = $true
$form.KeyPreview = $true
$form.Add_KeyDown({ if ($_.KeyCode -eq "Escape") { $form.Close() } })

$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $false
$label.Size = New-Object System.Drawing.Size(480, 660)
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Font = New-Object System.Drawing.Font("Consolas", 10)
$label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D8DEE9")
$label.Text = @"
  GLAZEWM CHEATSHEET         [Esc to close]

  FOCUS / MOVE
  Alt + H J K L         Focus direction
  Alt + Shift + H J K L Move window
  Alt + Shift + A F     Move workspace to monitor

  WORKSPACES
  Alt + 1-9             Switch workspace
  Alt + Shift + 1-9     Move window to workspace
  Alt + S / A           Next / prev workspace
  Alt + D               Recent workspace

  WINDOW STATE
  Alt + F               Fullscreen
  Alt + T               Toggle tiling
  Alt + Shift + Space   Toggle floating
  Alt + M               Minimize
  Alt + Shift + Q       Close window
  Alt + V               Toggle split direction
  Alt + Space           Cycle focus type

  RESIZE
  Alt + U / P           Narrow / widen
  Alt + I / O           Shorter / taller

  VOLUME
  Alt + F1              Mute toggle
  Alt + F2 / F3         Volume down / up

  SYSTEM
  Alt + Enter           Windows Terminal
  Alt + Shift + R       Reload config
  Alt + Shift + W       Redraw windows
  Alt + Shift + P       Pause GlazeWM
  Alt + Shift + E       Exit GlazeWM

  MOUSE (AltSnap)
  Alt + Left-drag       Move window
  Alt + Right-drag      Resize window

  Ctrl + Space          PowerToys Run
"@

$form.Controls.Add($label)
$form.ShowDialog() | Out-Null
