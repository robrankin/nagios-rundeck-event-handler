Nagios Event Handler for RunDeck
===

This is a simple and ugly event handler to fire off a single RunDeck job.  This satisfies my needs, but most probably won't satisfy yours.  Contributions and PRs welcome.

Nagios Setup
---

Nagios Command Definition

```
define command {
    command_name rd_run_job
    command_line $USER1$/rd_run_job.pl "$SERVICESTATE$" "$SERVICESTATETYPE$" "$SERVICEATTEMPT$" "<rundeck username>" "<rundeck password>" "<rundeck url>" "$_SERVICEJOBID$" "$HOSTNAME$" "DEBUG" "1" "$SERVICEOUTPUT$"
}
```

* `$SERVICESTATE$` Nagios Macro providing service state
* `$SERVICESTATETYPE$` Nagios Macro providing state type (CRITICAL SOFT versus CRITICAL HARD for example)
* `$SERVICEATTEMPT$` Nagios Macro for number of check attempts (SOFT 2 or 3 checks for example)
* `<rundeck username>` Your RunDeck user name that can run the jobs
* `<rundeck password>` Your RunDeck password
* `<rundeck url>` Base RunDeck URL (https://rundeck.example.org:4440)
* `$_SERVICEJOBID$` The RunDeck Job ID passed by the Nagios Service Check
* `$HOSTNAME$` Nagios Macro HOSTNAME, acts as a RunDeck Filter (i.e.: `name:$HOSTNAME$`)
* `DEBUG` RunDeck job DEBUG level.
* `1` Enable/Disable checks on valid Service Output messages
* `$SERVICEOUTPUT$` Nagios Macro providing the first line of text output from the last service check  

Nagios Service Definition

```
define service {
    host_name           host1.example.com
    service_description Apache Service
    check_command       check_http_port!80
    event_handler       rd_run_job
    _JOBID              e1a8c9ec-379d-46ca-9e33-6096bde0a17a
}
```

Add the `event_handler` and `_JOBID` Nagios parameters to your Service Check(s).


Event Handler
---
The Event Handler will execute on either:

* CRITICAL SOFT with at least 3 check attempts
* CRITICAL HARD

Command Line Testing
---
```
./rd_run_job.pl "CRITICAL" "HARD" "3" "nagios" "password" "http://rundeck.example.com:4440" "e1a8c9ec-379d-46ca-9e33-6096bde0a17a" "name:hostname.example.com" "DEBUG" "1" "Socket Timeout"
```



ToDo
---
1. Abstract RunDeck Username/Password
2. Abstract RunDeck URL
3. Make it work with Host Checks, not just Service Checks
4. Do smarter things with different state changes
