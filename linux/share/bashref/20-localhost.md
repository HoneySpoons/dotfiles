# Running a localhost

"Serving on localhost:4200" means a program on YOUR machine is answering web
requests on port 4200. Nothing is public. `localhost` and `127.0.0.1` are the
same thing: this computer.

    python3 -m http.server 8000        serve THIS folder at localhost:8000
    npx serve                          same idea, if the project is node
    npm run dev                        most JS projects define this themselves

The design-review server for the site:

    python3 ~/Agents/DES/tools/despin/despin.py ~/Projects/changelog-site --port 4200

Then open http://localhost:4200/ in the browser.

**It keeps running until you stop it.** That terminal is now busy. Either open
a new terminal (SUPER+RETURN) or start it in the background — see below.

# Stopping, backgrounding, getting unstuck

    Ctrl+C           stop the thing that's running right now
    Ctrl+D           end input / log out of a shell
    Ctrl+Z           SUSPEND it (paused, not dead)
    bg               resume that suspended job in the background
    fg               pull it back to the foreground
    jobs             list what you've suspended or backgrounded

    command &        start it in the background from the outset
    nohup command &  ...and keep it alive after you close the terminal

# Ports: what's using it, and how to kill it

The most common localhost error is `Address already in use` — something is
already sitting on that port, usually a copy of the thing you just started.

    ss -tlnp | grep 4200        what is listening on port 4200
    lsof -i :4200               same question, different tool
    pkill -f despin.py          kill processes whose command line matches

    ps aux | grep python        list matching processes (gives you the PID)
    kill 12345                  ask process 12345 to stop
    kill -9 12345               make it stop (last resort)

⚠️ `pkill -f <pattern>` matches the WHOLE command line, including the command
you are typing. If the pattern appears in your own command, it can kill your
own shell. Bit me on 2026-08-29. Safer: `pkill -f "python3 despin.py"`, or
find the PID with `ps` first and `kill` that.

# Is it actually up?

    curl -s localhost:4200 | head        fetch the page, show the first lines
    curl -o /dev/null -w "%{http_code}\n" localhost:4200    just the status code

200 = fine. 404 = wrong path. Connection refused = nothing is listening.
