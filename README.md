API Mate
========

API Mate is a web application (a simple web page) to access the APIs of [BigBlueButton](http://bigbluebutton.org) and [Mconf](http://mconf.org).

Usage
-----

Open `lib/api_mate.html` in your browser or check http://mconf.github.com/api-mate to use it.

Development
-----------

At first, install [Node.js](http://nodejs.org/) (see `package.json` for the specific version required).

Install the dependencies with:

    npm install

Then, to compile the source files with:

    cake build

This will compile all files inside `src/` to formats that can be opened in the browser that will be put into `/lib`.

To watch for changes and compile the files automatically run:

    cake watch

License
-------

Distributed under The MIT License (MIT), see `LICENSE`.
