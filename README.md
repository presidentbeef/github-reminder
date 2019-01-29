# GitHub Reminder

*Warning: This code is currently a work-in-progress and changing rapidly!*

This is a little Ruby script to check repositories for open issues that need attention.

It can then send an email reminder about outstanding issues.

Right now, "outstanding issues" are issues with no comments.

## Dependencies

Just Ruby!

## Running

    github-reminder --config-file YOUR-CONFIG-FILE.json

## Options

    -c, --config-file FILE           Specify configuration file to use
    -g, --generate-config            Generate configuration file to use

    -d, --[no-]display-issues        Write issue reports to console (Default)
    -e, --[no-]email-issues          Send issues via email (Default)

    -h, --help                       Display help message

## Configuration

GitHub Reminder needs a lot of information.

The easiest way to provide that information is to generate a skeleton configuration file:

    github-reminder --generate-config --config-file github-reminder.json

This will create a configuration file that looks like this:

```json
{
  "github_user": "",
  "github_token": "",
  "mail": {
    "server": {
      "host": "",
      "port": 465,
      "user": "",
      "password": "",
      "ignore_tls_failure": false
    },
    "sender_address": "",
    "receiver_address": ""
  },
  "repos": [
    {
      "owner": "",
      "name": ""
    }
  ]
}
```

### GitHub

*github_user*

This is the user name you will use to access the GitHub API.

*github_token*

You will need to generate a GitHub Access Token, otherwise you will run into rate limits when using the GitHub API.

Go [here](https://github.com/settings/tokens) to create a new token. You do not need to grant it access to any OAuth scopes.

### Email

You can leave the email section alone if you don't want to receive email reminders.

*sender_address*

"From" email address.

*receiver_address*

"To" email address.

#### Server

*host*

Host name of your email server. 

*port*

The port to use for outgoing (SMTP) mail on your email server.

*user*

The username for your outgoing mail server.

*password*

The password for your outgoing email server.

*ignore_tls_failure*

It's sad, but sometimes email servers are awful and you have to ignore certificate failures.

**Only use this option if you know what you are doing!**

### Repos

You may set up multiple GitHub repos for monitoring.

*owner*

The user name or organization for the repo. E.g., the `presidentbeef` in `presidentbeef/github-reminder`.

*name*

The name of the GitHub repository. E.g., the `github-reminder` in `presidentbeef/github-reminder`.

## Use with FaaStRuby

[FaaStRuby](https://faastruby.io/) can be used to run GitHub Reminder in the cloud.

Clone this repo:

    git clone https://github.com/presidentbeef/github-reminder.git

Generate a configuration file:

    ./bin/github-reminder --generate-config --config-file ../github-reminder.json

(Note: You do *not* want the configuration file with your passwords in the github-reminder directory.)

Edit `../github-reminder.json` as described above.

Install FaaStRuby:

    gem install faastruby

Create a workspace:

    faastruby create-workspace YOUR_WORKSPACE_NAME --email YOUR_EMAIL

Edit `faastruby.yml` to adjust name of the job and frequency, if desired.

Deploy:

    faastruby deploy-to YOUR_WORKSPACE_NAME

Update the configuration:

    cat ../github_reminder.json | base64 -w0 | faastruby update-context YOUR_WORKSPACE_NAME --stdin

This way the configuration [is encrypted](https://faastruby.io/getting-started/#execution-context) on the server.

You can use curl to test the setup by hitting the endpoint displayed after deploying.

Otherwise, it should run on the schedule you have set.

## License

MIT
