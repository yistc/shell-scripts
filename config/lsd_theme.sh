#! /bin/bash

# lsd theme
mkdir -p /root/.config/lsd/themes
cat > /root/.config/lsd/config.yaml << EOF
color:
  theme: yistc
EOF

cat > /root/.config/lsd/themes/yistc.yaml << EOF
user: 135
group: 214
permission:
  read: dark_green
  write: dark_yellow
  exec: dark_red
  exec-sticky: 5
  no-access: 245
  octal: 6
  acl: dark_cyan
  context: cyan
date:
  hour-old: 40
  day-old: 42
  older: 36
size:
  none: 245
  small: 32
  medium: 216
  large: 172
inode:
  valid: 13
  invalid: 245
links:
  valid: 13
  invalid: 245
tree-edge: 245
EOF