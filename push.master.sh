#!/bin/bash

# git commits code both github and gitlab remote script, and branch is master!
# if you want to commits to other branch, you need edit branch is <other> or 
# add a new script!

# Note: if current user does not have permission to execute the script, you need
# execute the following command to give the user permission:
# the command is: `chmod u+x push.master.sh`

# Note, if you alread existing git repository, but remote is origin. And you want
# rename remote, you can execute following command to rename:
# the command is: `git remote rename origin old-origin`

#-------------------------------------------------------------------------------
# git push code to github remote and if you repository need have `github` remote
# Not: if you want associating git repositories, you need need execute following
# command:
# the command is: `git remote add github git@github.com:<your-repository>.git`
# Warning, you should not execute `git push -u <remote> <branch>`

echo "commit to git@github.com ..."
git push github master
echo "Congratulations!"
echo "commit to git@github.com completed and no err"
echo -e "\n"


#-------------------------------------------------------------------------------
# git push code to gitlab remote and if you repository need have `github` remote
# Not: if you want associating git repositories, you need need execute following
# command:
# the command is: `git remote add github git@github.com:<your-repository>.git`
# Warning, you should not execute `git push -u <remote> <branch>`

echo "commit to git@gitLab.com ..."
git push gitlab master
echo "Congratulations!"
echo "commit to git@gitLab.com completed and no err"
