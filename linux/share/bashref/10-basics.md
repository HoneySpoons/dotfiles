# Where am I, and what's here

    pwd                 print working directory — where you are right now
    ls                  list files here
    ls -l               long form: permissions, size, date
    ls -la              ...including hidden files (the dotfiles)
    cd foo              go into folder foo
    cd ..               go UP one level
    cd                  go home (~), from anywhere
    cd -                go back to where you just were

`~` means your home folder. `.` means here. `..` means one up.

**Tab is the most important key in the shell.** Type the first few letters of a
name and press Tab — it completes it. Press Tab twice to see all the options.
You should almost never type a full filename by hand.

# Looking at a file

    cat file.txt        dump the whole thing to the screen
    less file.txt       page through it  (q to quit, / to search, n = next hit)
    head file.txt       first 10 lines
    tail file.txt       last 10 lines
    tail -f server.log  keep watching as new lines arrive   (Ctrl+C to stop)

# Making and moving things

    mkdir notes         make a folder
    mkdir -p a/b/c      make the whole path, no complaints if it exists
    touch file.txt      create an empty file / update its timestamp
    cp a.txt b.txt      copy
    cp -r dir1 dir2     copy a whole folder (-r = recursive)
    mv a.txt b.txt      move OR rename — same command
    rm file.txt         delete a file
    rm -r folder        delete a folder and everything in it

`rm` has no undo and no trash. There is no "are you sure" unless you ask for
one with `rm -i`. Look before you delete.

# Finding things

    grep "todo" file.txt        find lines containing "todo"
    grep -r "todo" .            ...in every file under here
    grep -ri "todo" .           ...case-insensitive
    grep -n "todo" file.txt     ...and show line numbers

    find . -name "*.html"       find files by name
    find . -type d              find folders

# Chaining commands

    command > file       send output INTO a file (overwrites it)
    command >> file      append to the end of a file instead
    command1 | command2  pipe: feed the output of one into the next

    ls | grep site       list files, keep only ones matching "site"
    cat log | tail -20   last 20 lines of a file

The `|` pipe is the whole idea of Unix: small tools, joined end to end.
