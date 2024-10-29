#!/bin/sh

# it would've been much easier to just call `firefox --private-window`
# so that's what i'm gonna do...
# fuck all that old code!
firefox --private-window &
sleep 0.2
i3-msg '[class="firefox"] focus'
