
use strict;
use warnings;
use DBI;




my ($dbname, $user, $pwd) = qw/CFSlab username password/;
my $dbh = DBI->connect(
"dbi:mysql:dbname=$dbname",
"$user",
"$pwd",
{RaiseError => 1},
) or die $DBI::errstr;
$dbh->do("DROP TABLE IF EXISTS Plasmid");
$dbh->do("CREATE TABLE Plasmid(

'ID' int(11) NOT NULL AUTO_INCREMENT,
'name' varchar(255) 	DEFAULT NULL,
'password' mediumtext NOT NULL,
'roles' CHAR(10) DEFAULT 'guest',
'p_list' TEXT,
's_list' TEXT,
PRIMARY KEY ('ID')
)ENGINE=MyISAM"
);

