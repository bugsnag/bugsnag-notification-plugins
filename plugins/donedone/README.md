## Work in Progress
I think all the code is set up properly, but the test fails while making the HTTP request. Help?

### spike

    $ coffee index.coffee --subdomain=example --projectId=123 --username=jjulian --apitoken=SECRET --defaultFixerId=99 --defaultTesterId=99 --defaultPriorityId=1 --spike

    events.js:72
    throw er; // Unhandled 'error' event
    ^
    Error: incorrect header check
    at Zlib._binding.onerror (zlib.js:295:17)

### new issue

    $ coffee index.coffee --subdomain=example --projectId=123 --username=jjulian --apitoken=SECRET --defaultFixerId=99 --defaultTesterId=99 --defaultPriorityId=1 --createdIssue=abc,def

    events.js:72
    throw er; // Unhandled 'error' event
    ^
    Error: incorrect header check
    at Zlib._binding.onerror (zlib.js:295:17)
