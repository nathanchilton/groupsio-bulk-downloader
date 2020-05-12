# groupsio-bulk-downloader
Bulk Downloader for photo albums stored in Groups.io

##Backstory
My ham radio club had about 2,500 photos in a groups.io account, organized into different albums. We were running out of space and, as a non-profit with a small budget, it was difficult to justify the expense.  They don't offer a bulk download option (though they do have a bulk upload option). 

The board had been advised that it looked like the only option was to either spend the money, or download the photos one-at-a-time. I saw that they had an API and spent a few hours building a Ruby script that could talk to it. We also had to deal with the fact that the file names can contain all sorts of illegal characters, since the original file name is replaced by whatever someone typed in as a title for the photo on the site (many contained forward slashes, colons, apostrophes, commas, question marks, and even exclamation points). Also, some photos were given the same title and thus had the same file name, so they had to be renamed. Many didn't have a file extension, so that needed to be detected, by analyzing the file, and then appended to the filename.

I invested few hours of work and I was then able to kick off the script and watch it go to work. After about 15 minutes, we had all 2,500 photos, with names that (as closely as practical) matched the title it had on groups.io, arranged in directories which matched the album names, and all with the correct file extensions.

##Usage:
Username and password are supplied by adding them to a .env file.

An example .env file is included.  Simply copy .env.dist to .env and add your username and password on the appropriate lines.

To install necessary Ruby gems: (these commands may need to be run with sudo)
  $ gem install bundler
  $ bundle install

To list available subscribed groups:
  $ bundle exec ruby batch_download_groups.io.rb list 

To download all photos for a group, specify the group ID number or the name:
  $ bundle exec ruby batch_download_groups.io.rb 12345   
  $ bundle exec ruby batch_download_groups.io.rb w6ek    
