#!/usr/bin/env bash

rm -R /home/user/upgit
git clone https://github.com/invulmain/upgit /home/user/upgit
chmod +x /home/user/upgit/upgit.sh

/home/user/upgit/upgit.sh

exit 0
