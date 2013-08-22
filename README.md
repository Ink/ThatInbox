ThatInbox
=========

ThatInbox is simple, elegant, and free new way to do your email on an iPad. It's completely free and open source.

ThatInbox connects with Ink so that you work with 3your attachments in other applications. Some of our favorite Ink workflows with ThatInbox:
* Sign email attachments and send them back as a reply.
* Take photos sent to from your family, touch them up with filters and red-eye reduction, and store them in the Cloud or post them on Facebook.
* Grab the most recent customer proposal that your coworker sent you and add it to Evernote.

Other great features of ThatInbox:
* View all of your emails with attachments in one place.
* Connects to your address book so you can get your work done faster.
* Only works with Gmail.

The full list of features is detailed in our [blog post](http://blog.inkmobility.com/post/58944353684/thatinbox-the-mail-client-for-attachments).

ThatInbox is also currently available on the [App Store](https://itunes.apple.com/app/thatinbox/id683470283?mt=8)

![ThatInbox in action](http://a3.mzstatic.com/us/r30/Purple6/v4/00/5a/2b/005a2b4b-9d1f-5b11-9697-7cb829301fc2/screen1024x1024.jpeg)

License
-------
ThatInbox is an open-source iOS application built by [Ink](www.inkmobility.com), released under the MIT License. You are welcome to fork this app, and pull requests are always encouraged.

The email library is [MailCore](https://github.com/MailCore/mailcore2) and the UX components is [FlatUIKit](https://github.com/Grouper/FlatUIKit) from [Grouper](https://www.joingrouper.com/). Both of the projects have been highly helpful and we've collaborated on a couple fixes.

How To Contribute
-------------------------
Glad you asked! ThatInbox is based on the [Git flow](http://nvie.com/posts/a-successful-git-branching-model/) development model, so to contribute, please make sure that you follow the git flow branching methodology.

Currently ThatInbox supports iOS6 on iPads. Make sure that your code runs in both the simulator and on an actual device for this environment.

Once you have your feature, improvement, or bugfix, submit a pull request, and we'll take a look and merge it in. We're very encouraging of adding new owners to the repo, so if after a few pull requests you want admin access, let us know.

Every other Thursday, we cut a release branch off of develop, build the app, and submit it to the iOS App Store.

If you're looking for something to work on, take a look in the list of issues for this repository. And in your pull request, be sure to add yourself to the readme and authors file as a contributor.


What are the "That" Apps?
-------------------------

To demonstrate the power Ink mobile framework, Ink created the "ThatApp" suite of sample apps. Along with ThatInbox, there is also [ThatPDF](https://github.com/Ink/ThatPDF) for editing pdfs, [ThatPhoto](https://github.com/Ink/ThatPhoto) for editing your photos and [ThatCloud](https://github.com/Ink/ThatCloud) for accessing files stored online. But we want the apps to do more than just showcase the Ink Mobile Framework. That's why we're releasing the apps open source. 

As iOS developers, we leverage an incredible amount of software created by the community. By releasing these apps, we hope we can make small contribution back. Here's what you can do with these apps:
  1. Use them!
    
  They are your apps, and you should be able to do with them what you want. Skin it, fix it, tweak it, improve it. Once you're done, send us a pull request. We build and submit to the app store every other week on Thursdays.
  
  2. Get your code to the app store 

  All of our sample apps are currently in the App store. If you're just learning iOS, you can get real, production code in the app store without having to write an entire app. Just send us a pull request!

  3. Support other iOS Framework companies
  
  If you are building iOS developer tools, these apps are a place where you can integrate your product and show it off to the world. They can also serve to demonstrate different integration strategies to your customers.

  4. Evaluate potential hires
  
  Want to interview an iOS developer? Test their chops by asking them to add a feature or two a real-world app.

  5. Show off your skills
  
  Trying to get a job? Point an employer to your merged pull requests to the sample apps as a demonstration of your ability to contribute to real apps.


Ink Integration Details
-----------------------
The Ink mobile framework adds the ability to take attachments from within ThatInbox and work with them in other applications. Plus, ThatInbox can accept attachments via Ink, so you can use ThatInbox to send emails with files from those applications. ThatInbox integrates with Ink in several locations:

  1. [AppDelegate](https://github.com/Ink/ThatInbox/blob/master/App/AppDelegate.m#L30) registers an incoming action, namely send.
  2. [HeaderView](https://github.com/Ink/ThatInbox/blob/master/App/Message/HeaderView.m#L232) binds Ink onto the thumbnail views of the attachments so that they respond to the two-finger double-tap gesture.


Contributors
------------
Many thanks to the people who have helped make this app:

* Liyan David Chang - [@liyanchang](https://github.com/liyanchang)
* Brett van Zuiden - [@brettcvz](https://github.com/brettcvz)

Also, the following third-party frameworks are used in this app:

* [Ink iOS Framework](https://github.com/Ink/InkiOSFramework) for connecting to other iOS apps.
* [MailCore](https://github.com/MailCore/mailcore2) for receiving, viewing, and sending emails.
* [FlatUIKit](https://github.com/Grouper/FlatUIKit) for the UX components.
* [PKRevealController](https://github.com/pkluz/PKRevealController) for the slide out left menu.
* [TRAutocompleteView](https://github.com/TarasRoshko/TRAutocompleteView) for the address book autocompletion.
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD) for HUD alerts.
* [FXKeychain](https://github.com/nicklockwood/FXKeychain) for wrapping the Apple keychain APIs
* [Google Toolbox for Mac - Oauth 2 Controllers](https://code.google.com/p/gtm-oauth2/) for oauth connectivity.
* [Apptentive](https://github.com/apptentive/apptentive-ios) for receiving user feedback.
