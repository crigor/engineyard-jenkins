# DEPRECATED

This project is deprecated in favour of [eycloud-app-jenkins](https://github.com/engineyard/eycloud-app-jenkins/).

# Easier to do CI than not to.

Run your continuous integration (CI) tests against your Engine Yard AppCloud environments - the exact same configuration you are using in production!

You're developing on OS X or Windows, deploying to Engine Yard AppCloud (Gentoo/Linux), and you're running your CI on your local machine or a spare Ubuntu machine in the corner of the office, or ... you're not running CI at all?

It's a nightmare. It was for me. 

But now, [Jenkins CI](http://jenkins-ci.org/), the [jenkins](http://github.com/cowboyd/jenkins.rb) CLI project, and **engineyard-jenkins** now make CI easier to do than not to for Engine Yard AppCloud users.

And here's some logos:

<img src="http://img.skitch.com/20101103-gcq2turgih14rjdqatt1kjkd6u.png">

## Installation

    gem install engineyard-jenkins

This will also install the `jenkins` CLI to interact with your Jenkins CI from the command line.

## Hosting on Engine Yard AppCloud

Using Engine Yard AppCloud "Quick Start" wizard, create an application with Git Repo `git://github.com/engineyard/jenkins_holding_page.git` (options: rails 3, passenger), and add your own SSH keys. This will create an environment called `jenkins_server_production`. Boot the environment as a Single instance (or Custom cluster with a single instance). 

Optionally, though it is quite pretty, deploy/ship the `jenkins_holding_page` application and visit the HTTP link to see the remaining "Almost there..." instructions.

Finally, install Jenkins CI and rebuild the environment:

    $ ey-jenkins install_server

When this completes, visit the URL or refresh the "Almost there..." page to see your Jenkins CI server.

Using the `jenkins list` CLI task you can also test there is a working server with no jobs:

*For the Jenkins slaves' configuration, you'll need:*

The `jenkins_server_production` instance public key:

    $ ey ssh -e jenkins_server_production
    # cat /home/deploy/.ssh/id_rsa.pub

Do those steps, copy down the configuration and you're done! Now, you either visit your Jenkins CI site or use `jenkins list` to see the status of your projects being tested.

## Hosting elsewhere

Hosting Jenkins CI on Engine Yard AppCloud is optional; yet delightfully simple. Jenkins CI can be hosted anywhere.

If you host your Jenkins CI elsewhere then you need the following information about your Jenkins CI environment to be able to add EngineYard AppCloud instances as Jenkins nodes/slaves:

* Jenkins CI public host & port
* Jenkins CI's user's public key (probably at `/home/deploy/.ssh/id_rsa.pub`)
* Jenkins CI's user's private key path (probably `/home/deploy/.ssh/id_rsa`)

## Running your CI tests on Engine Yard AppCloud

This is the exciting part - ensuring that your CI tests are being run in the same environment as your production applications. In this case, on Engine Yard AppCloud.

It is assumed that you already have a production application environment (might have multiple applications in it):

<img src="http://img.skitch.com/20101103-k2u4dpnn6ukkwq1dafbtiuwi2s.png">

In the Engine Yard AppCloud UI, create another environment that matches the production environment exactly (same Ruby, same set of applications, same Unix libraries).

<img src="http://img.skitch.com/20101103-h58t3kfrpc2qm4eb6t4664m13.png">

Now, in just a few steps and you will have your applications' tests running in an environment that matches your production environment:

    $ cd /my/project
    $ ey-jenkins install .
    
Now edit `cookbooks/jenkins_slave/attributes/default.rb` to set up the Jenkins CI instance details gathered above.

    $ ey recipes upload -e ci_demo_app_ci
    $ ey recipes apply -e ci_demo_app_ci

Boot your `ci_demo_app_ci` environment, visit your Jenkins CI and WOW! jobs have been created, they are already running, and they are doing it upon your `ci_demo_app_ci` environment!

At any time from the command line you can use `jenkins list` to see the status of your jobs

## Conventions/Requirements

* Do not use your production environment as your Jenkins CI slave. There are no guarantees what will happen. I expect bad things.
* You must name your CI environments with a suffix of `_ci` or `_jenkins_slave`.
* You should not name any other environments with a suffix of `_ci` or `_jenkins_slave`; lest they offer themselves to your Jenkins CI as slave nodes.
* Keep your production and CI environments exactly the same. Use the same Ruby implementation/version, same database, and include the same RubyGems and Unix packages. Why? This is the entire point of the exercise: to run your CI tests in the same environment as your production application runs.

For example, note the naming convention of the two CI environments below (one ends in `_jenkins_slave` and the other `_ci`).

<img src="http://img.skitch.com/20101031-dxnk7hbn32yce9rum1ctwjwt1w.png" style="width: 100%">

## What happens?

When you boot your Engine Yard AppCloud CI environments, each resulting EC2 instance executes a special "jenkins_slave" recipe (see `cookbooks/jenkins_slave/recipes/default.rb` in your project). This does three things:

* Adds this instance to your Jenkins CI server as a slave
* Adds each Rails/Rack application for the AppCloud environment into your Jenkins CI as a "job".
* Commences the first build of any newly added job.

If your CI instances have already been booted and you re-apply the recipes over and over (`ey recipes apply`), nothing good or bad will happen. The instances will stay registered as slaves and the applications will stay registered as Jenkins CI jobs.

If a new application is on the instance, then a new job will be created on Jenkins CI.

To delete a job from Jenkins CI, you should also delete it from your AppCloud CI environment to ensure it isn't re-added the next time you re-apply or re-build or terminate/boot your CI environment. (To delete a job, use the Jenkins CI UI or `jenkins remove APP-NAME` from the CLI.)

In essence, to add new Rails/Rack applications into your Jenkins CI server you:

* Add them to one of your Engine Yard AppCloud CI environments (the one that matches the production environment where the application will be hosted)
* Rebuild the environment or re-apply the custom recipes (`ey recipes apply`)

### Applications are run in their respective CI environment

Thusly demonstrated below: the application/job "ci_demo_app" is in the middle of a build on its target slave "ci_demo_app_ci". See the AppCloud UI example above to see the relationship between the application/job names and the environment/slave names.

<img src="http://img.skitch.com/20101031-tga2f23wems1acpad1ua41qdmb.png" style="width: 100%">

### Can I add applications/jobs to Jenkins CI other ways?

Yes. There are three simple ways to get Jenkins CI to run tests for your application ("create a job to run builds"). Above is the first: all "applications" on the Engine Yard AppCloud CI environment will automatically become Jenkins CI jobs. The alternates are:

* Use the `jenkins create .` command from the [jenkins](http://github.com/cowboyd/jenkins.rb) CLI. 

Pass the `--assigned_node xyz` flag to make the project's test be executed on a specific slave node. "xyz" is the name of another application on your AppCloud account; your tests will be executed on the same instance, with the same version of Ruby etc.

* Use the Jenkins CI UI to create a new job. As above, you can make sure the tests are run on a specific Engine Yard AppCloud instance by setting the assigned node label to be the same as another AppCloud application in your account that is being tested.

Specifically, Jenkins CI uses "labels" to match jobs to slaves. A common example usage is to label a Windows slave as "windows". A job could then be restricted to only running on slaves with label "windows". We are using this same mechanism.

## Automatically triggering job builds

In Jenkins CI, a "job" is one of your projects. Each time it runs your tests, it is called a "build".

It is often desirable to have your SCM trigger Jenkins CI to run your job build whenever you push new code.

### GitHub Service Hooks

* Go to the "Admin" section of your GitHub project
* Click "Service Hooks"
* Click "Post-Receive URLs"
* Enter the URL `http://HUDSON-CI-URL/job/APP-NAME/build`
* Click "Update Settings"

And here's a picture.

<img src="http://img.skitch.com/20101031-d5wrc7hysrahihqr9k53xgxi1t.png" style="width: 100%;">

You can also use the "Test Hook" link to test this is wired up correctly.

### CLI

Using the `jenkins` CLI:

    jenkins build path/to/APP-NAME

### Curl

You are triggering the build via a GET call to an URL endpoint. So you can also use `curl`:

    curl http://HUDSON-CI-URL/job/APP-NAME/build

## Contributions

* Dr Nic Williams ([drnic](http://github.com/drnic))
* Bodaniel Jeanes ([bjeanes](http://github.com/bjeanes)) - initial chef recipes for [Jenkins server + slave](http://github.com/bjeanes/ey-cloud-recipes)

## License

Copyright (c) 2010 Dr Nic Williams, Engine Yard

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.