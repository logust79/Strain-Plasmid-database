#Strain and Plasmid Database

##Introduction

In a multiplayer lab, material sharing is common. Especcially for a biology lab, people use common resources, such as bacterial strains, plasmids and primers all the time. When people tend to keep their own records of srains/plasmids/primers on an Excel sheet, it can get a bit tricky for one to use something that belongs to others. 
A worse senario? When I came to this lab, I had to carry over some work left by a leaving PhD. She had several boxes collection of strains, and I knew nothing about them... Handing over materials was such a pain in ... somewhere.

And that's when I decided to build up a Strain/Plasmid/Primer database to centralise every valuable materials in the lab (Primer's not available at the moment, but it will get there at some point).

For a preview of how the database looks like, please visit my [EC2 server](http://54.72.246.55:3000). You may log in with username = 'guest' and password = 'password'.

##How to set up

This application is based on MySQL (as the actual database) and Perl Dancer2 (as the web query interface). You might need to install several modules for this to work, such as Dancer2 and Template Toolkit. As for this writing, I tested it under Mac Mavericks (10.9.2). But it should work under Linux or Windows systems as well.

### Install Perl
* Linux and Mac users should already have Perl. However, this app uses some new features of Perl not available to old versions of Perl. You might need to upgrade it to at least v5.16.0. I use Perlbrew for upgrading Perl under Mac or Linux.

* Windows users can use Active Perl or Strawberry Perl.

### Install relevant Perl modules
* I'm sorry I couldn't list all the modules you need to install before you can run the Perl app. But you can get a clue by just running 'query.pl'. Although it will fail, it will tell you what modules are missing at the same time. You can install them one by one.

* Under Linux, Windows and Mac, you can install `cpanm`, and then use `cpanm` for module installation:
    
    `$cpan App::cpanminus`
    
    `$cpanm Dancer2`
    
    `$...`

Note, you might need `sudo` to do this.

* At least under Mac, after I upgraded to Mavericks, I had some problems when installing modules that require XS. If this happens, reinstall Xcode. That fixed my problem.

## Install MySQL
* I don't know how to install MySQL under Linux, but it should be straight forward under Linux and Windows. In Mac, however, I had to use Homebrew to do it. Install Homebew in Mac if necessary.

## Create a schema in MySQL
* In my example, I created a schema call 'CFSlab'. You can create your own schema, but then don't forget to change the corresponding field in ./config.yml. When you set up new username and password, you have to change the corresponding field in ./config.yml, too. And you also need to make changes in 'Create_xx_db.pl' scripts.
* You can then use the scripts 'Create_Plasmid_db.pl' and 'Create_Strain_db.pl' to create the two tables. You can add fields in them, but I don't recommend to remove any fields from them. Some algarithms rely on many of the fields being present. But then, if you want to add fields in the tables, you have to change a lot of things in the query.pl script and those '.tt' files in the 'views' folder. Quite a pain.

## Running the app
* Now you are ready to go, simply by running 'query.pl'. Don't forget you are using the 3000 port as Dancer2's default setting. You can query the database from anywhere in the local network by visiting the server's internal ip address.

* Oh, you can't log in? Don't be surprised... Because there's no user yet. First, run 'Create_user_db.pl', and then enable the '/add_user' handler in the 'query.pl' script by deleting '=disable' and '=cut' at the beginning and end of the handler, respectively. Now you can visit 'localhost:3000/add_user' to add users. Don't forget to change 'username' and 'password' in the 'Create_user_db.pl' according to your database's settings.
* If you want to grant some users with administrator privilege, for the time being, you have to manually change the 'roles' of the user in the 'users' table, from 'guest' to 'admin'. Now the user can edit any entry in the database.


