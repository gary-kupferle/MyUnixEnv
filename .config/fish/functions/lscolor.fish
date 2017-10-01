# This lists all files in the current directory, but files
# with certain extensions are output with specific colors.
# There are default colors for files with
# the extensions .html, .css, .js, and .scss files.
# These can be overridden and colors for other file extensions
# can be specified with arguments of the form extension=color.
# Files with unspecified extensions have a default color of white.
# For example, lscolor fish=magenta js=cyan
function lscolor
  # Default colors
  set cssColor 'green'
  set defaultColor 'white'
  set htmlColor 'blue'
  set jsColor 'red'
  set scssColor 'green'

  # Use colors specified in switches.
  for arg in $argv
    set pieces (string split '=' $arg)
    set extension $pieces[1]
    set color $pieces[2]
    set varName $extension'Color'
    set $varName $color
  end

  for file in (ls -1)
    set_color $defaultColor
    set pieces (string split '.' $file)
    if test (count $pieces) -ge 2
      set extension $pieces[2]
      set varName $extension'Color'
      set color $$varName
      if test -n "$color"; set_color $color; end
    end
    echo $file
  end
end
