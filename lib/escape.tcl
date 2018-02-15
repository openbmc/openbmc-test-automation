#!/usr/bin/wish

# This file provides many valuable quote and metachar escape processing
# procedures.


proc escape_bash_quotes { buffer } {

  # Do a bash-style escape of all single quotes in the buffer and return the
  # result.

  # In bash, if you wish to have a single quote (i.e. apostrophe) inside
  # single quotes, you must escape it.

  # For example, the following bash command:
  # echo 'Mike'\''s dog'
  # Will produce the following output.
  # Mike's dog

  # So, if you pass the following string to this procedure:
  # Mike's dog
  # This procedure will return the following:
  # Mike'\''s dog

  # Description of argument(s):
  # buffer                          The string whose single quotes are to be
  #                                 escaped.

  regsub -all {'} $buffer {'\''} new_buffer
  return $new_buffer

}


proc quotes_to_curly_braces { buffer } {

  # Convert a single-quoted string to a curly brace-quoted string and return
  # the result.

  # This procedure can help in converting bash expressions, which are quoted
  # with single quotes, to equivalent TCL expressions which are quoted with
  # curly braces.  This procedure will recognize and preserve a bash single
  # quote escape sequence: '\''

  # Description of argument(s):
  # buffer                          The string whose quotes are to be
  #                                 converted to curly braces.

  # For example, the following code...

  # set buffer {'Mike'\''s dog'}
  # print_var buffer
  # set buffer [quotes_to_curly_braces $buffer]
  # print_var buffer

  # Would produce the following result:
  # buffer:     'Mike'\''s dog'
  # buffer:     {Mike's dog}

  set quote {'}

  set return_buffer {}

  set inside_quotes 0

  # In a bash string "'\''" is an escaped quote which we wish to convert to a
  # single quote.
  set place_holder {supercaliforniaplace_holder}
  regsub -all {'\\''} $buffer ${place_holder} buffer

  # Walk the string one character at a time.
  for {set ix 0} {$ix < [string length $buffer]} {incr ix} {
    set char [string index $buffer $ix]
    if { $char == $quote } {
      # Processing a quote.  inside_quotes will tell us whether we've come
      # across a left quote or a right quote.
      if { $inside_quotes == 0 } {
        # Processing closing quote.  Add a left curly brace to return_buffer
        # and discard the quote char.
        set return_buffer "${return_buffer}\{"
        # Set inside_quotes to indicate we are now waiting for a closing quote.
        set inside_quotes 1
      } else {
        # Processing opening quote.  Add a right curly brace to return_buffer
        # and discard the quote char.
        set return_buffer "${return_buffer}\}"
        # Clear inside_quotes to indicate we have found our closing quote.
        set inside_quotes 0
      }
    } else {
      # For non-quote character, simply add it to the return buffer/
      set return_buffer "${return_buffer}${char}"
    }
  }

  regsub -all ${place_holder} $return_buffer {'} return_buffer

  return $return_buffer

}


proc curly_braces_to_quotes { buffer } {

  # Convert a curly brace-quoted string to a single-quoted string and return
  # the result.

  # This procedure can help in converting TCL expressions, which are quoted
  # with curly braces, to equivalent bash expressions which are quoted with
  # single quotes.  This procedure will first convert single quotes to the
  # bash escaped single quote sequence: '\''

  # Description of argument(s):
  # buffer                          The string whose curly braces are to be
  #                                 converted to single quotes.

  # For example, the following buffer value:
  # echo {Mike's dog}
  # Will be changed to this:
  # echo 'Mike'\''s dog'

  regsub -all {[\{\}]} [escape_bash_quotes $buffer] {'} new_buffer
  return $new_buffer

}


