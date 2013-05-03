# marathon-dns

A standalone component extracted from (marathon)[https://github.com/davewasmer/marathon] for enabling custom DNS for local servers. 

# Installation

    npm install marathon -g

Once it finishes, open up your project file (`~/.marathon`), and add any projects you'd like. For example, the following project file:

    {
      "myawesomeapp": 3000 
    }

would setup `http://myawesomeapp.dev` to point to `http://localhost:3000`

That's basically it.