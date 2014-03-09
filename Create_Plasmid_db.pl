use 5.16.0;
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

ID INT PRIMARY KEY AUTO_INCREMENT,
Name CHAR(20) UNIQUE,
Resistance TEXT,
Carriers TEXT,
Size INT(10),
Parent CHAR(20),
Daughters TEXT,
Copy_number CHAR(10),
Genotype TEXT,
Map LONGBLOB,
Sequence TEXT,
Temperature CHAR(7),
Blue_white CHAR(6) DEFAULT 'no',
Constructor VARCHAR(255),
Keeper VARCHAR(255),
Pre_keeper TEXT,
Recorder VARCHAR(255),
Arrival_time DATE,
Recording_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
Modified_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
Reference TEXT,
Location VARCHAR(255),
Construction TEXT,
Comments TEXT,
Obsolete INT DEFAULT 0
)ENGINE=InnoDB"
);

