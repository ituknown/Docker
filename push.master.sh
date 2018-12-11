#!/bin/bash

# git commits code both github and gitlab remote script, and branch is master!
# if you want to commits to other branch, you need edit branch is <other> or 
# add a new script!

# Note: if current user does not have permission to execute the script, you need
# execute the following command to give the user permission:
# the command is: `chmod u+x push.master.sh`

#-------------------------------------------------------------------------------
# git push code to github remote and if you repository need have `github` remote
git push github master

#-------------------------------------------------------------------------------
# git push code to gitlab remote and if you repository need have `github` remote
git push gitlab master
