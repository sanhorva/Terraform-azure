#!/bin/bash
 sudo apt update -y && sudo apt install -y docker.io
 sudo sysmtemctl start docker            
 sudo usermod -aG docker adminuser

