# Rig Installer Demo
# Usage: vhs demo.tape

Output demo.gif
Set Shell "bash"
Set FontSize 18
Set Width 1400
Set Height 900
Set Padding 24
Set Framerate 30
Set TypingSpeed 35ms
Set Theme { "name": "Catppuccin Mocha", "black": "#45475a", "red": "#f38ba8", "green": "#a6e3a1", "yellow": "#f9e2af", "blue": "#89b4fa", "magenta": "#f5c2e7", "cyan": "#89dceb", "white": "#cdd6f4", "brightBlack": "#585b70", "brightRed": "#f38ba8", "brightGreen": "#a6e3a1", "brightYellow": "#f9e2af", "brightBlue": "#89b4fa", "brightMagenta": "#f5c2e7", "brightCyan": "#89dceb", "brightWhite": "#a6adc8", "background": "#1e1e2e", "foreground": "#cdd6f4", "selection": "#45475a", "cursor": "#f5e0dc" }

Sleep 500ms

Type "curl -fsSL https://ba.sh/rig | bash"
Sleep 300ms
Enter
Sleep 2s

# Toggle all on with 'a'
Type "a"
Sleep 1.2s

# Toggle all off
Type "a"
Sleep 800ms

# Navigate to uv (index 5): Down x5
Down
Sleep 120ms
Down
Sleep 120ms
Down
Sleep 120ms
Down
Sleep 120ms
Down
Sleep 120ms
Space
Sleep 350ms

# Select go (index 6): Down x1
Down
Sleep 120ms
Space
Sleep 350ms

# Pause to show selection
Sleep 1.5s

# Confirm
Enter
Sleep 2s

# Plan shown, proceed
Type "y"
Enter

# Wait for downloads + installation
Sleep 8s

# Show final result
Sleep 4s
