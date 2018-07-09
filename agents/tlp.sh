#!/bin/bash

dnf install powertop tlp

systemctl enable powertop
systemctl start powertop
systemctl restart powertop
systemctl enable tlp
systemctl start tlp
systemctl restart tlp
